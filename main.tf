module "s3" {
  source  = "boldlink/s3/aws"
  version = "~> 2.5"

  bucket            = var.bucket_suffix ? null : "${local.prefix}-logs"
  bucket_prefix     = var.bucket_suffix ? "${local.prefix}-logs-" : null
  versioning_status = "Enabled"

  # S3 access logs don't support encryption with a customer managed key
  # (CMK).
  # See https://repost.aws/knowledge-center/s3-server-access-log-not-delivered
  sse_bucket_key_enabled = true
  sse_sse_algorithm      = "AES256"

  bucket_policy = jsonencode(yamldecode(templatefile("${path.module}/templates/bucket-policy.yaml.tftpl", {
    account_id : data.aws_caller_identity.identity.account_id,
    partition : data.aws_partition.current.partition,
    name : module.s3.bucket
    bucket_arn : module.s3.arn,
    elb_account_arn : data.aws_elb_service_account.current.arn
  })))

  lifecycle_configuration = [
    {
      id     = "logs"
      status = "Enabled"

      abort_incomplete_multipart_upload_days = 7

      # Transition the current version to infrequent access to reduce costs.
      transition = [
        {
          days          = var.object_ia_age
          storage_class = "STANDARD_IA"
        }
      ]

      # Expire non-current versions.
      noncurrent_version_expiration = [
        {
          days = var.object_noncurrent_expiration
        }
      ]

      # Expire current versions. Objects will be deleted after the expiration,
      # baed on the non-current expiration.
      expiration = [
        {
          days = var.object_expiration
        }
      ]
    }
  ]

  tags = merge({ use = "logging" }, var.tags)
}

resource "aws_s3_bucket_object_lock_configuration" "lock" {
  for_each = var.object_lock_mode != "DISABLED" ? toset(["this"]) : toset([])

  bucket = module.s3.bucket

  rule {
    default_retention {
      mode  = var.object_lock_mode
      days  = var.object_lock_period == "days" ? var.object_lock_age : null
      years = var.object_lock_period == "years" ? var.object_lock_age : null
    }
  }
}

resource "aws_kms_key" "logs" {
  description             = "Logging encryption key for ${var.project} ${var.environment}"
  deletion_window_in_days = var.key_recovery_period
  enable_key_rotation     = true
  policy = jsonencode(yamldecode(templatefile("${path.module}/templates/key-policy.yaml.tftpl", {
    account_id : data.aws_caller_identity.identity.account_id
    partition : data.aws_partition.current.partition
    region : data.aws_region.current.name
    # bucket_arn : aws_s3_bucket.logs.arn
    bucket_arn : module.s3.arn
    project : var.project
    environment : var.environment
  })))

  tags = merge({ use = "logging" }, var.tags)
}

resource "aws_kms_alias" "logs" {
  name          = "alias/${var.project}/${var.environment}/logs"
  target_key_id = aws_kms_key.logs.id
}

resource "aws_cloudwatch_log_group" "logs" {
  for_each = var.log_groups

  name              = each.value.name != "" ? each.value.name : each.key
  retention_in_days = each.value.retention != null ? each.value.retention : var.cloudwatch_log_retention
  kms_key_id        = aws_kms_key.logs.arn

  tags = merge({ use = "logging" }, var.tags, each.value.tags)
}

resource "aws_cloudwatch_log_subscription_filter" "datadog" {
  for_each = length(local.datadog_lambda) > 0 ? resource.aws_cloudwatch_log_group.logs : {}

  name            = "datadog"
  log_group_name  = each.value.name
  filter_pattern  = ""
  destination_arn = data.aws_lambda_function.datadog["this"].arn
}

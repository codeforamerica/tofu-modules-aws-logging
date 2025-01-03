# We don't want to log access to this bucket, as that would cause an infinite
# loop of logging.
#trivy:ignore:avd-aws-0089
resource "aws_s3_bucket" "logs" {
  bucket        = var.bucket_suffix ? null : "${local.prefix}-logs"
  bucket_prefix = var.bucket_suffix ? "${local.prefix}-logs-" : null

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.logs.id

  rule {
    # This is necessary for certain AWS services to write to the bucket,
    # including CloudFront
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_public_access_block" "good_example" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    bucket_key_enabled = true

    apply_server_side_encryption_by_default {
      # S3 access logs don't support encryption with a customer managed key
      # (CMK).
      # See https://repost.aws/knowledge-center/s3-server-access-log-not-delivered
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id
  policy = jsonencode(yamldecode(templatefile("${path.module}/templates/bucket-policy.yaml.tftpl", {
    account_id : data.aws_caller_identity.identity.account_id,
    partition : data.aws_partition.current.partition,
    bucket_arn : aws_s3_bucket.logs.arn,
    elb_account_arn : data.aws_elb_service_account.current.arn
  })))
}

resource "aws_kms_key" "logs" {
  description             = "Logging encryption key for ${var.project} ${var.environment}"
  deletion_window_in_days = var.key_recovery_period
  enable_key_rotation     = true
  policy = jsonencode(yamldecode(templatefile("${path.module}/templates/key-policy.yaml.tftpl", {
    account_id : data.aws_caller_identity.identity.account_id
    partition : data.aws_partition.current.partition
    region : data.aws_region.current.name
    bucket_arn : aws_s3_bucket.logs.arn
    project : var.project
    environment : var.environment
  })))

  tags = var.tags
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

  tags = merge(var.tags, each.value.tags)
}

resource "aws_cloudwatch_log_subscription_filter" "datadog" {
  for_each = length(local.datadog_lambda) > 0 ? resource.aws_cloudwatch_log_group.logs : {}

  name            = "datadog"
  log_group_name  = each.value.name
  filter_pattern  = ""
  destination_arn = data.aws_lambda_function.datadog["this"].arn
}

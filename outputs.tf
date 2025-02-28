output "bucket" {
  value       = module.s3.bucket
  description = "S3 bucket used to store logs."
}

output "bucket_domain_name" {
  value       = module.s3.bucket_domain_name
  description = "Domain name of the S3 bucket used to store logs."
}

output "datadog_lambda" {
  value       = length(local.datadog_lambda) > 0 ? local.datadog_lambda[0] : ""
  description = "ARN of the Datadog lambda forwarder, if in use."
}

output "kms_key_alias" {
  value       = aws_kms_alias.logs.name
  description = "Alias of the KMS key used to encrypt logs."
}

output "kms_key_arn" {
  value       = aws_kms_key.logs.arn
  description = "ARN of the KMS key used to encrypt logs."
}

output "log_groups" {
  value       = { for key, group in aws_cloudwatch_log_group.logs : key => group.arn }
  description = "ARNs of any created CloudWatch log groups."
}

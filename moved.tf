# Move resources from the root of this module to the "s3" module introduced in
# 2.0.0.
moved {
  from = aws_s3_bucket.logs
  to   = module.s3.aws_s3_bucket.main
}

moved {
  from = aws_s3_bucket_ownership_controls.example
  to   = module.s3.aws_s3_bucket_ownership_controls.main
}

moved {
  from = aws_s3_bucket_policy.logs
  to   = module.s3.aws_s3_bucket_policy.main
}

moved {
  from = aws_s3_bucket_public_access_block.good_example
  to   = module.s3.aws_s3_bucket_public_access_block.main
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.logs
  to   = module.s3.aws_s3_bucket_server_side_encryption_configuration.main
}

moved {
  from = aws_s3_bucket_versioning.logs
  to   = module.s3.aws_s3_bucket_versioning.main
}

output "logs_bucket" {
  description = "Bucket containing log files."
  value = {
    id                 = aws_s3_bucket.logs.id
    arn                = aws_s3_bucket.logs.arn
    bucket_domain_name = aws_s3_bucket.logs.bucket_domain_name
  }
}

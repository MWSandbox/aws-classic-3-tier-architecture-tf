data "aws_caller_identity" "current" {}

data "aws_elb_service_account" "main" {}

#tfsec:ignore:aws-s3-enable-bucket-logging No need to do access logging on the access logs
resource "aws_s3_bucket" "logs" {
  # checkov:skip=CKV_AWS_145: Access Logging requires SSE-S3 encryption - see https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-logs.html
  # checkov:skip=CKV_AWS_144: Cross AZ replication is available, no need for now to add multi-region replication
  # checkov:skip=CKV_AWS_18: No need to do access logging on the access logs
  #ts:skip=AC_AWS_0497 No need to do access logging on the access logs
  #ts:skip=AC_AWS_0215 All users in the AWS account will have access to the log files

  bucket        = "${var.common.project_name}-logs"
  force_destroy = true

  tags = {
    Name = "${var.common.project_name}-logs"
  }
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_acl" "logs" {
  bucket = aws_s3_bucket.logs.id
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  #ts:skip=AC_AWS_0207 Access Logging requires SSE-S3 encryption - see https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-logs.html
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "private_logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

resource "aws_s3_bucket_policy" "access_for_load_balancer" {
  bucket = aws_s3_bucket.logs.id
  policy = data.aws_iam_policy_document.logs_bucket_policy.json

  depends_on = [
    aws_s3_bucket_public_access_block.private_logs
  ]
}

data "aws_iam_policy_document" "logs_bucket_policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.main.arn]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.logs.arn}/${var.load_balancer_access_logs_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
  }

  statement {
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.logs.arn}/${var.load_balancer_access_logs_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.logs.arn]
  }
}

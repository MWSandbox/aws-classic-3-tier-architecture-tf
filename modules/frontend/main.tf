locals {
  kms_deletion_window_in_days = 7
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "frontend" {
  # checkov:skip=CKV_AWS_145: Static website hosting - not a good use case for KMS encryption
  #ts:skip=AC_AWS_0215 All users in the AWS account will have access to the frontend
  #ts:skip=AC_AWS_0208 Static website hosting is enabled on purpose
  bucket        = var.frontend_dns_name
  acl           = "private"
  force_destroy = true

  logging {
    target_bucket = var.logs_bucket.id
    target_prefix = "frontend-logs/"
  }

  website {
    index_document = "index.html"
  }

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name = var.frontend_dns_name
  }
}

resource "aws_s3_bucket_public_access_block" "private_frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

resource "aws_s3_bucket_policy" "access_for_ip_whitelist" {
  bucket = aws_s3_bucket.frontend.id
  policy = data.aws_iam_policy_document.ip_based_access_to_frontend.json

  depends_on = [
    aws_s3_bucket_public_access_block.private_frontend
  ]
}

data "aws_iam_policy_document" "ip_based_access_to_frontend" {
  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.frontend.arn}/*"]
    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = var.ip_accept_list
    }
  }

  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.frontend_bucket_access.iam_arn]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.frontend.arn}/*"]
  }
}

resource "aws_cloudfront_distribution" "frontend" {
  # checkov:skip=CKV2_AWS_32: No documentation from checkov available yet - strict response header policy has been defined
  #ts:skip=AC_AWS_0023 Bug in terrascan - TLS 1.2 is being used
  aliases             = [var.frontend_dns_name]
  comment             = "HTTP to HTTPs"
  retain_on_delete    = false
  default_root_object = "index.html"
  enabled             = true
  price_class         = "PriceClass_100"
  web_acl_id          = var.web_acl_arn

  default_cache_behavior {
    allowed_methods            = ["HEAD", "GET"]
    cached_methods             = ["HEAD", "GET"]
    target_origin_id           = aws_s3_bucket.frontend.id
    viewer_protocol_policy     = "redirect-to-https"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.secure_header_config.id

    forwarded_values {
      cookies {
        forward = "none"
      }
      query_string = true
    }
  }

  logging_config {
    bucket = var.logs_bucket.bucket_domain_name
    prefix = "cloudfront"
  }

  origin {
    domain_name = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.frontend.id
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.frontend_bucket_access.cloudfront_access_identity_path
    }
  }

  restrictions {
    geo_restriction {
      locations        = var.country_keys_for_caching
      restriction_type = "whitelist"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = var.tls_certificate_arn
    cloudfront_default_certificate = false
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  tags = {
    Name = "${var.common.project_name}-frontend-distribution"
  }
}

resource "aws_cloudfront_origin_access_identity" "frontend_bucket_access" {
  comment = "Provides access for the frontend S3 bucket to the cloudfront network without the need to make the bucket public."
}

resource "aws_cloudfront_response_headers_policy" "secure_header_config" {
  name    = "${var.common.project_name}-secure-header-config"
  comment = "Header config that uses best practices to protect against XSS, MIME type sniffing, Clickjacking."

  security_headers_config {
    content_security_policy {
      override                = true
      content_security_policy = "frame-ancestors 'none'; default-src 'none'; img-src 'self'; script-src 'self'; style-src 'self'; media-src 'self'; object-src 'none'; connect-src 'https://${var.backend_dns_name}'"
    }
    content_type_options {
      override = true
    }
    frame_options {
      override     = true
      frame_option = "DENY"
    }
    referrer_policy {
      override        = true
      referrer_policy = "no-referrer"
    }
    xss_protection {
      override   = true
      mode_block = false
      protection = true
    }
  }
}
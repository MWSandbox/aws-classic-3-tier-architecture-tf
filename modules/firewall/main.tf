locals {
  wafv2_rule_level_config = {
    is_cloudwatch_enabled       = false
    is_request_sampling_enabled = false
  }
  cloudfront_region = "us-east-1"
}

provider "aws" {
  alias   = "wafv2"
  profile = "default"
  region  = var.scope == "CLOUDFRONT" ? local.cloudfront_region : var.common.aws_region

  default_tags {
    tags = {
      Project = var.common.project_name
    }
  }
}

resource "aws_wafv2_ip_set" "ip_accept_list" {
  provider           = aws.wafv2
  name               = "${var.common.project_name}-ip-accept-list"
  description        = "IP accept list"
  scope              = var.scope
  ip_address_version = "IPV4"
  addresses          = var.ip_accept_list

  tags = {
    Name = "${var.common.project_name}-ip-accept-list"
  }
}

resource "aws_wafv2_rule_group" "block_all_ips_but_ip_accept_list" {
  provider    = aws.wafv2
  name        = "${var.common.project_name}-block-all-ips-but-ip-accept-list"
  description = "Blocks all traffic originating from IP addresses excluded from the IP accept list"
  scope       = var.scope
  capacity    = 1

  rule {
    name     = "${var.common.project_name}-only-allow-ip-accept-list"
    priority = 1

    action {
      block {}
    }

    statement {
      not_statement {
        statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.ip_accept_list.arn
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = local.wafv2_rule_level_config.is_cloudwatch_enabled
      metric_name                = "AllowedRequests"
      sampled_requests_enabled   = local.wafv2_rule_level_config.is_request_sampling_enabled
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = local.wafv2_rule_level_config.is_cloudwatch_enabled
    metric_name                = "AllowedRequests"
    sampled_requests_enabled   = local.wafv2_rule_level_config.is_request_sampling_enabled
  }

  tags = {
    Name = "${var.common.project_name}-block-all-ips-but-ip-accept-list"
  }
}

resource "aws_wafv2_web_acl" "general_firewall" {
  provider = aws.wafv2
  # checkov:skip=CKV2_AWS_31: No Firewall logging enabled
  name        = "${var.common.project_name}-elb"
  description = "Firewall to only grant access from IP accept list and protect the resource using AWS core managed rules based on OWASP Top 10."
  scope       = var.scope

  default_action {
    allow {}
  }

  rule {
    name     = "block-all-ips-but-ip-accept-list"
    priority = 1

    override_action {
      none {}
    }

    statement {
      rule_group_reference_statement {
        arn = aws_wafv2_rule_group.block_all_ips_but_ip_accept_list.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = local.wafv2_rule_level_config.is_cloudwatch_enabled
      metric_name                = "AllowedRequests"
      sampled_requests_enabled   = local.wafv2_rule_level_config.is_request_sampling_enabled
    }
  }

  rule {
    name     = "aws-core-rules"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = local.wafv2_rule_level_config.is_cloudwatch_enabled
      metric_name                = "BlockedRequests"
      sampled_requests_enabled   = local.wafv2_rule_level_config.is_request_sampling_enabled
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "AllowedRequests"
    sampled_requests_enabled   = true
  }
}

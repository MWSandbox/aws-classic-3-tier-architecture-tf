variable "common" {
  description = "Common properties reused in multiple modules."
  type = object({
    project_name = string
    aws_region   = string
  })
  validation {
    condition     = length(var.common.project_name) < 16
    error_message = "Project name needs to be shorter than 16 characters, since it will be used as a prefix for the name tag."
  }
  validation {
    condition     = length(regex(".*-.*-\\d", var.common.aws_region)) > 0
    error_message = "Provided AWS region name uses incorrect pattern."
  }
}

variable "logs_bucket" {
  description = "Bucket containing log files."
  type = object({
    id                 = string
    arn                = string
    bucket_domain_name = string
  })
}

variable "ip_accept_list" {
  description = "List of IPv4 addresses that should be able to call the application. All other IP addresses will be blocked by WAFv2 and S3 bucket policies. To permit access from everywhere, please add 0.0.0.0/0 to the list."
  type        = list(string)
}

variable "frontend_dns_name" {
  description = "Full DNS name for the frontend S3 bucket."
  type        = string
}

variable "backend_dns_name" {
  description = "Full DNS name for the backend."
  type        = string
}

variable "tls_certificate_arn" {
  description = "Arn of the certificate to use for HTTPS protocol."
  type        = string
}

variable "web_acl_arn" {
  description = "Arn of the Web ACL to apply to the cloudfront distribution as firewall."
  type        = string
}

variable "country_keys_for_caching" {
  description = "List of country keys to use as caching locations by CloudFront."
  type        = list(string)
}

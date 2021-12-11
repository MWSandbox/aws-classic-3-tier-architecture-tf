variable "common" {
  description = "Common properties reused in multiple modules."
  type = object({
    project_name = string
  })
  validation {
    condition     = length(var.common.project_name) < 16
    error_message = "Project name needs to be shorter than 16 characters, since it will be used as a prefix for the name tag."
  }
}

variable "access_logs_prefix" {
  description = "Prefix of the access logs that will be stored in S3 bucket."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC that contains the infrastructure"
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs of the public subnets where the load balancer should be deployed."
  type        = list(string)
  validation {
    condition     = length(var.public_subnet_ids) == 2
    error_message = "Only 2 public subnets required for a highly available environment."
  }
}

variable "logs_bucket" {
  description = "Bucket containing log files."
  type = object({
    id  = string
    arn = string
  })
}

variable "ip_accept_list" {
  description = "List of IPv4 addresses that should be able to call the application. All other IP addresses will be blocked by WAFv2 and S3 bucket policies. To permit access from everywhere, please add 0.0.0.0/0 to the list."
  type        = list(string)
}

variable "tls_certificate_arn" {
  description = "Arn of the TLS certificate that will be used by the load balancer for HTTPS traffic."
  type        = string
  validation {
    condition     = length(regex("^arn:aws:acm:.*:.*:certificate\\/.*", var.tls_certificate_arn)) > 0
    error_message = "Invalid certificate arn provided. Arn needs to be in format arn:aws:acm:[region]:[account-id]:certificate/[certificate-id]."
  }
}

variable "web_acl_arn" {
  description = "Arn of the WAFv2 Web ACL to apply to the load balancer."
  type        = string
}

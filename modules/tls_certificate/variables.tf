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

variable "domain_name" {
  description = "Name of the domain to issue the certificate for."
  type        = string
}

variable "dns_name" {
  description = "Full DNS name to issue the certificate for."
  type        = string
}

variable "certificate_region" {
  description = "Region to issue the certificate for. Cloudfront certificates need to be issued in region us-east."
  type        = string
}
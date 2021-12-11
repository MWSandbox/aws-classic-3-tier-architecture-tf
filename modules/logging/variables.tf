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

variable "load_balancer_access_logs_prefix" {
  description = "Prefix of the access logs of the load balancer. A directory with the prefix name will be created in the S3 bucket containing all log files"
  type        = string
}
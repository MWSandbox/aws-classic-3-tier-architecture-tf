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

variable "vpc_cidr" {
  description = "CIDR of the VPC running most of the infrastructure."
  type        = string
  default     = "10.0.0.0/16"
  validation {
    condition     = can(regex("^(?:\\d{1,3}\\.){3}\\d{1,3}/\\d{1,3}", var.vpc_cidr))
    error_message = "All provided CIDRs need to be in format: (aaa.bbb.ccc.ddd/eee)."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDRs of the public subnets."
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "Please provide exactly 2 IPv4 CIDRs."
  }
  validation {
    condition     = can([for cidr in var.public_subnet_cidrs : regex("^(?:\\d{1,3}\\.){3}\\d{1,3}/\\d{1,3}", cidr)])
    error_message = "All provided CIDRs need to be in format: (aaa.bbb.ccc.ddd/eee)."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDRs of the private subnets."
  type        = list(string)
  default     = ["10.0.2.0/23", "10.0.4.0/23"]
  validation {
    condition     = length(var.private_subnet_cidrs) == 2
    error_message = "Please provide exactly 2 IPv4 CIDRs."
  }
  validation {
    condition     = can([for cidr in var.private_subnet_cidrs : regex("^(?:\\d{1,3}\\.){3}\\d{1,3}/\\d{1,3}", cidr)])
    error_message = "All provided CIDRs need to be in format: (aaa.bbb.ccc.ddd/eee)."
  }
}

variable "availability_zones" {
  description = "List of availability zones to run the infrastructure. Number of availability zones should match number of private/public subnets for high availability."
  type        = list(string)
  validation {
    condition     = can([for availability_zone in var.availability_zones : length(regex(".*-.*-\\d[a-z]", availability_zone))])
    error_message = "Provided AZ name uses incorrect pattern."
  }
}

variable "flow_log_format" {
  description = "Format of the VPC flow logs"
  default     = "$${account-id} $${action} $${srcaddr} $${srcport} $${dstaddr} $${dstport} $${az-id} $${subnet-id} $${type} $${traffic-path} $${flow-direction} $${bytes}"
  type        = string
  validation {
    condition     = length(regex("^(?:\\$\\{.*\\}\\s)*\\$\\{.*\\}", var.flow_log_format)) > 0
    error_message = "Provided log format does not match correct pattern."
  }
}

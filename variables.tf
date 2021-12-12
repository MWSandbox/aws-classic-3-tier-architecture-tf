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

variable "app_server_ami" {
  description = "AMI to use for provisioning the EC2 instances of the app servers."
  type        = string
  default     = "ami-058e6df85cfc7760b"
  validation {
    condition     = length(regex("^ami-.*", var.app_server_ami)) > 0
    error_message = "Valid AMI IDs start with ami-."
  }
}

variable "app_server_instance_type" {
  description = "Instance type of the EC2 instances running the app servers."
  type        = string
  default     = "t2.micro"
}

variable "app_server_scaling" {
  description = "Properties used to autoscale the appservers."
  type = object({
    desired_capacity = number
    min_capacity     = number
    max_capacity     = number
    cpu_threshold    = number
  })
  default = {
    desired_capacity = 2
    min_capacity     = 2
    max_capacity     = 4
    cpu_threshold    = 60
  }
  validation {
    condition     = var.app_server_scaling.desired_capacity > 0
    error_message = "Please specify a desired capacity of instances to run the application."
  }
  validation {
    condition     = var.app_server_scaling.min_capacity > 0 && var.app_server_scaling.min_capacity <= var.app_server_scaling.desired_capacity
    error_message = "Please specify a min. capacity of instances to run the application that is > 0 and <= desired_capacity."
  }
  validation {
    condition     = var.app_server_scaling.max_capacity > 0 && var.app_server_scaling.min_capacity <= var.app_server_scaling.max_capacity && var.app_server_scaling.desired_capacity <= var.app_server_scaling.max_capacity
    error_message = "Please specify a max. capacity of instances to run the application that is > 0 and >= min_capacity and >= desired_capacity."
  }
  validation {
    condition     = var.app_server_scaling.cpu_threshold > 0 && var.app_server_scaling.cpu_threshold <= 100
    error_message = "Please specify a value between 1 and 100."
  }
}

variable "app_server_volume_size" {
  description = "EBS volume size for the app servers EC2 instances."
  type        = number
  default     = 8
  validation {
    condition     = var.app_server_volume_size > 0 && var.app_server_volume_size <= 30
    error_message = "Only volume sizes between 1 and 30 GB should be used."
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

variable "db_monitoring_interval_in_seconds" {
  description = "Period in seconds in which the enhanced monitoring metrics of the DB instance should be collected."
  type        = number
  default     = 60
  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.db_monitoring_interval_in_seconds)
    error_message = "Please provide a value of 0, 1, 5, 10, 15, 30 or 60 seconds."
  }
}

variable "db_postgres_version" {
  description = "Postgres version to provision the DB instance."
  type        = string
  default     = "11"
}

variable "db_instance_class" {
  description = "Instance class to use for the DB servers."
  type        = string
  default     = "db.t3.small"
}

variable "db_backup_retention_period_in_days" {
  description = "Period in days in which backups of the DB should be kept."
  type        = number
  default     = 2
  validation {
    condition     = var.db_backup_retention_period_in_days >= 1 && var.db_backup_retention_period_in_days <= 35
    error_message = "Retention period has to be between 1 and 35 days."
  }
}

variable "db_name" {
  description = "Name of the database to be created."
  type        = string
}

variable "db_user" {
  description = "DB user to be created."
  type        = string
}

variable "db_password_secret_name" {
  description = "Name of the secret in AWS Secrets Manager holding the DB password."
  type        = string
}

variable "db_password_secret_key" {
  description = "Key inside the secret in AWS Secrets Manager referencing the DB password."
  type        = string
}

variable "is_standby_db_required" {
  description = "True, if a standby DB should be provisioned in a separate AZ."
  type        = bool
  default = true
}

variable "domain_name" {
  description = "Your domain name under which the application should be accessible."
  type        = string
}

variable "backend_dns_prefix" {
  description = "The prefix to the domain name to be used to access the backend. Backend DNS name = backend_dns_prefix + domain_name. Has to end with a dot."
  type        = string
  validation {
    condition     = length(regex("^.*\\.", var.backend_dns_prefix)) > 0
    error_message = "DNS prefix needs to end with a dot."
  }
}

variable "frontend_dns_prefix" {
  description = "The prefix to the domain name to be used to access the frontend. Frontend DNS name = frontend_dns_prefix + domain_name. Has to end with a dot."
  type        = string
  validation {
    condition     = length(regex("^.*\\.", var.frontend_dns_prefix)) > 0
    error_message = "DNS prefix needs to end with a dot."
  }
}

variable "load_balancer_access_logs_prefix" {
  description = "Prefix of the load balancer access logs that will be stored inside the logging S3 bucket."
  type        = string
  default     = "classic-arch-lb"
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

variable "static_ip_accept_list" {
  description = "List of IPv4 addresses that should be able to call the application. All other IP addresses will be blocked by WAFv2 and S3 bucket policies. To permit access from everywhere, please add 0.0.0.0/0 to the list."
  type        = list(string)
}

variable "is_own_ip_restricted" {
  description = "True, if the application should only be available from your own public IPv4 address. The address will be resolved automatically."
  type        = bool
}

variable "country_keys_for_caching" {
  description = "List of country keys to use as caching locations by CloudFront."
  type        = list(string)
}

variable "ecr_repository" {
  description = "List of country keys to use as caching locations by CloudFront."
  type        = string
}

variable "context_path" {
  description = "Context path the application is deployed on the app server."
  type        = string
}

variable "app_version_to_deploy" {
  description = "Default version to be deployed, when a new EC2 instance starts (e.g. latest) from the PROD ECR registry."
  type        = string
}

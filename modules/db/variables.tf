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

variable "monitoring_interval_in_seconds" {
  description = "Period in seconds in which the enhanced monitoring metrics of the DB instance should be collected."
  type        = number
  default     = 60
  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval_in_seconds)
    error_message = "Please provide a value of 0, 1, 5, 10, 15, 30 or 60 seconds."
  }
}

variable "postgres_version" {
  description = "Postgres version to provision the DB instance."
  type        = string
  default     = "11"
}

variable "instance_class" {
  description = "Instance class to use for the DB servers."
  type        = string
  default     = "db.t3.small"
}

variable "backup_retention_period_in_days" {
  description = "Period in days in which backups of the DB should be kept."
  type        = number
  default     = 2
  validation {
    condition     = var.backup_retention_period_in_days >= 1 && var.backup_retention_period_in_days <= 35
    error_message = "Retention period has to be between 0 and 35 days."
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


variable "vpc_id" {
  description = "ID of the VPC that contains the infrastructure"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets in which the DB instances should be deployed to"
  type        = list(string)
  validation {
    condition     = length(var.private_subnet_ids) == 2
    error_message = "Only 2 private subnets required for a highly available environment."
  }
}

variable "availability_zones" {
  description = "List of availability zones to run the database."
  type        = list(string)
  validation {
    condition     = can([for availability_zone in var.availability_zones : length(regex(".*-.*-\\d[a-z]", availability_zone))])
    error_message = "Provided AZ name uses incorrect pattern."
  }
}

variable "is_standby_db_required" {
  description = "True, if a standby DB should be provisioned in a separate AZ."
  type        = bool
  default = true
}

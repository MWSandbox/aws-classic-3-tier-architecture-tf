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

variable "ami" {
  description = "AMI to use for provisioning the EC2 instances of the app servers."
  type        = string
  default     = "ami-058e6df85cfc7760b"
  validation {
    condition     = length(regex("^ami-.*", var.ami)) > 0
    error_message = "Valid AMI IDs start with ami-."
  }
}

variable "instance_type" {
  description = "Instance type of the EC2 instances running the app servers."
  type        = string
  default     = "t2.micro"
}

variable "scaling" {
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
    condition     = var.scaling.desired_capacity > 0
    error_message = "Please specify a desired capacity of instances to run the application."
  }
  validation {
    condition     = var.scaling.min_capacity > 0 && var.scaling.min_capacity <= var.scaling.desired_capacity
    error_message = "Please specify a min. capacity of instances to run the application that is > 0 and <= desired_capacity."
  }
  validation {
    condition     = var.scaling.max_capacity > 0 && var.scaling.min_capacity <= var.scaling.max_capacity && var.scaling.desired_capacity <= var.scaling.max_capacity
    error_message = "Please specify a max. capacity of instances to run the application that is > 0 and >= min_capacity and >= desired_capacity."
  }
  validation {
    condition     = var.scaling.cpu_threshold > 0 && var.scaling.cpu_threshold <= 100
    error_message = "Please specify a value between 1 and 100."
  }
}

variable "volume_size" {
  description = "EBS volume size for the app servers EC2 instances."
  type        = number
  default     = 8
  validation {
    condition     = var.volume_size > 0 && var.volume_size <= 30
    error_message = "Only volume sizes between 1 and 30 GB should be used."
  }
}

variable "context_path" {
  description = "Context path on which the app will be deployed."
  type        = string
}

variable "app_version_to_deploy" {
  description = "Default version of the app to deploy (e.g. latest) - separate docker repository should be used per environment."
  type        = string
}

variable "db_endpoint" {
  description = "Endpoint of the DB to connect to."
  type        = string
}

variable "db_name" {
  description = "Name of the DB to connect to."
  type        = string
}

variable "db_user" {
  description = "User for the DB connection."
  type        = string
}

variable "db_secret_name" {
  description = "Name of the secret in AWS Secrets Manager holding the DB password."
  type        = string
}

variable "backend_dns_name" {
  description = "DNS name that should be used for the backend."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC that contains the infrastructure"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets in which the EC2 instances should be deployed to"
  type        = list(string)
  validation {
    condition     = length(var.private_subnet_ids) == 2
    error_message = "Only 2 private subnets required for a highly available environment."
  }
}

variable "target_group_arn" {
  description = "ARN of the load balancer target group that should forward the traffic to the EC2 instances"
  type        = string
  validation {
    condition     = length(regex("^arn:aws:elasticloadbalancing:.*:.*:targetgroup\\/.*\\/.*", var.target_group_arn)) > 0
    error_message = "Provided target group arn does not match the correct pattern: arn:aws:elasticloadbalancing:REGION:ACCOUNT:targetgroup/my-targets/TARGET-GROUP-ID."
  }
}

variable "load_balancer_security_group_id" {
  description = "Only the security group of the load balancer is allowed to send traffic to EC2 instances"
  type        = string
}

variable "db_security_group_id" {
  description = "ID of the security group used by the DB the app should connect to."
  type        = string
}

variable "ecr_repository" {
  description = "Name of the repository containing the app images."
  type        = string
}
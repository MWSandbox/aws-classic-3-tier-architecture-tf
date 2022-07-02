terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.21"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 2.2"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.2"
    }
  }

  backend "s3" {
    region         = "YOUR REGION"
    bucket         = "YOUR BUCKET"
    key            = "terraform.tfstate"
    encrypt        = true
    dynamodb_table = "YOUR TABLE"
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  profile = "default"
  region  = var.common.aws_region

  default_tags {
    tags = {
      Project = var.common.project_name
    }
  }
}

locals {
  public_ip_provider            = "http://ipv4.icanhazip.com"
  full_ip_accept_list           = var.is_own_ip_restricted ? concat(var.static_ip_accept_list, ["${chomp(data.http.my_public_ip.body)}/32"]) : var.static_ip_accept_list
  cloudfront_certificate_region = "us-east-1"
}

data "http" "my_public_ip" {
  url = local.public_ip_provider
}

module "vpc_network" {
  source = "./modules/vpc-network"

  common               = var.common
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  flow_log_format      = var.flow_log_format
}

module "logging" {
  source = "./modules/logging"

  common                           = var.common
  load_balancer_access_logs_prefix = var.load_balancer_access_logs_prefix
}

module "backend_tls_certificate" {
  source = "./modules/tls_certificate"

  common             = var.common
  domain_name        = var.domain_name
  dns_name           = "${var.backend_dns_prefix}${var.domain_name}"
  certificate_region = var.common.aws_region
}

module "load_balancer_firewall" {
  source = "./modules/firewall"

  common         = var.common
  ip_accept_list = local.full_ip_accept_list
  scope          = "REGIONAL"
}

module "load_balancer" {
  source = "./modules/load_balancer"

  common              = var.common
  vpc_id              = module.vpc_network.vpc_id
  public_subnet_ids   = module.vpc_network.public_subnet_ids
  logs_bucket         = module.logging.logs_bucket
  access_logs_prefix  = var.load_balancer_access_logs_prefix
  ip_accept_list      = local.full_ip_accept_list
  tls_certificate_arn = module.backend_tls_certificate.tls_certificate_arn
  web_acl_arn         = module.load_balancer_firewall.web_acl_arn
}

module "db" {
  source = "./modules/db"

  common                          = var.common
  vpc_id                          = module.vpc_network.vpc_id
  private_subnet_ids              = module.vpc_network.private_subnet_ids
  availability_zones              = var.availability_zones
  monitoring_interval_in_seconds  = var.db_monitoring_interval_in_seconds
  postgres_version                = var.db_postgres_version
  instance_class                  = var.db_instance_class
  backup_retention_period_in_days = var.db_backup_retention_period_in_days
  db_name                         = var.db_name
  db_user                         = var.db_user
  db_password_secret_name         = var.db_password_secret_name
  db_password_secret_key          = var.db_password_secret_key
  is_standby_db_required = var.is_standby_db_required
}

module "app" {
  source = "./modules/app"

  common                          = var.common
  ami                             = var.app_server_ami
  instance_type                   = var.app_server_instance_type
  scaling                         = var.app_server_scaling
  volume_size                     = var.app_server_volume_size
  context_path                    = var.context_path
  app_version_to_deploy           = var.app_version_to_deploy
  db_endpoint                     = module.db.endpoint
  db_name                         = var.db_name
  db_user                         = var.db_user
  db_secret_name                  = var.db_password_secret_name
  db_security_group_id            = module.db.security_group_id
  backend_dns_name                = "${var.backend_dns_prefix}${var.domain_name}"
  vpc_id                          = module.vpc_network.vpc_id
  private_subnet_ids              = module.vpc_network.private_subnet_ids
  target_group_arn                = module.load_balancer.target_group_arn
  load_balancer_security_group_id = module.load_balancer.security_group_id
  ecr_repository                  = var.ecr_repository
}

module "frontend_tls_certificate" {
  source = "./modules/tls_certificate"

  common             = var.common
  domain_name        = var.domain_name
  dns_name           = "${var.frontend_dns_prefix}${var.domain_name}"
  certificate_region = local.cloudfront_certificate_region
}

module "cloudfront_firewall" {
  source = "./modules/firewall"

  common         = var.common
  ip_accept_list = local.full_ip_accept_list
  scope          = "CLOUDFRONT"
}

module "frontend" {
  source = "./modules/frontend"

  common                   = var.common
  logs_bucket              = module.logging.logs_bucket
  ip_accept_list           = local.full_ip_accept_list
  frontend_dns_name        = "${var.frontend_dns_prefix}${var.domain_name}"
  backend_dns_name         = "${var.backend_dns_prefix}${var.domain_name}"
  tls_certificate_arn      = module.frontend_tls_certificate.tls_certificate_arn
  web_acl_arn              = module.cloudfront_firewall.web_acl_arn
  country_keys_for_caching = var.country_keys_for_caching
}

module "backend_dns_setup" {
  source = "./modules/dns"

  common                   = var.common
  domain_name              = var.domain_name
  service_dns_prefix       = var.backend_dns_prefix
  service_default_dns_name = module.load_balancer.dns_name
  service_default_zone_id  = module.load_balancer.zone_id
}

module "frontend_dns_setup" {
  source = "./modules/dns"

  common                   = var.common
  domain_name              = var.domain_name
  service_dns_prefix       = var.frontend_dns_prefix
  service_default_dns_name = module.frontend.cloudfront_dns_name
  service_default_zone_id  = module.frontend.cloudfront_zone_id
}
data "aws_secretsmanager_secret" "password" {
  name = var.db_password_secret_name
}

data "aws_secretsmanager_secret_version" "current_password" {
  secret_id = data.aws_secretsmanager_secret.password.id
}

data "aws_caller_identity" "current" {}

resource "aws_db_instance" "app_data" {
  # checkov:skip=CKV2_AWS_30: No documentation about query logging available
  #ts:skip=AC_AWS_0058 Storage encryption is enabled
  identifier                            = "classic-arch-app-data"
  engine                                = "postgres"
  engine_version                        = var.postgres_version
  username                              = var.db_user
  password                              = jsondecode(data.aws_secretsmanager_secret_version.current_password.secret_string)[var.db_password_secret_key]
  instance_class                        = var.instance_class
  allocated_storage                     = 20
  max_allocated_storage                 = 0
  db_subnet_group_name                  = aws_db_subnet_group.app_data.name
  vpc_security_group_ids                = [aws_security_group.app_data.id]
  db_name                               = var.db_name
  monitoring_interval                   = var.monitoring_interval_in_seconds
  monitoring_role_arn                   = aws_iam_role.monitoring.arn
  skip_final_snapshot                   = true
  enabled_cloudwatch_logs_exports       = ["postgresql", "upgrade"]
  multi_az                              = var.is_standby_db_required
  iam_database_authentication_enabled   = true
  storage_encrypted                     = true
  backup_retention_period               = var.backup_retention_period_in_days
  auto_minor_version_upgrade            = true
  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  performance_insights_kms_key_id       = aws_kms_key.performance_insights.arn
}

resource "aws_kms_key" "performance_insights" {
  description             = "KMS Key to encrypt RDS performance insights"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.performance_insights_key_policy.json
}

resource "aws_kms_alias" "performance_insights" {
  name          = "alias/${var.common.project_name}-performance-insights-key"
  target_key_id = aws_kms_key.performance_insights.key_id
}

data "aws_iam_policy_document" "performance_insights_key_policy" {
  # checkov:skip=CKV_AWS_109: Key Policy only applicable for this specific key
  # checkov:skip=CKV_AWS_111: Key Policy only applicable for this specific key
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
}

resource "aws_db_subnet_group" "app_data" {
  name       = "classic-arch-app-data"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "classic-arch-app-data"
  }
}

resource "aws_security_group" "app_data" {
  vpc_id      = var.vpc_id
  name        = "classic-arch-db"
  description = "Only App layer should have access to DB"

  tags = {
    Name = "classic-arch-db"
  }
}

resource "aws_iam_role" "monitoring" {
  name                  = "${var.common.project_name}-rds-monitoring"
  description           = "Grants CloudWatch permissions for RDS enhanced monitoring"
  force_detach_policies = true
  assume_role_policy    = data.aws_iam_policy_document.rds_assume_role.json
}

resource "aws_iam_role_policy_attachment" "access_to_cloudwatch_for_rds_monitoring" {
  role       = aws_iam_role.monitoring.name
  policy_arn = aws_iam_policy.access_to_cloudwatch.arn
}

resource "aws_iam_policy" "access_to_cloudwatch" {
  name        = "${var.common.project_name}-access-to-cloudwatch"
  description = "Grants access to CloudWatch for RDS enhanced monitoring"
  policy      = data.aws_iam_policy_document.access_to_cloudwatch.json
}

#tfsec:ignore:aws-iam-no-policy-wildcards Standard policy to enable RDS Enhanced Monitoring (Compare to managed policy AmazonRDSEnhancedMonitoringRole)
data "aws_iam_policy_document" "access_to_cloudwatch" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:PutRetentionPolicy",
    ]
    resources = ["arn:aws:logs:*:*:log-group:RDS*"]
  }

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:GetLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:log-group:RDS*:log-stream:*"]
  }
}

data "aws_iam_policy_document" "rds_assume_role" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

locals {
  auto_scaling_health_check_period = 200
  traffic_ports                    = [80, 443]
  ssm_session_manager_policy_arn   = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  kms_deletion_window_in_days      = 7
}

data "aws_caller_identity" "current" {}

data "template_file" "ec2_user_data" {
  template = file("${path.module}/resources/app-user-data-docker.tpl")
  vars = {
    db_endpoint           = var.db_endpoint
    db_user               = var.db_user
    db_name               = var.db_name
    openapi_servers       = "https://${var.backend_dns_name}/${var.context_path}"
    region                = var.common.aws_region
    ecr_repository        = var.ecr_repository
    app_version_to_deploy = var.app_version_to_deploy
    db_secret_name        = var.db_secret_name
  }
}

resource "aws_launch_template" "server" {
  name                   = "${var.common.project_name}-app-server-template"
  default_version        = 1
  image_id               = var.ami
  instance_type          = var.instance_type
  vpc_security_group_ids = ["${aws_security_group.server.id}"]
  user_data              = base64encode(data.template_file.ec2_user_data.rendered)

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.volume_size
      delete_on_termination = true
      encrypted             = true
      volume_type           = "gp2"
      kms_key_id            = aws_kms_key.server.arn
    }
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.server.name
  }

  credit_specification {
    cpu_credits = "standard"
  }
}

resource "aws_kms_key" "server" {
  description             = "KMS Key for EC2 instance to encrypt storage"
  deletion_window_in_days = local.kms_deletion_window_in_days
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.server_key_policy.json
}

resource "aws_kms_alias" "server" {
  name          = "alias/${var.common.project_name}-ec2-encryption-key"
  target_key_id = aws_kms_key.server.key_id
}

data "aws_iam_policy_document" "server_key_policy" {
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

  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"]
    }
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["*"]
  }

  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"]
    }
    actions = [
      "kms:CreateGrant"
    ]
    resources = ["*"]

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = [true]
    }
  }
}

resource "aws_autoscaling_group" "server" {
  name                      = "${var.common.project_name}-app-server"
  vpc_zone_identifier       = var.private_subnet_ids
  desired_capacity          = var.scaling.desired_capacity
  min_size                  = var.scaling.min_capacity
  max_size                  = var.scaling.max_capacity
  target_group_arns         = ["${var.target_group_arn}"]
  health_check_grace_period = local.auto_scaling_health_check_period

  launch_template {
    id      = aws_launch_template.server.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
  }

  tag {
    key                 = "Name"
    value               = "${var.common.project_name}-app-server"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "scaling_based_on_cpu" {
  name                   = "${var.common.project_name}-app-scaling-based-on-cpu"
  autoscaling_group_name = aws_autoscaling_group.server.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = var.scaling.cpu_threshold
  }
}

resource "aws_iam_role" "server" {
  name                  = "${var.common.project_name}-app-server"
  description           = "Role for the app server EC2 instances"
  force_detach_policies = true
  assume_role_policy    = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "access_to_ssm_session_manager_for_server" {
  role       = aws_iam_role.server.name
  policy_arn = local.ssm_session_manager_policy_arn
}

resource "aws_iam_instance_profile" "server" {
  name = "${var.common.project_name}-app-server"
  role = aws_iam_role.server.name
}

resource "aws_security_group" "server" {
  # checkov:skip=CKV2_AWS_5: Not directly attached to EC2 instances, but via launch template
  vpc_id      = var.vpc_id
  name        = "${var.common.project_name}-app-server"
  description = "Only allow web access from load balancer"

  tags = {
    Name = "${var.common.project_name}-app-server"
  }
}

resource "aws_security_group_rule" "inbound_traffic_from_elb_to_app" {
  count                    = 2
  description              = "Only allow incoming HTTP traffic from load balancer"
  type                     = "ingress"
  from_port                = local.traffic_ports[count.index]
  to_port                  = local.traffic_ports[count.index]
  protocol                 = "tcp"
  security_group_id        = aws_security_group.server.id
  source_security_group_id = var.load_balancer_security_group_id
}

resource "aws_security_group_rule" "outbound_traffic_from_app" {
  count             = 2
  description       = "Outgoing traffic can go anywhere"
  type              = "egress"
  from_port         = local.traffic_ports[count.index]
  to_port           = local.traffic_ports[count.index]
  protocol          = "tcp"
  security_group_id = aws_security_group.server.id
  #tfsec:ignore:aws-vpc-no-public-egress-sgr Required so the application is reachable from the internet. Security is enforced by hiding the instances behind a NAT gateway and making the containing subnets private. Further restrictions on who will be able to connect are enforced on ELB and WAFv2 side.
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "reachability_of_app_from_elb" {
  count                    = 4
  description              = "Allow traffic between elb and app"
  type                     = count.index < 2 ? "ingress" : "egress"
  from_port                = local.traffic_ports[count.index % 2]
  to_port                  = local.traffic_ports[count.index % 2]
  protocol                 = "tcp"
  security_group_id        = var.load_balancer_security_group_id
  source_security_group_id = aws_security_group.server.id
}

resource "aws_security_group_rule" "reachability_of_app_from_db" {
  count                    = 2
  description              = "Allow traffic between db and app"
  type                     = count.index == 1 ? "ingress" : "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = var.db_security_group_id
  source_security_group_id = aws_security_group.server.id
}

resource "aws_security_group_rule" "reachability_of_db_from_app" {
  count                    = 2
  description              = "Allow traffic between db and app"
  type                     = count.index == 1 ? "ingress" : "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.server.id
  source_security_group_id = var.db_security_group_id
}

data "aws_iam_policy_document" "access_to_ecr" {
  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
      "ecr:DescribeRegistry",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetLifecyclePolicy",
      "ecr:GetLifecyclePolicyPreview",
      "ecr:GetRegistryPolicy",
      "ecr:GetRepositoryPolicy",
      "ecr:ListImages",
      "ecr:ListTagsForResource"
    ]
    resources = ["arn:aws:ecr:${var.common.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${var.ecr_repository}"]
  }

  statement {
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "access_to_ecr" {
  name        = "${var.common.project_name}-access-to-ecr"
  description = "Grants access to ECR for pulling docker images"
  policy      = data.aws_iam_policy_document.access_to_ecr.json
}

resource "aws_iam_role_policy_attachment" "access_to_ecr_for_server" {
  role       = aws_iam_role.server.name
  policy_arn = aws_iam_policy.access_to_ecr.arn
}

data "aws_iam_policy_document" "access_to_secrets_manager" {
  statement {
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:ListSecretVersionIds",
    ]

    resources = ["arn:aws:secretsmanager:${var.common.aws_region}:${data.aws_caller_identity.current.account_id}:secret:*"]
  }
}

resource "aws_iam_policy" "access_to_secrets_manager" {
  name        = "${var.common.project_name}-access-to-secrets-manager"
  description = "Grants access to read app relevant secrets"
  policy      = data.aws_iam_policy_document.access_to_secrets_manager.json
}

resource "aws_iam_role_policy_attachment" "access_to_secrets_manager_for_server" {
  role       = aws_iam_role.server.name
  policy_arn = aws_iam_policy.access_to_secrets_manager.arn
}

locals {
  flow_log_aggregation_interval    = 600
  flow_log_retention_in_days       = 3
  flow_log_deletion_window_in_days = 7
  traffic_ports                    = [80, 443]
  ephemeral_port_range_by_nat      = [1024, 65535]
}

data "aws_caller_identity" "current" {}

resource "aws_vpc" "this" {
  # checkov:skip=CKV2_AWS_12: Default security group would be inherited to NAT gateways and there is no option to modify these.
  cidr_block           = var.vpc_cidr
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  enable_classiclink   = "false"
  instance_tenancy     = "default"

  tags = {
    Name = "${var.common.project_name}-vpc"
  }
}

resource "aws_flow_log" "all_traffic" {
  iam_role_arn             = aws_iam_role.flow_logs.arn
  log_destination          = aws_cloudwatch_log_group.flow_logs.arn
  traffic_type             = "ALL"
  vpc_id                   = aws_vpc.this.id
  max_aggregation_interval = local.flow_log_aggregation_interval
  log_format               = var.flow_log_format
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "${var.common.project_name}-vpc-flow-logs"
  retention_in_days = local.flow_log_retention_in_days
  kms_key_id        = aws_kms_key.flow_logs.arn
}

resource "aws_kms_key" "flow_logs" {
  description             = "KMS Key for Cloudwatch log group to collect VPC flow logs"
  deletion_window_in_days = local.flow_log_deletion_window_in_days
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.flow_logs_key_policy.json
}

resource "aws_kms_alias" "flow_logs" {
  name          = "alias/${var.common.project_name}-flow-logs-encryption-key"
  target_key_id = aws_kms_key.flow_logs.key_id
}

data "aws_iam_policy_document" "flow_logs_key_policy" {
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
      type        = "Service"
      identifiers = ["logs.eu-central-1.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["*"]
    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:${var.common.aws_region}:${data.aws_caller_identity.current.account_id}:*"]
    }
  }
}

resource "aws_iam_role" "flow_logs" {
  name               = "${var.common.project_name}-vpc-flow-logs"
  assume_role_policy = data.aws_iam_policy_document.flow_logs_role_assume_policy.json
}

data "aws_iam_policy_document" "flow_logs_role_assume_policy" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy" "flow_logs" {
  name   = "${var.common.project_name}-vpc-flow-logs"
  role   = aws_iam_role.flow_logs.id
  policy = data.aws_iam_policy_document.flow_logs_role_policy.json
}

data "aws_iam_policy_document" "flow_logs_role_policy" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = [
      "${aws_cloudwatch_log_group.flow_logs.arn}:*"
    ]
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.common.project_name}"
  }
}

resource "aws_subnet" "public" {
  # checkov:skip=CKV_AWS_130: Public Subnet can have public IPs per default
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = "true"
  availability_zone       = var.availability_zones[count.index]

  tags = {
    Name = "${var.common.project_name}-public-${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  map_public_ip_on_launch = "false"
  availability_zone       = var.availability_zones[count.index]

  tags = {
    Name = "${var.common.project_name}-private-${count.index + 1}"
  }
}

resource "aws_eip" "nat_gateway" {
  count = length(var.public_subnet_cidrs)

  vpc = true
}

resource "aws_nat_gateway" "gateway_for_private_instances" {
  count = length(var.public_subnet_cidrs)

  allocation_id = aws_eip.nat_gateway[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.common.project_name}-public"
  }
}

resource "aws_route_table" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gateway_for_private_instances[count.index].id
  }

  tags = {
    Name = "${var.common.project_name}-private-${count.index + 1}"
  }
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)

  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidrs)

  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_network_acl" "this" {
  vpc_id     = aws_vpc.this.id
  subnet_ids = concat(aws_subnet.public.*.id, aws_subnet.private.*.id)

  tags = {
    "Name" = var.common.project_name
  }
}

#tfsec:ignore:aws-vpc-no-public-ingress Application is reachable via HTTP & HTTPS from the internet
resource "aws_network_acl_rule" "allow_http_and_https_connections" {
  count          = 4
  network_acl_id = aws_network_acl.this.id
  rule_number    = 100 * (count.index % 2 + 1)
  egress         = count.index < 2
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = local.traffic_ports[count.index % 2]
  to_port        = local.traffic_ports[count.index % 2]
}

resource "aws_network_acl_rule" "allow_vpc_connections" {
  count          = 2
  network_acl_id = aws_network_acl.this.id
  rule_number    = 300
  egress         = count.index == 0
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
}

#tfsec:ignore:aws-vpc-no-public-ingress NAT gateway will keep the source IP addresses from requesting clients but exchange ports according. Therefore ephemeral ports need to be open for all IP addresses.
resource "aws_network_acl_rule" "allow_nat_connections" {
  count          = 2
  network_acl_id = aws_network_acl.this.id
  rule_number    = 400
  egress         = count.index == 0
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = local.ephemeral_port_range_by_nat[0]
  to_port        = local.ephemeral_port_range_by_nat[1]
}

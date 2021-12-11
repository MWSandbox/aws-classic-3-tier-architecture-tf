locals {
  target_group_healthy_threshold     = 2
  target_group_health_check_interval = 10
  traffic_ports                      = [80, 443]
}

resource "aws_lb" "entry_point" {
  # checkov:skip=CKV_AWS_150: Load balancers should be deleted on destroy -> whole infrastructure should be removed
  name = var.common.project_name
  #tfsec:ignore:aws-elbv2-alb-not-public ELB is the entrypoint to the application and therefore exposed publicly on purpose
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.public.id]
  subnets                    = var.public_subnet_ids
  drop_invalid_header_fields = true

  access_logs {
    bucket  = var.logs_bucket.id
    prefix  = var.access_logs_prefix
    enabled = true
  }

  tags = {
    Name = var.common.project_name
  }
}

resource "aws_lb_target_group" "app" {
  #ts:skip=AC_AWS_0492 SSL termination on load balancer level - no end-to-end encryption supported yet
  vpc_id   = var.vpc_id
  name     = "${var.common.project_name}-app-target-group"
  port     = 80
  protocol = "HTTP"

  health_check {
    enabled           = true
    healthy_threshold = local.target_group_healthy_threshold
    interval          = local.target_group_health_check_interval
  }
}

resource "aws_lb_listener" "https_traffic_from_internet" {
  load_balancer_arn = aws_lb.entry_point.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.tls_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_security_group" "public" {
  # checkov:skip=CKV2_AWS_5: Security group used for ELB no need for EC2 instance assignment
  vpc_id      = var.vpc_id
  name        = "${var.common.project_name}-public"
  description = "Limit Sources / Destinations for public subnets"

  tags = {
    Name = "${var.common.project_name}-public"
  }
}

resource "aws_security_group_rule" "traffic_from_ip_accept_list" {
  count             = 4
  description       = "Traffic from/to IP accept list"
  type              = count.index <= 1 ? "ingress" : "egress"
  from_port         = local.traffic_ports[count.index % 2]
  to_port           = local.traffic_ports[count.index % 2]
  protocol          = "tcp"
  security_group_id = aws_security_group.public.id
  cidr_blocks       = var.ip_accept_list
}

resource "aws_wafv2_web_acl_association" "load_balancer_firewall" {
  resource_arn = aws_lb.entry_point.arn
  web_acl_arn  = var.web_acl_arn
}

data "aws_route53_zone" "this" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_route53_record" "service" {
  # checkov:skip=CKV2_AWS_23: The calling module is responsible for passing services that are located in the correct AWS account.
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "${var.service_dns_prefix}${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.service_default_dns_name
    zone_id                = var.service_default_zone_id
    evaluate_target_health = true
  }
}

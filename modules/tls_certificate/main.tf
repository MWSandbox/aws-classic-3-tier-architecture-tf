data "aws_route53_zone" "this" {
  name         = var.domain_name
  private_zone = false
}

provider "aws" {
  alias   = "acm_provider"
  profile = "default"
  region  = var.certificate_region

  default_tags {
    tags = {
      Project = var.common.project_name
    }
  }
}

resource "aws_acm_certificate" "tls" {
  provider          = aws.acm_provider
  domain_name       = var.dns_name
  validation_method = "DNS"
}

resource "aws_acm_certificate_validation" "tls" {
  provider                = aws.acm_provider
  certificate_arn         = aws_acm_certificate.tls.arn
  validation_record_fqdns = [for record in aws_route53_record.dns_validation : record.fqdn]
}

resource "aws_route53_record" "dns_validation" {
  provider = aws.acm_provider
  for_each = {
    for option in aws_acm_certificate.tls.domain_validation_options : option.domain_name => {
      name   = option.resource_record_name
      record = option.resource_record_value
      type   = option.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.this.zone_id
}

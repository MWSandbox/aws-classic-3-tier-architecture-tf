<!-- BEGIN_TF_DOCS -->


## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_aws.acm_provider"></a> [aws.acm\_provider](#provider\_aws.acm\_provider) | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_acm_certificate.tls](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate_validation.tls](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) | resource |
| [aws_route53_record.dns_validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_zone.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| <a name="input_certificate_region"></a> [certificate\_region](#input\_certificate\_region) | Region to issue the certificate for. Cloudfront certificates need to be issued in region us-east. | `string` | n/a |
| <a name="input_common"></a> [common](#input\_common) | Common properties reused in multiple modules. | <pre>object({<br>    project_name = string<br>  })</pre> | n/a |
| <a name="input_dns_name"></a> [dns\_name](#input\_dns\_name) | Full DNS name to issue the certificate for. | `string` | n/a |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Name of the domain to issue the certificate for. | `string` | n/a |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_tls_certificate_arn"></a> [tls\_certificate\_arn](#output\_tls\_certificate\_arn) | Arn of the TLS certificate. |
<!-- END_TF_DOCS -->
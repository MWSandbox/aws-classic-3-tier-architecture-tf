<!-- BEGIN_TF_DOCS -->


## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudfront_distribution.frontend](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_cloudfront_origin_access_identity.frontend_bucket_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_identity) | resource |
| [aws_cloudfront_response_headers_policy.secure_header_config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_response_headers_policy) | resource |
| [aws_s3_bucket.frontend](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_policy.access_for_ip_whitelist](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.private_frontend](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.ip_based_access_to_frontend](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| <a name="input_backend_dns_name"></a> [backend\_dns\_name](#input\_backend\_dns\_name) | Full DNS name for the backend. | `string` | n/a |
| <a name="input_common"></a> [common](#input\_common) | Common properties reused in multiple modules. | <pre>object({<br>    project_name = string<br>    aws_region   = string<br>  })</pre> | n/a |
| <a name="input_country_keys_for_caching"></a> [country\_keys\_for\_caching](#input\_country\_keys\_for\_caching) | List of country keys to use as caching locations by CloudFront. | `list(string)` | n/a |
| <a name="input_frontend_dns_name"></a> [frontend\_dns\_name](#input\_frontend\_dns\_name) | Full DNS name for the frontend S3 bucket. | `string` | n/a |
| <a name="input_ip_accept_list"></a> [ip\_accept\_list](#input\_ip\_accept\_list) | List of IPv4 addresses that should be able to call the application. All other IP addresses will be blocked by WAFv2 and S3 bucket policies. To permit access from everywhere, please add 0.0.0.0/0 to the list. | `list(string)` | n/a |
| <a name="input_logs_bucket"></a> [logs\_bucket](#input\_logs\_bucket) | Bucket containing log files. | <pre>object({<br>    id                 = string<br>    arn                = string<br>    bucket_domain_name = string<br>  })</pre> | n/a |
| <a name="input_tls_certificate_arn"></a> [tls\_certificate\_arn](#input\_tls\_certificate\_arn) | Arn of the certificate to use for HTTPS protocol. | `string` | n/a |
| <a name="input_web_acl_arn"></a> [web\_acl\_arn](#input\_web\_acl\_arn) | Arn of the Web ACL to apply to the cloudfront distribution as firewall. | `string` | n/a |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudfront_dns_name"></a> [cloudfront\_dns\_name](#output\_cloudfront\_dns\_name) | The default DNS name generated by AWS when creating the cloudfront distribution. |
| <a name="output_cloudfront_zone_id"></a> [cloudfront\_zone\_id](#output\_cloudfront\_zone\_id) | The default DNS zone ID generated by AWS when creating cloudfront distribution. |
<!-- END_TF_DOCS -->
<!-- BEGIN_TF_DOCS -->


## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws.wafv2"></a> [aws.wafv2](#provider\_aws.wafv2) | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_wafv2_ip_set.ip_accept_list](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_ip_set) | resource |
| [aws_wafv2_rule_group.block_all_ips_but_ip_accept_list](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_rule_group) | resource |
| [aws_wafv2_web_acl.general_firewall](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl) | resource |

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| <a name="input_common"></a> [common](#input\_common) | Common properties reused in multiple modules. | <pre>object({<br>    project_name = string<br>    aws_region   = string<br>  })</pre> | n/a |
| <a name="input_ip_accept_list"></a> [ip\_accept\_list](#input\_ip\_accept\_list) | List of IPv4 addresses that should be able to call the application. All other IP addresses will be blocked by WAFv2 and S3 bucket policies. To permit access from everywhere, please add 0.0.0.0/0 to the list. | `list(string)` | n/a |
| <a name="input_scope"></a> [scope](#input\_scope) | Scope of the WAFv2 resources. | `string` | n/a |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_web_acl_arn"></a> [web\_acl\_arn](#output\_web\_acl\_arn) | Arn of the Web ACL. |
<!-- END_TF_DOCS -->
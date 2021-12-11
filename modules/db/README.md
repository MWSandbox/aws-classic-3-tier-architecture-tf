<!-- BEGIN_TF_DOCS -->


## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_db_instance.app_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) | resource |
| [aws_db_subnet_group.app_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_iam_policy.access_to_cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.access_to_cloudwatch_for_rds_monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_security_group.app_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_iam_policy_document.access_to_cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.rds_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_secretsmanager_secret.password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |
| [aws_secretsmanager_secret_version.current_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | List of availability zones to run the database. | `list(string)` | n/a |
| <a name="input_backup_retention_period_in_days"></a> [backup\_retention\_period\_in\_days](#input\_backup\_retention\_period\_in\_days) | Period in days in which backups of the DB should be kept. | `number` | `2` |
| <a name="input_common"></a> [common](#input\_common) | Common properties reused in multiple modules. | <pre>object({<br>    project_name = string<br>    aws_region   = string<br>  })</pre> | n/a |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | Name of the database to be created. | `string` | n/a |
| <a name="input_db_password_secret_key"></a> [db\_password\_secret\_key](#input\_db\_password\_secret\_key) | Key inside the secret in AWS Secrets Manager referencing the DB password. | `string` | n/a |
| <a name="input_db_password_secret_name"></a> [db\_password\_secret\_name](#input\_db\_password\_secret\_name) | Name of the secret in AWS Secrets Manager holding the DB password. | `string` | n/a |
| <a name="input_db_user"></a> [db\_user](#input\_db\_user) | DB user to be created. | `string` | n/a |
| <a name="input_instance_class"></a> [instance\_class](#input\_instance\_class) | Instance class to use for the DB servers. | `string` | `"db.t3.small"` |
| <a name="input_monitoring_interval_in_seconds"></a> [monitoring\_interval\_in\_seconds](#input\_monitoring\_interval\_in\_seconds) | Period in seconds in which the enhanced monitoring metrics of the DB instance should be collected. | `number` | `60` |
| <a name="input_postgres_version"></a> [postgres\_version](#input\_postgres\_version) | Postgres version to provision the DB instance. | `string` | `"11"` |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | IDs of the private subnets in which the DB instances should be deployed to | `list(string)` | n/a |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC that contains the infrastructure | `string` | n/a |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_endpoint"></a> [endpoint](#output\_endpoint) | Endpoint of the created database. |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | Rules can be assigned to this security group in order to permit traffic to the database. |
<!-- END_TF_DOCS -->
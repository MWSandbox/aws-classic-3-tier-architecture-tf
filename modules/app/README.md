<!-- BEGIN_TF_DOCS -->


## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_template"></a> [template](#provider\_template) | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group.server](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_autoscaling_policy.scaling_based_on_cpu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_policy) | resource |
| [aws_iam_instance_profile.server](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_policy.access_to_ecr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.access_to_secrets_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.server](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.access_to_ecr_for_server](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.access_to_secrets_manager_for_server](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.access_to_ssm_session_manager_for_server](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_kms_alias.server](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.server](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_launch_template.server](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_security_group.server](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.inbound_traffic_from_elb_to_app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.outbound_traffic_from_app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.reachability_of_app_from_db](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.reachability_of_app_from_elb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.reachability_of_db_from_app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.access_to_ecr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.access_to_secrets_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.server_key_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [template_file.ec2_user_data](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| <a name="input_ami"></a> [ami](#input\_ami) | AMI to use for provisioning the EC2 instances of the app servers. | `string` | `"ami-058e6df85cfc7760b"` |
| <a name="input_app_version_to_deploy"></a> [app\_version\_to\_deploy](#input\_app\_version\_to\_deploy) | Default version of the app to deploy (e.g. latest) - separate docker repository should be used per environment. | `string` | n/a |
| <a name="input_backend_dns_name"></a> [backend\_dns\_name](#input\_backend\_dns\_name) | DNS name that should be used for the backend. | `string` | n/a |
| <a name="input_common"></a> [common](#input\_common) | Common properties reused in multiple modules. | <pre>object({<br>    project_name = string<br>    aws_region   = string<br>  })</pre> | n/a |
| <a name="input_context_path"></a> [context\_path](#input\_context\_path) | Context path on which the app will be deployed. | `string` | n/a |
| <a name="input_db_endpoint"></a> [db\_endpoint](#input\_db\_endpoint) | Endpoint of the DB to connect to. | `string` | n/a |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | Name of the DB to connect to. | `string` | n/a |
| <a name="input_db_secret_name"></a> [db\_secret\_name](#input\_db\_secret\_name) | Name of the secret in AWS Secrets Manager holding the DB password. | `string` | n/a |
| <a name="input_db_security_group_id"></a> [db\_security\_group\_id](#input\_db\_security\_group\_id) | ID of the security group used by the DB the app should connect to. | `string` | n/a |
| <a name="input_db_user"></a> [db\_user](#input\_db\_user) | User for the DB connection. | `string` | n/a |
| <a name="input_ecr_repository"></a> [ecr\_repository](#input\_ecr\_repository) | Name of the repository containing the app images. | `string` | n/a |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | Instance type of the EC2 instances running the app servers. | `string` | `"t2.micro"` |
| <a name="input_load_balancer_security_group_id"></a> [load\_balancer\_security\_group\_id](#input\_load\_balancer\_security\_group\_id) | Only the security group of the load balancer is allowed to send traffic to EC2 instances | `string` | n/a |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | IDs of the private subnets in which the EC2 instances should be deployed to | `list(string)` | n/a |
| <a name="input_scaling"></a> [scaling](#input\_scaling) | Properties used to autoscale the appservers. | <pre>object({<br>    desired_capacity = number<br>    min_capacity     = number<br>    max_capacity     = number<br>    cpu_threshold    = number<br>  })</pre> | <pre>{<br>  "cpu_threshold": 60,<br>  "desired_capacity": 2,<br>  "max_capacity": 4,<br>  "min_capacity": 2<br>}</pre> |
| <a name="input_target_group_arn"></a> [target\_group\_arn](#input\_target\_group\_arn) | ARN of the load balancer target group that should forward the traffic to the EC2 instances | `string` | n/a |
| <a name="input_volume_size"></a> [volume\_size](#input\_volume\_size) | EBS volume size for the app servers EC2 instances. | `number` | `8` |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC that contains the infrastructure | `string` | n/a |
<!-- END_TF_DOCS -->
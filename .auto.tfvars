common = {
  aws_region   = "to-be-changed"
  project_name = "to-be-changed"
}

# DNS properties
domain_name         = "to-be-changed"
backend_dns_prefix  = "to-be-changed."
frontend_dns_prefix = "to-be-changed."

# Network properties
availability_zones    = ["to-be-changed", "to-be-changed"]
static_ip_accept_list = []
is_own_ip_restricted  = true

# DB properties
db_name                 = "to-be-changed"
db_password_secret_key  = "to-be-changed"
db_password_secret_name = "to-be-changed"
db_user                 = "to-be-changed"

# App properties
ecr_repository        = "to-be-changed"
context_path          = "to-be-changed"
app_version_to_deploy = "to-be-changed"

# Other
country_keys_for_caching = "to-be-changed"

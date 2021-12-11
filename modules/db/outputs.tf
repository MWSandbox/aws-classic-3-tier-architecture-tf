output "security_group_id" {
  description = "Rules can be assigned to this security group in order to permit traffic to the database."
  value       = aws_security_group.app_data.id
}

output "endpoint" {
  description = "Endpoint of the created database."
  value       = aws_db_instance.app_data.endpoint
}
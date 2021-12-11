output "vpc_id" {
  description = "ID of the VPC containing the infrastructure"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "List of IDs of all public subnets in the VPC"
  value       = aws_subnet.public.*.id
}

output "private_subnet_ids" {
  description = "List of IDs of all private subnets in the VPC"
  value       = aws_subnet.private.*.id
}

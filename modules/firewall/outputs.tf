output "web_acl_arn" {
  description = "Arn of the Web ACL."
  value       = aws_wafv2_web_acl.general_firewall.arn
}
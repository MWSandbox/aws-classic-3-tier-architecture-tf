output "tls_certificate_arn" {
  description = "Arn of the TLS certificate."
  value       = aws_acm_certificate.tls.arn
}

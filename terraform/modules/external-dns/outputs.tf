output "role_arn" {
  description = "The ID of the badge the DNS helper wears"
  value       = aws_iam_role.external_dns.arn
}
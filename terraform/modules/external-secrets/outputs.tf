output "role_arn" {
  description = "The ID of the badge the ESO wears"
  value       = aws_iam_role.external_secrets.arn
}
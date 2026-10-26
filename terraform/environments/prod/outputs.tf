output "cluster_name" {
  description = "The name of the cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "The API endpoint of the cluster"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate" {
  description = "The cluster certificate to verify the cluster"
  value       = module.eks.cluster_certificate
}

output "external_secrets_role_arn" {
  description = "The badge the password helper wears"
  value       = module.external_secrets.role_arn
}
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
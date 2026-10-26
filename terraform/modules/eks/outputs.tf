output "cluster_name" {
  description = "The name of the Cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "The network address where kubectl and terraform send commands to"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_certificate" {
  description = "The cluster certificate to verify the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "oidc_provider_arn" {
  description = "The ID of the trusted badge issuer in AWS"
  value       = aws_iam_openid_connect_provider.cluster.arn
}

output "oidc_provider_url" {
  description = "The address of the trusted badge issuer"
  value       = aws_iam_openid_connect_provider.cluster.url
}
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


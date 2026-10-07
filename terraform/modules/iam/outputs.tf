output "cluster_role_arn" {
  description = "The iam role arn for the cluster"
  value       = aws_iam_role.cluster_role.arn
}

output "node_role_arn" {
  description = "The iam role arn for the nodes"
  value       = aws_iam_role.node_role.arn
}
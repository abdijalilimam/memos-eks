output "cluster_role_arn" {
  description = "The iam role arn for the cluster"
  value       = aws_iam_role.cluster_role.arn
  depends_on  = [aws_iam_role_policy_attachment.cluster_policy]
}

output "node_role_arn" {
  description = "The iam role arn for the nodes"
  value       = aws_iam_role.node_role.arn
  depends_on  = [aws_iam_role_policy_attachment.node_policy]
}
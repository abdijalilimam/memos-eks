output "node_sg_id" {
  description = "ID of the security group for the EKS nodes"
  value       = aws_security_group.node_sg.id
}
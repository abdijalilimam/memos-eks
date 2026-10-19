#Security group for EKS worker nodes
resource "aws_security_group" "node_sg" {
  name        = "${var.name}-node-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name}-node-sg"
  }
}

# What is allowed to come in to public subnet 1
resource "aws_vpc_security_group_ingress_rule" "lb_s1" {
  description       = "The incoming traffic rule for public subnet 1"
  security_group_id = aws_security_group.node_sg.id
  cidr_ipv4         = var.public_s1_cidr
  ip_protocol       = "tcp"
  from_port         = 30000
  to_port           = 32767
}

# What is allowed to come in to public subnet 2
resource "aws_vpc_security_group_ingress_rule" "lb_s2" {
  description       = "The incoming traffic rule for public subnet 2"
  security_group_id = aws_security_group.node_sg.id
  cidr_ipv4         = var.public_s2_cidr
  ip_protocol       = "tcp"
  from_port         = 30000
  to_port           = 32767
}

# What is allowed to come in to public subnet 3
resource "aws_vpc_security_group_ingress_rule" "lb_s3" {
  description       = "The incoming traffic rule for public subnet 3"
  security_group_id = aws_security_group.node_sg.id
  cidr_ipv4         = var.public_s3_cidr
  ip_protocol       = "tcp"
  from_port         = 30000
  to_port           = 32767
}
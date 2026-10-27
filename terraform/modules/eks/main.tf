# EKS cluster 
resource "aws_eks_cluster" "main" {
  name     = "${var.name}-cluster"
  role_arn = var.cluster_role_arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = concat(var.public_subnet_ids, var.private_subnet_ids)
    endpoint_public_access  = true
    endpoint_private_access = true
  }
}

#launch template (ec2 instance pre settings)
resource "aws_launch_template" "node_template" {
  name_prefix = "${var.name}-node-template"

  vpc_security_group_ids = [
    var.node_sg_id,
    aws_eks_cluster.main.vpc_config[0].cluster_security_group_id,
  ]
}

#EKS worker nodes 
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.name}-nodes"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = [var.instance_type]

  scaling_config {
    desired_size = var.desired_size
    min_size     = var.min_size
    max_size     = var.max_size
  }

  launch_template {
    id      = aws_launch_template.node_template.id
    version = aws_launch_template.node_template.latest_version
  }
}

#OIDC
resource "aws_iam_openid_connect_provider" "cluster" {
  url            = aws_eks_cluster.main.identity[0].oidc[0].issuer
  client_id_list = ["sts.amazonaws.com"]
}

#EBS CSI driver (lets pods get AWS disks)
locals {
  oidc_host = replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")
}

# The badge: only the disk driver's service account in this cluster can wear it
resource "aws_iam_role" "ebs_csi" {
  name = "${var.name}-ebs-csi"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity"
        Principal = {
          Federated = aws_iam_openid_connect_provider.cluster.arn
        }
        Condition = {
          StringEquals = {
            "${local.oidc_host}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
            "${local.oidc_host}:aud" = "sts.amazonaws.com"
          }
        }
      },
    ]
  })

  tags = {
    Name = "${var.name}-ebs-csi"
  }
}

# What the badge allows: AWS's ready-made list of disk permissions
resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# AWS installs the driver for you and hands it the badge
resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi.arn

  depends_on = [
    aws_eks_node_group.main,
    aws_iam_role_policy_attachment.ebs_csi,
  ]
}
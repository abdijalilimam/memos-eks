data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  region     = data.aws_region.current.region
  account_id = data.aws_caller_identity.current.account_id
  secret_arn = "arn:aws:secretsmanager:${local.region}:${local.account_id}:secret:${var.secret_prefix}*"

  oidc_host = replace(var.oidc_provider_url, "https://", "")
}

# The badge: ESO wears it
resource "aws_iam_role" "external_secrets" {
  name = "${var.name}-external-secrets"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${local.oidc_host}:sub" = "system:serviceaccount:external-secrets:external-secrets"
            "${local.oidc_host}:aud" = "sts.amazonaws.com"
          }
        }
      },
    ]
  })

  tags = {
    Name = "${var.name}-external-secrets"
  }
}

# Policy for ESO 
resource "aws_iam_role_policy" "read_secrets" {
  name = "${var.name}-read-secrets"
  role = aws_iam_role.external_secrets.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
        ]
        Resource = local.secret_arn
      },
    ]
  })
}
# Look up your existing DNS zone (this builds nothing)
data "aws_route53_zone" "this" {
  name = var.domain_name
}

locals {
  oidc_host = replace(var.oidc_provider_url, "https://", "")
}

# The badge: only the DNS helper in this cluster can wear it
resource "aws_iam_role" "external_dns" {
  name = "${var.name}-external-dns"

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
            "${local.oidc_host}:sub" = "system:serviceaccount:external-dns:external-dns"
            "${local.oidc_host}:aud" = "sts.amazonaws.com"
          }
        }
      },
    ]
  })

  tags = {
    Name = "${var.name}-external-dns"
  }
}

# What the badge allows: edit records in this one zone, and look around
resource "aws_iam_role_policy" "dns" {
  name = "${var.name}-dns"
  role = aws_iam_role.external_dns.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["route53:ChangeResourceRecordSets"]
        Resource = data.aws_route53_zone.this.arn
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets",
          "route53:ListTagsForResource",
        ]
        Resource = "*"
      },
    ]
  })
}
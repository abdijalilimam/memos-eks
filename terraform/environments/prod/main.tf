module "vpc" {
  source            = "../../modules/vpc"
  name              = var.name
  vpc_cidr          = var.vpc_cidr
  availability_mode = var.availability_mode
  connectivity_type = var.connectivity_type
  az1               = var.az1
  public_s1_cidr    = var.public_s1_cidr
  public_s1_tags    = var.public_s1_tags
  private_s1_cidr   = var.private_s1_cidr
  private_s1_tags   = var.private_s1_tags
  az2               = var.az2
  public_s2_cidr    = var.public_s2_cidr
  public_s2_tags    = var.public_s2_tags
  private_s2_cidr   = var.private_s2_cidr
  private_s2_tags   = var.private_s2_tags
  az3               = var.az3
  public_s3_cidr    = var.public_s3_cidr
  public_s3_tags    = var.public_s3_tags
  private_s3_cidr   = var.private_s3_cidr
  private_s3_tags   = var.private_s3_tags

}

module "sg" {
  source = "../../modules/sg"

  name           = var.name
  vpc_id         = module.vpc.vpc_id
  public_s1_cidr = var.public_s1_cidr
  public_s2_cidr = var.public_s2_cidr
  public_s3_cidr = var.public_s3_cidr
}

module "iam" {
  source = "../../modules/iam"

  name = var.name
}

module "eks" {
  source = "../../modules/eks"

  name               = var.name
  cluster_role_arn   = module.iam.cluster_role_arn
  node_role_arn      = module.iam.node_role_arn
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  node_sg_id         = module.sg.node_sg_id
  kubernetes_version = var.kubernetes_version
  instance_type      = var.instance_type
  desired_size       = var.desired_size
  min_size           = var.min_size
  max_size           = var.max_size
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "10.10.5"

  depends_on = [module.eks]
}

module "external_secrets" {
  source = "../../modules/external-secrets"

  name              = var.name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  secret_prefix     = var.secret_prefix
}
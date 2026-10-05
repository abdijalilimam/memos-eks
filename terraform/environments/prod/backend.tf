terraform {
  backend "s3" {
    bucket       = "memos-eks-tfstate-305476115260"
    key          = "memos-eks/prod/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}

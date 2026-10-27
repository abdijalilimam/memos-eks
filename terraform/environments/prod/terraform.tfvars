name              = "memos-eks"
vpc_cidr          = "10.0.0.0/16"
availability_mode = "regional"
connectivity_type = "public"

az1 = "us-east-2a"
az2 = "us-east-2b"
az3 = "us-east-2c"

public_s1_cidr = "10.0.1.0/24"
public_s2_cidr = "10.0.2.0/24"
public_s3_cidr = "10.0.3.0/24"

public_s1_tags = "memos-eks-public-1"
public_s2_tags = "memos-eks-public-2"
public_s3_tags = "memos-eks-public-3"

private_s1_cidr = "10.0.11.0/24"
private_s2_cidr = "10.0.12.0/24"
private_s3_cidr = "10.0.13.0/24"

private_s1_tags = "memos-eks-private-1"
private_s2_tags = "memos-eks-private-2"
private_s3_tags = "memos-eks-private-3"

kubernetes_version = "1.37"
instance_type      = "t3.medium"
desired_size       = 3
min_size           = 2
max_size           = 4

secret_prefix = "memos-eks/prod/"

domain_name = "abdijalil.dev"
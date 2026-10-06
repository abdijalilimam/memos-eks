locals {
  public_subnets = {
    s1 = {
      cidr_block        = var.public_s1_cidr
      availability_zone = var.az1
      tags = {
        Name = var.public_s1_tags
      }
    }

    s2 = {
      cidr_block        = var.public_s2_cidr
      availability_zone = var.az2
      tags = {
        Name = var.public_s2_tags
      }
    }

    s3 = {
      cidr_block        = var.public_s3_cidr
      availability_zone = var.az3
      tags = {
        Name = var.public_s3_tags
      }
    }
  }

  private_subnets = {
    s1 = {
      cidr_block        = var.private_s1_cidr
      availability_zone = var.az1
      tags = {
        Name = var.private_s1_tags
      }
    }

    s2 = {
      cidr_block        = var.private_s2_cidr
      availability_zone = var.az2
      tags = {
        Name = var.private_s2_tags
      }
    }

    s3 = {
      cidr_block        = var.private_s3_cidr
      availability_zone = var.az3
      tags = {
        Name = var.private_s3_tags
      }
    }
  }
}
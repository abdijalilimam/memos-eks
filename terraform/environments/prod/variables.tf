variable "name" {
  description = "The prefix name for resources"
  type        = string
}

variable "vpc_cidr" {
  description = "The VPC range"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_mode" {
  description = "NAT gateway availability mode"
  type        = string
}

variable "connectivity_type" {
  description = "NAT gateway connectivity type"
  type        = string
}

variable "az1" {
  description = "First availability zone"
  type        = string
}

variable "public_s1_cidr" {
  description = "Public subnet 1 cidr"
  type        = string

}

variable "public_s1_tags" {
  description = "Public subnet tag 1"
  type        = string
}

variable "private_s1_cidr" {
  description = "Private subnet 1 cidr"
  type        = string

}

variable "private_s1_tags" {
  description = "Private subnet tag 1"
  type        = string
}

variable "az2" {
  description = "Second availability zone"
  type        = string
}

variable "public_s2_cidr" {
  description = "Public subnet 2 cidr"
  type        = string

}

variable "public_s2_tags" {
  description = "Public subnet tag 2"
  type        = string
}

variable "private_s2_cidr" {
  description = "Private subnet 2 cidr"
  type        = string

}

variable "private_s2_tags" {
  description = "Private subnet tag 2"
  type        = string
}

variable "az3" {
  description = "Third availability zone"
  type        = string
}

variable "public_s3_cidr" {
  description = "Public subnet 3 cidr"
  type        = string

}

variable "public_s3_tags" {
  description = "Public subnet tag 3"
  type        = string
}

variable "private_s3_cidr" {
  description = "Private subnet 3 cidr"
  type        = string

}

variable "private_s3_tags" {
  description = "Private subnet tag 3"
  type        = string
}

variable "kubernetes_version" {
  description = "The version of Kubernetes"
  type        = string
}

variable "instance_type" {
  description = "The instance type for the worker nodes"
  type        = string
}

variable "desired_size" {
  description = "The desired number of nodes"
  type        = number
}

variable "min_size" {
  description = "The smallest number of nodes"
  type        = number
}

variable "max_size" {
  description = "The largest number of nodes"
  type        = number
}

variable "secret_prefix" {
  description = "The start of the secret names the helper may read"
  type        = string
}

variable "domain_name" {
  description = "The domain whose DNS records the helper may edit"
  type        = string
}
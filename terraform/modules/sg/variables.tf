variable "name" {
  description = "The prefix name for resources"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID"
  type        = string
}

variable "public_s1_cidr" {
  description = "Public subnet 1 cidr"
  type        = string

}

variable "public_s2_cidr" {
  description = "Public subnet 2 cidr"
  type        = string

}

variable "public_s3_cidr" {
  description = "Public subnet 3 cidr"
  type        = string

}

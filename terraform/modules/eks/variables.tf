variable "name" {
  description = "The prefix name for resources"
  type        = string
}

variable "public_subnet_ids" {
  description = "The public subnet ids"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "The private subnet ids"
  type        = list(string)
}

variable "cluster_role_arn" {
  description = "The arn for Cluster"
  type        = string
}

variable "node_role_arn" {
  description = "The arn for nodes"
  type        = string
}

variable "node_sg_id" {
  description = "The nodes security group id"
  type        = string
}

variable "kubernetes_version" {
  description = "The version of Kubernetes"
  type        = string
}

variable "instance_type" {
  description = "The instance type"
  type        = string
}

variable "desired_size" {
  description = "The desired number of nodes "
  type        = number
}

variable "max_size" {
  description = "The largest number of nodes"
  type        = number
}

variable "min_size" {
  description = "The smallest number of nodes"
  type        = number
}

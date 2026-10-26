variable "name" {
  description = "The prefix name for resources"
  type        = string
}

variable "oidc_provider_arn" {
  description = "The ID of OIDC in AWS"
  type        = string
}

variable "oidc_provider_url" {
  description = "The address of OIDC "
  type        = string
}

variable "secret_prefix" {
  description = "The start of the secret names the ESO is allowed to read"
  type        = string
}
variable "name" {
  description = "The prefix name for resources"
  type        = string
}

variable "oidc_provider_arn" {
  description = "The ID of the trusted badge issuer in AWS"
  type        = string
}

variable "oidc_provider_url" {
  description = "The address of the trusted badge issuer"
  type        = string
}

variable "domain_name" {
  description = "The domain whose DNS records the helper may edit"
  type        = string
}
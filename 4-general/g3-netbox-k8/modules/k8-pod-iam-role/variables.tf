variable "policy_document_json" {
  description = "IAM policy document JSON string to use for the IAM role"
  type        = string
}

variable "name" {
  description = "Name of the IAM role to be created"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider to trust"
  type        = string
}
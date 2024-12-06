
variable "prefix" {
  description = "prefix used for all resources"
  default     = "c"
}

variable "aws_access_key" {
  description = "account access key"
}

variable "aws_secret_access_key" {
  description = "account secret key"
}

variable "public_key_path" {
  description = "path to public key for ec2 SSH"
  default     = null
}

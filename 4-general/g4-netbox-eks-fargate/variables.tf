
variable "prefix" {
  description = "prefix used for all resources"
  default     = "g4"
}

variable "public_key_path" {
  description = "path to public key for ec2 SSH"
}

variable "ami_ids" {
  description = "list of AMI IDs to use for instances"
  type        = map(string)
  default = {
    "netbox-community" = "ami-0a48818358b2711d7"
  }
}

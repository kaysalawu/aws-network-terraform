
variable "name" {
  description = "ec2 instance name. also used as prefix for other resources"
  type        = string
}

variable "env" {
  description = "environment name"
  type        = string
  default     = "dev"
}

variable "availability_zone" {
  description = "availability zone"
  type        = string
}

variable "instance_type" {
  description = "instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami" {
  description = "ami id"
  type        = string
}

variable "key_name" {
  description = "key pair name"
  type        = string
  default     = null
}

variable "tags" {
  description = "tags for all hub resources"
  type        = map(any)
  default     = {}
}

variable "enable_ipv6" {
  description = "enable ipv6 for the ec2 instance"
  type        = bool
  default     = false
}

variable "instance_metadata_tags" {
  description = "enable instance metadata tags"
  type        = string
  default     = "enabled"
}

variable "iam_instance_profile" {
  description = "iam instance profile"
  type        = string
  default     = null
}

variable "vpc_security_group_ids" {
  description = "vpc security group ids"
  type        = list(string)
  default     = []
}

variable "user_data" {
  description = "user data for the ec2 instance"
  type        = string
  default     = null
}

variable "interfaces" {
  description = "list of interfaces"
  type = list(object({
    name                    = string
    subnet_id               = string
    private_ip_list_enabled = optional(bool, true)
    private_ip_list         = optional(list(string), [])
    security_group_ids      = optional(list(string), [])
    ipv6_addresses          = optional(list(string), [])
    create_eip              = optional(bool, false)
    eip_id                  = optional(string, null)
    eip_tag_name            = optional(string, null)
    public_ip               = optional(string, null)
    source_dest_check       = optional(bool, true)
    dns_config = optional(object({
      public    = optional(string, false)
      zone_name = optional(string, null)
      name      = optional(string, null)
      type      = optional(string, "A")
      ttl       = optional(number, 300)
    }), {})
  }))
  default = []
}

variable "source_dest_check" {
  description = "enable/disable source/dest check"
  type        = bool
  default     = null
}

variable "root_block_device" {
  description = "Customize details about the root block device of the instance. See Block Devices below for details"
  type = object({
    delete_on_termination = optional(bool, true)
    encrypted             = optional(bool, false)
    iops                  = optional(number, null)
    kms_key_id            = optional(string, null)
    tags                  = optional(map(string), {})
    throughput            = optional(number, null)
    volume_size           = optional(number, null)
    volume_type           = optional(string, null) # standard, gp2, gp3, io1, io2, sc1, st1.
  })
  default = null
}

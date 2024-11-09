
variable "name" {
  description = "Name to be used on all the resources as identifier"
  type        = string
  default     = ""
}

variable "create_tgw" {
  description = "Controls if TGW should be created (it affects almost all resources)"
  type        = bool
  default     = true
}

variable "amazon_side_asn" {
  description = "The Autonomous System Number (ASN) for the Amazon side of the gateway. By default the TGW is created with the current default Amazon ASN."
  type        = string
  default     = null
}

variable "transit_gateway_id" {
  description = "The ID of the EC2 Transit Gateway. If not provided, a new one will be created."
  type        = string
  default     = null
}

################################################################################
# Transit Gateway
################################################################################

variable "auto_accept_shared_attachments" {
  description = "Whether resource attachment requests are automatically accepted"
  type        = string
  default     = "enable"
}

variable "default_route_table_association" {
  description = "Whether resource attachments are automatically associated with the default association route table"
  type        = string
  default     = "enable"
}

variable "default_route_table_propagation" {
  description = "Whether resource attachments automatically propagate routes to the default propagation route table"
  type        = string
  default     = "enable"
}

variable "description" {
  description = "Description of the EC2 Transit Gateway"
  type        = string
  default     = null
}

variable "dns_support" {
  description = "Should be true to enable DNS support in the TGW"
  type        = string
  default     = "enable"
}

variable "security_group_referencing_support" {
  description = "Whether Security Group Referencing Support is enabled"
  type        = string
  default     = "disable"
}

variable "multicast_support" {
  description = "Whether multicast support is enabled"
  type        = string
  default     = "disable"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "transit_gateway_cidr_blocks" {
  description = "One or more IPv4 or IPv6 CIDR blocks for the transit gateway. Must be a size /24 CIDR block or larger for IPv4, or a size /64 CIDR block or larger for IPv6"
  type        = list(string)
  default     = []
}

variable "vpn_ecmp_support" {
  description = "Whether VPN Equal Cost Multipath Protocol support is enabled"
  type        = string
  default     = "enable"
}

variable "timeouts" {
  description = "Create, update, and delete timeout configurations for the transit gateway"
  type        = map(string)
  default     = {}
}

variable "tgw_tags" {
  description = "Additional tags for the TGW"
  type        = map(string)
  default     = {}
}

variable "tgw_default_route_table_tags" {
  description = "Additional tags for the Default TGW route table"
  type        = map(string)
  default     = {}
}

# ################################################################################
# # VPC Attachment
# ################################################################################

variable "vpc_attachments" {
  description = "A map of VPC attachments to create with the EC2 Transit Gateway"
  type = list(object({
    name                   = string
    route_table            = optional(string, null)
    subnet_ids             = list(string)
    vpc_id                 = string
    appliance_mode_support = optional(string, "disable")
    dns_support            = optional(string, "enable")
    ipv6_support           = optional(string, "disable")

    security_group_referencing_support              = optional(string, "disable")
    transit_gateway_default_route_table_association = optional(bool, false)
    transit_gateway_default_route_table_propagation = optional(bool, false)

    vpc_routes = optional(list(object({
      name           = string
      ipv4_prefixes  = optional(list(string), [])
      ipv6_prefixes  = optional(list(string), [])
      route_table_id = string
    })), [])

    transit_gateway_routes = optional(list(object({
      route_table_name = string
      name             = string
      ipv4_prefixes    = optional(list(string), [])
      blackhole        = optional(bool, false)
      attachment_name  = optional(string, null)
    })), [])
  }))
  default = []

  validation {
    condition = alltrue([
      for attachment in var.vpc_attachments : alltrue([
        for route in attachment.transit_gateway_routes :
        !(route.blackhole && route.attachment_name != null)
      ])
    ])
    error_message = "Validation failed: If 'blackhole' is true in 'transit_gateway_routes', 'attachment_name' must not be specified, and vice versa."
  }
}

variable "tgw_vpc_attachment_tags" {
  description = "Additional tags for VPC attachments"
  type        = map(string)
  default     = {}
}

# ################################################################################
# # Route Table / Routes
# ################################################################################

variable "route_tables" {
  description = "List of route table configurations with tags"
  type = list(object({
    name = string
  }))
  default = []
}

# variable "create_tgw_routes" {
#   description = "Controls if TGW Route Table / Routes should be created"
#   type        = bool
#   default     = true
# }

# variable "transit_gateway_route_table_id" {
#   description = "Identifier of EC2 Transit Gateway Route Table to use with the Target Gateway when reusing it between multiple TGWs"
#   type        = string
#   default     = null
# }

# variable "tgw_route_table_tags" {
#   description = "Additional tags for the TGW route table"
#   type        = map(string)
#   default     = {}
# }

################################################################################
# Resource Access Manager
################################################################################

variable "share_tgw" {
  description = "Whether to share your transit gateway with other accounts"
  type        = bool
  default     = true
}

variable "ram_name" {
  description = "The name of the resource share of TGW"
  type        = string
  default     = ""
}

variable "ram_allow_external_principals" {
  description = "Indicates whether principals outside your organization can be associated with a resource share."
  type        = bool
  default     = false
}

variable "ram_principals" {
  description = "A list of principals to share TGW with. Possible values are an AWS account ID, an AWS Organizations Organization ARN, or an AWS Organizations Organization Unit ARN"
  type        = list(string)
  default     = []
}

variable "ram_resource_share_arn" {
  description = "ARN of RAM resource share"
  type        = string
  default     = ""
}

variable "ram_tags" {
  description = "Additional tags for the RAM"
  type        = map(string)
  default     = {}
}


variable "prefix" {
  description = "prefix to append before all resources"
  type        = string
}

variable "env" {
  description = "environment name"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "vpc region"
  type        = string
}

variable "tags" {
  description = "tags for all hub resources"
  type        = map(any)
  default     = {}
}

variable "admin_username" {
  description = "test username. please change for production"
  type        = string
  default     = "ubuntu"
}

variable "admin_password" {
  description = "test password. please change for production"
  type        = string
  default     = "Password123"
}

variable "ssh_public_key" {
  description = "sh public key data"
  type        = string
  default     = null
}

variable "cidr" {
  description = "(Optional) The IPv4 CIDR blocks for the VPC. CIDR can be explicitly set or it can be derived from IPAM using `ipv4_netmask_length` & `ipv4_ipam_pool_id`"
  type        = list(string)
  default     = "10.0.0.0/16"
}

variable "secondary_cidr_blocks" {
  description = "List of secondary CIDR blocks to associate with the VPC to extend the IP Address pool"
  type        = list(string)
  default     = []
}

variable "instance_tenancy" {
  description = "A tenancy option for instances launched into the VPC"
  type        = string
  default     = "default"
}

variable "enable_dns_hostnames" {
  description = "Should be true to enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Should be true to enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "enable_network_address_usage_metrics" {
  description = "Determines whether network address usage metrics are enabled for the VPC"
  type        = bool
  default     = null
}

variable "use_ipam_pool" {
  description = "Determines whether IPAM pool is used for CIDR allocation"
  type        = bool
  default     = false
}

variable "ipv4_ipam_pool_id" {
  description = "(Optional) The ID of an IPv4 IPAM pool you want to use for allocating this VPC's CIDR"
  type        = string
  default     = null
}

variable "ipv4_netmask_length" {
  description = "(Optional) The netmask length of the IPv4 CIDR you want to allocate to this VPC. Requires specifying a ipv4_ipam_pool_id"
  type        = number
  default     = null
}

variable "enable_ipv6" {
  description = "Requests an Amazon-provided IPv6 CIDR block with a /56 prefix length for the VPC. You cannot specify the range of IP addresses, or the size of the CIDR block"
  type        = bool
  default     = false
}

variable "ipv6_cidr" {
  description = "(Optional) IPv6 CIDR block to request from an IPAM Pool. Can be set explicitly or derived from IPAM using `ipv6_netmask_length`"
  type        = string
  default     = null
}

variable "ipv6_ipam_pool_id" {
  description = "(Optional) IPAM Pool ID for a IPv6 pool. Conflicts with `assign_generated_ipv6_cidr_block`"
  type        = string
  default     = null
}

variable "ipv6_netmask_length" {
  description = "(Optional) Netmask length to request from IPAM Pool. Conflicts with `ipv6_cidr_block`. This can be omitted if IPAM pool as a `allocation_default_netmask_length` set. Valid values: `56`"
  type        = number
  default     = null
}

variable "ipv6_cidr_block_network_border_group" {
  description = "By default when an IPv6 CIDR is assigned to a VPC a default ipv6_cidr_block_network_border_group will be set to the region of the VPC. This can be changed to restrict advertisement of public addresses to specific Network Border Groups such as LocalZones"
  type        = string
  default     = null
}

variable "config_vpc" {
  type = object({
    cidr = list(string)
    subnets = optional(map(object({
      address_prefixes    = list(string)
      address_prefixes_v6 = optional(list(string), [])
    })), {})
    # nsg_id                       = optional(string)
    # dns_servers                  = optional(list(string))
    # bgp_community                = optional(string, null)
    # ddos_protection_plan_id      = optional(string, null)
    # encryption_enabled           = optional(bool, false)
    # encryption_enforcement       = optional(string, "AllowUnencrypted") # DropUnencrypted, AllowUnencrypted
    # enable_private_dns_resolver  = optional(bool, false)
    # enable_ars                   = optional(bool, false)
    # enable_express_route_gateway = optional(bool, false)
    # nat_gateway_subnet_names     = optional(list(string), [])
    # subnet_names_private_dns     = optional(list(string), [])

    # enable_vnet_flow_logs           = optional(bool, false)
    # enable_vnet_flow_logs_analytics = optional(bool, true)

    # private_dns_inbound_subnet_name  = optional(string, null)
    # private_dns_outbound_subnet_name = optional(string, null)
    # ruleset_dns_forwarding_rules     = optional(map(any), {})

    # vpn_gateway_ip_config0_apipa_addresses = optional(list(string), ["169.254.21.1"])
    # vpn_gateway_ip_config1_apipa_addresses = optional(list(string), ["169.254.21.5"])
  })
}


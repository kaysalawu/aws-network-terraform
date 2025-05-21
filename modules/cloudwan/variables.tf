
variable "global_network_name" {
  description = "The name of the global network"
  type        = string
}

variable "base_policy_regions" {
  description = "The regions to be used for the base policy"
  type        = list(string)
  default     = ["eu-central-1", "eu-west-1"]
}

variable "edge_locations" {
  description = "List of core network edge locations"
  type = list(object({
    location           = string
    asn                = number
    inside_cidr_blocks = list(string)
  }))
}

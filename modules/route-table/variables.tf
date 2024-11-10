
variable "prefix" {
  description = "A short prefix to identify the resource"
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to all resources"
  type        = map(any)
  default     = {}
}

variable "region" {
  description = "The region where the route table will be created"
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet IDs to associate with the route table"
  type        = list(string)
}

variable "route_table_id" {
  description = "The ID of the route table"
  type        = string
  default     = null
}

variable "routes" {
  description = "A list of route objects"
  type = list(object({
    name                   = string
    address_prefix         = list(string)
    next_hop_type          = string
    next_hop_in_ip_address = optional(string, null)
    delay_creation         = optional(string, "0s")
  }))
  default = []
}

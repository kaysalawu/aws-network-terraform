
variable "create" {
  description = "Controls if resources should be created (affects nearly all resources)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "Identifier of the VPC where the security group will be created"
  type        = string
  default     = null
}

variable "create_security_group" {
  description = "Determines if a security group is created"
  type        = bool
  default     = true
}

variable "route53_records" {
  description = "Map of Route53 records to create. Each record map should contain `zone_id`, `name`, and `type`"
  type        = any
  default     = {}
}

################################################################################
# Load Balancer
################################################################################

variable "access_logs" {
  description = "Map containing access logging configuration for load balancer"
  type = object({
    bucket  = optional(string, "")  # S3 bucket name to store the logs in
    enabled = optional(bool, false) # Enable / disable access_logs
    prefix  = optional(string, "")  # S3 bucket prefix
  })
  default = {}
}

variable "connection_logs" {
  description = "Map containing access logging configuration for load balancer"
  type = object({
    bucket  = optional(string, "")  # S3 bucket name to store the logs in
    enabled = optional(bool, false) # Enable / disable access_logs
    prefix  = optional(string, "")  # S3 bucket prefix
  })
  default = {}
}

variable "client_keep_alive" {
  description = "Client keep alive value in seconds. The valid range is 60-604800 seconds. The default is 3600 seconds."
  type        = number
  default     = null
}

variable "customer_owned_ipv4_pool" {
  description = "The ID of the customer owned ipv4 pool to use for this load balancer"
  type        = string
  default     = null
}

variable "desync_mitigation_mode" {
  description = "Determines how the load balancer handles requests that might pose a security risk to an application due to HTTP desync. Valid values are `monitor`, `defensive` (default), `strictest`"
  type        = string
  default     = null
}

variable "dns_record_client_routing_policy" {
  description = "Indicates how traffic is distributed among the load balancer Availability Zones. Possible values are any_availability_zone (default), availability_zone_affinity, or partial_availability_zone_affinity. Only valid for network type load balancers."
  type        = string
  default     = null
}

variable "drop_invalid_header_fields" {
  description = "Indicates whether HTTP headers with header fields that are not valid are removed by the load balancer (`true`) or routed to targets (`false`). The default is `true`. Elastic Load Balancing requires that message header names contain only alphanumeric characters and hyphens. Only valid for Load Balancers of type `application`"
  type        = bool
  default     = true
}

variable "enable_cross_zone_load_balancing" {
  description = "If `true`, cross-zone load balancing of the load balancer will be enabled. For application load balancer this feature is always enabled (`true`) and cannot be disabled. Defaults to `true`"
  type        = bool
  default     = true
}

variable "enable_deletion_protection" {
  description = "If `true`, deletion of the load balancer will be disabled via the AWS API. This will prevent Terraform from deleting the load balancer. Defaults to `true`"
  type        = bool
  default     = false
}

variable "enable_http2" {
  description = "Indicates whether HTTP/2 is enabled in application load balancers. Defaults to `true`"
  type        = bool
  default     = true
}

variable "enable_tls_version_and_cipher_suite_headers" {
  description = "Indicates whether the two headers (`x-amzn-tls-version` and `x-amzn-tls-cipher-suite`), which contain information about the negotiated TLS version and cipher suite, are added to the client request before sending it to the target. Only valid for Load Balancers of type `application`. Defaults to `false`"
  type        = bool
  default     = null
}

variable "enable_waf_fail_open" {
  description = "Indicates whether to allow a WAF-enabled load balancer to route requests to targets if it is unable to forward the request to AWS WAF. Defaults to `false`"
  type        = bool
  default     = null
}

variable "enable_xff_client_port" {
  description = "Indicates whether the X-Forwarded-For header should preserve the source port that the client used to connect to the load balancer in `application` load balancers. Defaults to `false`"
  type        = bool
  default     = null
}

variable "enable_zonal_shift" {
  description = "Whether zonal shift is enabled"
  type        = bool
  default     = null
}

variable "enforce_security_group_inbound_rules_on_private_link_traffic" {
  description = "Indicates whether inbound security group rules are enforced for traffic originating from a PrivateLink. Only valid for Load Balancers of type network. The possible values are on and off."
  type        = string
  default     = null
}

variable "idle_timeout" {
  description = "The time in seconds that the connection is allowed to be idle. Only valid for Load Balancers of type `application`. Default: `60`"
  type        = number
  default     = null
}

variable "internal" {
  description = "If true, the LB will be internal. Defaults to `false`"
  type        = bool
  default     = null
}

variable "ip_address_type" {
  description = "The type of IP addresses used by the subnets for your load balancer. The possible values are `ipv4` and `dualstack`"
  type        = string
  default     = null
}

variable "load_balancer_type" {
  description = "The type of load balancer to create. Possible values are `application`, `gateway`, or `network`. The default value is `application`"
  type        = string
  default     = "network"
}

variable "name" {
  description = "The name of the LB. This name must be unique within your AWS account, can have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, and must not begin or end with a hyphen"
  type        = string
  default     = null
}

variable "name_prefix" {
  description = "Creates a unique name beginning with the specified prefix. Conflicts with `name`"
  type        = string
  default     = null
}

variable "security_groups" {
  description = "A list of security group IDs to assign to the LB"
  type        = list(string)
  default     = []
}

variable "preserve_host_header" {
  description = "Indicates whether the Application Load Balancer should preserve the Host header in the HTTP request and send it to the target without any change. Defaults to `false`"
  type        = bool
  default     = true
}

variable "subnet_mapping" {
  description = "A list of subnet mapping blocks describing subnets to attach to load balancer"
  type = list(object({
    subnet_id            = string
    allocation_id        = optional(string, null)
    ipv6_address         = optional(string, null)
    private_ipv4_address = optional(string, null)
  }))
  default = []
}

variable "subnets" {
  description = "A list of subnet IDs to attach to the LB. Subnets cannot be updated for Load Balancers of type `network`. Changing this value for load balancers of type `network` will force a recreation of the resource"
  type        = list(string)
  default     = null
}

variable "xff_header_processing_mode" {
  description = "Determines how the load balancer modifies the X-Forwarded-For header in the HTTP request before sending the request to the target. The possible values are `append`, `preserve`, and `remove`. Only valid for Load Balancers of type `application`. The default is `append`"
  type        = string
  default     = null
}

variable "timeouts" {
  description = "Create, update, and delete timeout configurations for the load balancer"
  type        = map(string)
  default     = {}
}

################################################################################
# Listener(s)
################################################################################

variable "listeners" {
  description = "List of listener configurations"
  type = list(object({
    name                     = string
    alpn_policy              = optional(string, null)
    certificate_arn          = optional(string, null)
    port                     = optional(number, null)
    protocol                 = optional(string, null)
    ssl_policy               = optional(string, null)
    tcp_idle_timeout_seconds = optional(number, 60)

    authenticate_cognito = optional(object({
      default                             = optional(bool, false)
      user_pool_arn                       = optional(string, null)
      user_pool_client_id                 = optional(string, null)
      user_pool_domain                    = optional(string, null)
      authentication_request_extra_params = optional(map(string), null)
      on_unauthenticated_request          = optional(string, null)
      scope                               = optional(string, null)
      session_cookie_name                 = optional(string, null)
      session_timeout                     = optional(number, null)
    }), {})

    authenticate_oidc = optional(object({
      default                             = optional(bool, false)
      authorization_endpoint              = optional(string, null)
      client_id                           = optional(string, null)
      client_secret                       = optional(string, null)
      issuer                              = optional(string, null)
      token_endpoint                      = optional(string, null)
      user_info_endpoint                  = optional(string, null)
      authentication_request_extra_params = optional(map(string), null)
      on_unauthenticated_request          = optional(string, null)
      scope                               = optional(string, null)
      session_cookie_name                 = optional(string, null)
      session_timeout                     = optional(number, null)
    }), {})

    forward = optional(object({
      default      = optional(bool, false)
      order        = optional(number, null)
      target_group = optional(string, null)
      stickiness = optional(object({
        duration = optional(number, null)
        enabled  = optional(bool, null)
        type     = optional(string, null)
      }), {})
    }), {})

    fixed_response = optional(object({
      default      = optional(bool, false)
      content_type = optional(string, null)
      message_body = optional(string, null)
      status_code  = optional(string, null)
    }), {})

    mutual_authentication = optional(list(object({
      mode                             = string # off, verify, passthrough
      trust_store_arn                  = string
      ignore_client_certificate_expiry = optional(bool, false)
    })), [])
  }))
  default = []
}

################################################################################
# Target Group
################################################################################

variable "target_groups" {
  description = "Map of target group configurations to create"
  type = list(object({
    name                               = string
    name_prefix                        = optional(string, null)
    connection_termination             = optional(bool, null)
    deregistration_delay               = optional(number, null)
    lambda_multi_value_headers_enabled = optional(bool, null)
    load_balancing_algorithm_type      = optional(string, null)
    load_balancing_anomaly_mitigation  = optional(string, null)
    load_balancing_cross_zone_enabled  = optional(bool, true)
    port                               = optional(number, null)
    preserve_client_ip                 = optional(bool, false)
    protocol_version                   = optional(string, null)
    protocol                           = optional(string, null)
    proxy_protocol_v2                  = optional(bool, false)
    slow_start                         = optional(number, null)
    target_id                          = optional(string, null)
    ip_address_type                    = optional(string, "ipv4")
    vpc_id                             = optional(string, null)

    target = optional(object({
      type              = optional(string, "instance")
      id                = optional(string, null)
      port              = optional(number, null)
      availability_zone = optional(string, null)
    }), {})

    health_check = optional(object({
      enabled             = optional(bool, true)
      interval            = optional(number, 30)
      matcher             = optional(string, null)
      path                = optional(string, null)
      port                = optional(string, "traffic-port") # traffic-port, 1-65535
      protocol            = optional(string, null)           # TCP, HTTP, HTTPS
      timeout             = optional(number, null)
      healthy_threshold   = optional(number, 3) # 2-10
      unhealthy_threshold = optional(number, 3) # 2-10
    }), {})

    stickiness = optional(object({
      cookie_duration = optional(number, null)
      cookie_name     = optional(string, null)
      enabled         = optional(bool, null)
      type            = optional(string, null)
    }), {})

    target_failover = optional(object({
      on_deregistration = optional(string, "no_rebalance") # `rebalance`, `no_rebalance`
      on_unhealthy      = optional(string, "no_rebalance") # `rebalance`, `no_rebalance`
    }), {})

    target_health_state = optional(object({
      enable_unhealthy_connection_termination = optional(bool, true)
      unhealthy_draining_interval             = optional(number, 0) # 0-360000
    }), {})

    target_group_health = optional(object({
      dns_failover = optional(object({
        minimum_healthy_targets_count      = optional(number, 1)    # off, 1-max_number_of_targets
        minimum_healthy_targets_percentage = optional(string, null) # off, 1-100
      }), {})
      unhealthy_state_routing = optional(object({
        minimum_healthy_targets_count      = optional(number, 1)    # off, 1-max_number_of_targets
        minimum_healthy_targets_percentage = optional(string, null) # off, 1-100
      }), {})
    }), {})
  }))
  default = []
}

variable "additional_target_group_attachments" {
  description = "Map of additional target group attachments to create. Use `target_group_key` to attach to the target group created in `target_groups`"
  type        = any
  default     = {}
}

################################################################################
# WAF
################################################################################

variable "associate_web_acl" {
  description = "Indicates whether a Web Application Firewall (WAF) ACL should be associated with the load balancer"
  type        = bool
  default     = false
}

variable "web_acl_arn" {
  description = "Web Application Firewall (WAF) ARN of the resource to associate with the load balancer"
  type        = string
  default     = null
}

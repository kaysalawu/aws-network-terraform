
data "aws_networkmanager_core_network_policy_document" "this" {
  core_network_configuration {
    vpn_ecmp_support   = true
    asn_ranges         = ["65400-65534"]
    inside_cidr_blocks = ["192.168.192.0/18"]

    dynamic "edge_locations" {
      for_each = var.edge_locations
      content {
        location           = edge_locations.value.location
        asn                = edge_locations.value.asn
        inside_cidr_blocks = edge_locations.value.inside_cidr_blocks
      }
    }
  }

  segments {
    name                          = "production"
    description                   = "Segment for production workloads"
    require_attachment_acceptance = true
    allow_filter                  = []
  }

  segments {
    name                          = "staging"
    description                   = "Segment for staging workloads"
    require_attachment_acceptance = true
    allow_filter                  = []
  }

  segments {
    name                          = "sandbox"
    description                   = "Segment for sandbox workloads"
    require_attachment_acceptance = true
    allow_filter                  = []
  }

  segments {
    name                          = "vpn"
    description                   = "Segment for VPN connectivity"
    require_attachment_acceptance = true
    allow_filter = [
      "production",
      "finance",
      "sandbox",
      "sharedservice",
      "staging",
    ]
  }

  segments {
    name                          = "sharedservice"
    description                   = "Segment for sharedservice workloads"
    require_attachment_acceptance = true
    allow_filter = [
      "production",
      "sandbox",
      "staging",
      "finance"
    ]
  }

  segments {
    name                          = "ut"
    description                   = "UT infra"
    require_attachment_acceptance = true
  }

  segment_actions {
    action  = "share"
    mode    = "attachment-route"
    segment = "production"
    share_with = [
      "sharedservice",
      "vpn"
    ]
  }

  segment_actions {
    action  = "share"
    mode    = "attachment-route"
    segment = "staging"
    share_with = [
      "sharedservice",
      "vpn"
    ]
  }

  segment_actions {
    action  = "share"
    mode    = "attachment-route"
    segment = "sandbox"
    share_with = [
      "sharedservice",
      "vpn"
    ]
  }

  attachment_policies {
    rule_number     = 100
    condition_logic = "or"

    conditions {
      type     = "tag-value"
      operator = "equals"
      key      = "segment"
      value    = "production"
    }
    action {
      association_method = "constant"
      segment            = "production"
    }
  }

  attachment_policies {
    rule_number     = 200
    condition_logic = "or"

    conditions {
      type     = "tag-value"
      operator = "equals"
      key      = "segment"
      value    = "sharedservice"
    }
    action {
      association_method = "constant"
      segment            = "sharedservice"
    }
  }

  attachment_policies {
    rule_number     = 300
    condition_logic = "or"

    conditions {
      type     = "tag-value"
      operator = "equals"
      key      = "segment"
      value    = "staging"
    }
    action {
      association_method = "constant"
      segment            = "staging"
    }
  }

  attachment_policies {
    rule_number     = 400
    condition_logic = "or"

    conditions {
      type     = "tag-value"
      operator = "equals"
      key      = "segment"
      value    = "sandbox"
    }
    action {
      association_method = "constant"
      segment            = "sandbox"
    }
  }
}

data "aws_networkmanager_core_network_policy_document" "this" {
  core_network_configuration {
    vpn_ecmp_support   = true
    asn_ranges         = ["65400-65534"]
    inside_cidr_blocks = ["192.168.192.0/18"]

    edge_locations {
      location           = "eu-central-1"
      asn                = 65400
      inside_cidr_blocks = ["192.168.192.0/24"]
    }

    edge_locations {
      location           = "eu-west-1"
      asn                = 65401
      inside_cidr_blocks = ["192.168.193.0/24"]
    }

    edge_locations {
      location           = "ap-south-1"
      asn                = 65402
      inside_cidr_blocks = ["192.168.194.0/24"]
    }

    edge_locations {
      location           = "me-central-1"
      asn                = 65403
      inside_cidr_blocks = ["192.168.195.0/24"]
    }

    edge_locations {
      location           = "ap-southeast-5"
      asn                = 65404
      inside_cidr_blocks = ["192.168.196.0/24"]
    }

    edge_locations {
      location           = "eu-west-3"
      asn                = 65405
      inside_cidr_blocks = ["192.168.197.0/24"]
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
    name                          = "regional"
    description                   = "Regional Integrations"
    require_attachment_acceptance = true
  }

  segments {
    name                          = "ut"
    description                   = "UT infra"
    require_attachment_acceptance = true
  }

  segments {
    name                          = "finance"
    description                   = "Finance infra"
    require_attachment_acceptance = true
    allow_filter                  = []
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
      key      = "wise:net:segment"
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
      key      = "wise:net:segment"
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
      key      = "wise:net:segment"
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
      key      = "wise:net:segment"
      value    = "sandbox"
    }
    action {
      association_method = "constant"
      segment            = "sandbox"
    }
  }
}

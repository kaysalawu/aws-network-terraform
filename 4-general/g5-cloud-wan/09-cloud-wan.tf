
module "cloud_wan" {
  source              = "../../modules/cloudwan"
  global_network_name = "${local.tgw1_prefix}cwan"
  base_policy_regions = [local.region1, local.region2, ]

  edge_locations = [
    { inside_cidr_blocks = ["192.168.192.0/24"], asn = 65400, location = "eu-central-1" },
    # { inside_cidr_blocks = ["192.168.193.0/24"], asn = 65401, location = "eu-west-1" },
    # { inside_cidr_blocks = ["192.168.194.0/24"], asn = 65402, location = "ap-south-1" },
    # { inside_cidr_blocks = ["192.168.195.0/24"], asn = 65403, location = "me-central-1" },
    # { inside_cidr_blocks = ["192.168.196.0/24"], asn = 65404, location = "ap-southeast-5" },
    { inside_cidr_blocks = ["192.168.197.0/24"], asn = 65405, location = "eu-west-3" }
  ]
}

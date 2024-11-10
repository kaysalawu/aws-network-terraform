
data "aws_caller_identity" "current" {}

module "tgw1" {
  source          = "../../modules/transit-gateway"
  name            = "${local.tgw1_prefix}tgw"
  description     = "tgw for ${local.region1} attachments"
  amazon_side_asn = local.tgw1_bgp_asn
  tags            = local.tgw1_tags

  transit_gateway_cidr_blocks = local.tgw1_address_prefixes

  ram_allow_external_principals = true
  # ram_principals                = [data.aws_caller_identity.current.account_id]

  auto_accept_shared_attachments  = "enable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  route_tables = [
    { name = "hub" },
    { name = "vpc" },
    { name = "vpn" },
  ]

  transit_gateway_routes = [
    # { route_table_name = "vpc", name = "internet", attachment_name = module.hub1.vpc_name, ipv4_prefixes = ["0.0.0.0/0"] },
    # { route_table_name = "hub", name = "spoke1", attachment_name = module.spoke1.vpc_name, ipv4_prefixes = local.spoke1_cidr },
    # { route_table_name = "hub", name = "spoke2", attachment_name = module.spoke2.vpc_name, ipv4_prefixes = local.spoke2_cidr },
  ]

  vpc_attachments = [
    # {
    #   name        = module.hub1.vpc_name
    #   route_table = "hub"
    #   subnet_ids  = [module.hub1.private_subnet_ids["ManagementSubnet"], ]
    #   vpc_id      = module.hub1.vpc_id
    #   vpc_routes = [
    #     { name = "private-internal", ipv4_prefixes = local.private_prefixes_ipv4, route_table_id = module.hub1.private_route_table_id },
    #     { name = "public-internal", ipv4_prefixes = local.private_prefixes_ipv4, route_table_id = module.hub1.public_route_table_id },
    #   ]
    # },
    # {
    #   name        = module.spoke1.vpc_name
    #   route_table = "vpc"
    #   subnet_ids  = [module.spoke1.private_subnet_ids["ManagementSubnet"], ]
    #   vpc_id      = module.spoke1.vpc_id
    #   vpc_routes = [
    #     { name = "default", ipv4_prefixes = ["0.0.0.0/0"], route_table_id = module.spoke1.private_route_table_id },
    #   ]
    # },
    # {
    #   name        = module.spoke2.vpc_name
    #   route_table = "vpc"
    #   subnet_ids  = [module.spoke2.private_subnet_ids["ManagementSubnet"], ]
    #   vpc_id      = module.spoke2.vpc_id
    #   vpc_routes = [
    #     { name = "default", ipv4_prefixes = ["0.0.0.0/0"], route_table_id = module.spoke2.private_route_table_id },
    #   ]
    # }
  ]
}

resource "time_sleep" "tgw1" {
  create_duration = "90s"
  depends_on = [
    module.tgw1
  ]
}

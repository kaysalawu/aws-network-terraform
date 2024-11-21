
module "tgw1" {
  source          = "../../modules/transit-gateway"
  providers       = { aws = aws.region1 }
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
  ]

  vpc_attachments = [
    {
      name       = module.hub1.vpc_name
      vpc_id     = module.hub1.vpc_id
      subnet_ids = [module.hub1.subnet_ids["ManagementSubnetA"], ]
      vpc_routes = [
        { name = "private-internal", ipv4_prefixes = local.private_prefixes_ipv4, route_table_id = module.hub1.route_table_ids["private"] },
        { name = "public-internal", ipv4_prefixes = local.private_prefixes_ipv4, route_table_id = module.hub1.route_table_ids["public"] },
      ]
      associated_route_table_name  = "hub"
      propagated_route_table_names = ["vpc"]
    },
    {
      name       = module.spoke1.vpc_name
      vpc_id     = module.spoke1.vpc_id
      subnet_ids = [module.spoke1.subnet_ids["ManagementSubnetA"], ]
      vpc_routes = [
        { name = "default", ipv4_prefixes = ["0.0.0.0/0"], route_table_id = module.spoke1.route_table_ids["private"] },
      ]
      associated_route_table_name  = "vpc"
      propagated_route_table_names = ["hub"]
    },
    {
      name       = module.spoke2.vpc_name
      vpc_id     = module.spoke2.vpc_id
      subnet_ids = [module.spoke2.subnet_ids["ManagementSubnetA"], ]
      vpc_routes = [
        { name = "default", ipv4_prefixes = ["0.0.0.0/0"], route_table_id = module.spoke2.route_table_ids["private"] },
      ]
      associated_route_table_name  = "vpc"
      propagated_route_table_names = ["hub"]
    }
  ]

  transit_gateway_routes = [
    { name = "internet", route_table_name = "vpc", attachment_name = module.hub1.vpc_name, ipv4_prefixes = ["0.0.0.0/0"] },
    # { name = "spoke1", route_table_name = "hub", attachment_name = module.spoke1.vpc_name, ipv4_prefixes = local.spoke1_cidr },
    # { name = "spoke2", route_table_name = "hub", attachment_name = module.spoke2.vpc_name, ipv4_prefixes = local.spoke2_cidr },
  ]
}

resource "time_sleep" "tgw1" {
  create_duration = "90s"
  depends_on = [
    module.tgw1
  ]
}

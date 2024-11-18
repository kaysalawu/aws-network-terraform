
module "tgw2" {
  source          = "../../modules/transit-gateway"
  providers       = { aws = aws.region2 }
  name            = "${local.tgw2_prefix}tgw"
  description     = "tgw for ${local.region2} attachments"
  amazon_side_asn = local.tgw2_bgp_asn
  tags            = local.tgw2_tags

  transit_gateway_cidr_blocks = local.tgw2_address_prefixes

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
      name       = module.hub2.vpc_name
      vpc_id     = module.hub2.vpc_id
      subnet_ids = [module.hub2.subnet_ids["ManagementSubnet"], ]
      vpc_routes = [
        { name = "private-internal", ipv4_prefixes = local.private_prefixes_ipv4, route_table_id = module.hub2.route_table_ids["private"] },
        { name = "public-internal", ipv4_prefixes = local.private_prefixes_ipv4, route_table_id = module.hub2.route_table_ids["public"] },
      ]
      associated_route_table_name  = "hub"
      propagated_route_table_names = ["vpc"]
    },
    {
      name       = module.spoke4.vpc_name
      vpc_id     = module.spoke4.vpc_id
      subnet_ids = [module.spoke4.subnet_ids["ManagementSubnet"], ]
      vpc_routes = [
        { name = "default", ipv4_prefixes = ["0.0.0.0/0"], route_table_id = module.spoke4.route_table_ids["private"] },
      ]
      associated_route_table_name  = "vpc"
      propagated_route_table_names = ["hub"]
    },
    {
      name       = module.spoke5.vpc_name
      vpc_id     = module.spoke5.vpc_id
      subnet_ids = [module.spoke5.subnet_ids["ManagementSubnet"], ]
      vpc_routes = [
        { name = "default", ipv4_prefixes = ["0.0.0.0/0"], route_table_id = module.spoke5.route_table_ids["private"] },
      ]
      associated_route_table_name  = "vpc"
      propagated_route_table_names = ["hub"]
    }
  ]

  transit_gateway_routes = [
    { name = "internet", route_table_name = "vpc", attachment_name = module.hub2.vpc_name, ipv4_prefixes = ["0.0.0.0/0"] },
    # { name = "spoke4", route_table_name = "hub", attachment_name = module.spoke4.vpc_name, ipv4_prefixes = local.spoke4_cidr },
    # { name = "spoke5", route_table_name = "hub", attachment_name = module.spoke5.vpc_name, ipv4_prefixes = local.spoke5_cidr },
  ]
}

resource "time_sleep" "tgw2" {
  create_duration = "90s"
  depends_on = [
    module.tgw2
  ]
}


data "aws_caller_identity" "current" {}

module "tgw1" {
  source          = "terraform-aws-modules/transit-gateway/aws"
  name            = "${local.tgw1_prefix}tgw"
  description     = "TGW: ${local.tgw1_prefix}"
  amazon_side_asn = local.tgw1_bgp_asn

  transit_gateway_cidr_blocks = local.tgw1_address_prefixes

  enable_auto_accept_shared_attachments = true
  enable_multicast_support              = false

  vpc_attachments = {
    (module.hub1.vpc_name) = {
      vpc_id      = module.hub1.vpc_id
      subnet_ids  = [module.hub1.private_subnet_ids["ManagementSubnet"], ]
      dns_support = true
      # ipv6_support = true
      # transit_gateway_default_route_table_association = false
      # transit_gateway_default_route_table_propagation = false
      tgw_routes = [
        { destination_cidr_block = "30.0.0.0/16" },
        { destination_cidr_block = "0.0.0.0/0", blackhole = true }
      ]
      tags = { Name = "hub1" }
    },
    (module.spoke1.vpc_name) = {
      vpc_id     = module.spoke1.vpc_id
      subnet_ids = [module.spoke1.private_subnet_ids["ManagementSubnet"], ]

      tgw_routes = [
        { destination_cidr_block = "50.0.0.0/16" },
        { destination_cidr_block = "10.10.10.10/32", blackhole = true }
      ]
      tags = { Name = "spoke1" }
    },
  }

  ram_allow_external_principals = true

  # ram_principals = [data.aws_caller_identity.current.account_id]
  tags = local.tgw1_tags
}

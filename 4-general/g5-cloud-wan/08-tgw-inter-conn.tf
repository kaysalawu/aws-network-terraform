

####################################################
# vpc hubs
####################################################

# private zone associations
#---------------------------------------

locals {
  private_zone_vpc_associations_region1 = [
    { vpc_id = module.hub1.vpc_id, zone_id = aws_route53_zone.region2.zone_id },
    { vpc_id = module.spoke1.vpc_id, zone_id = aws_route53_zone.region2.zone_id },
    { vpc_id = module.spoke2.vpc_id, zone_id = aws_route53_zone.region2.zone_id },
    { vpc_id = module.spoke3.vpc_id, zone_id = aws_route53_zone.region2.zone_id },
  ]

  private_zone_vpc_associations_region2 = [
    { vpc_id = module.hub2.vpc_id, zone_id = aws_route53_zone.region1.zone_id },
    { vpc_id = module.spoke4.vpc_id, zone_id = aws_route53_zone.region1.zone_id },
    { vpc_id = module.spoke5.vpc_id, zone_id = aws_route53_zone.region1.zone_id },
    { vpc_id = module.spoke6.vpc_id, zone_id = aws_route53_zone.region1.zone_id },
  ]
}

resource "aws_route53_zone_association" "private_zone_vpc_associations_region1" {
  count    = length(local.private_zone_vpc_associations_region1)
  provider = aws.region1
  zone_id  = local.private_zone_vpc_associations_region1[count.index].zone_id
  vpc_id   = local.private_zone_vpc_associations_region1[count.index].vpc_id
}

resource "aws_route53_zone_association" "private_zone_vpc_associations_region2" {
  count    = length(local.private_zone_vpc_associations_region2)
  provider = aws.region2
  zone_id  = local.private_zone_vpc_associations_region2[count.index].zone_id
  vpc_id   = local.private_zone_vpc_associations_region2[count.index].vpc_id
}

####################################################
# transit gateway
####################################################

resource "time_sleep" "wait_for_tgws" {
  create_duration = "60s"
  depends_on = [
    module.tgw1,
    module.tgw2,
  ]
}

# peering
#---------------------------------------

# tgw1

resource "aws_ec2_transit_gateway_peering_attachment" "tgw1_tgw2_peering" {
  provider                = aws.region1
  peer_account_id         = module.tgw2.owner_id
  peer_region             = local.region2
  peer_transit_gateway_id = module.tgw2.id
  transit_gateway_id      = module.tgw1.id

  tags = {
    Name = "tgw1-requester"
    Side = "requester"
  }
  depends_on = [
    time_sleep.wait_for_tgws,
  ]
}

resource "aws_ec2_transit_gateway_route_table_association" "tgw1_tgw2_association" {
  provider                       = aws.region1
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.tgw1_tgw2_peering.id
  transit_gateway_route_table_id = module.tgw1.route_table_ids["hub"]

  depends_on = [
    aws_ec2_transit_gateway_peering_attachment.tgw1_tgw2_peering,
  ]
}

# tgw2

resource "aws_ec2_transit_gateway_peering_attachment_accepter" "tgw2_tgw1_peering" {
  provider                      = aws.region2
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.tgw1_tgw2_peering.id

  tags = {
    Name = "tgw2-accepter"
    Side = "accepter"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "tgw2_tgw1_association" {
  provider                       = aws.region2
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment_accepter.tgw2_tgw1_peering.id
  transit_gateway_route_table_id = module.tgw2.route_table_ids["hub"]

  depends_on = [
    aws_ec2_transit_gateway_peering_attachment_accepter.tgw2_tgw1_peering,
  ]
}

# routes
#---------------------------------------

# tgw1

module "tgw1_routes" {
  source          = "../../modules/transit-gateway"
  providers       = { aws = aws.region1 }
  name            = "${local.tgw1_prefix}tgw"
  description     = "tgw1 routes"
  amazon_side_asn = local.tgw1_bgp_asn
  tags            = local.tgw1_tags

  create_tgw         = false
  transit_gateway_id = module.tgw1.id

  transit_gateway_routes = [
    {
      name           = "vpc-to-region2"
      route_table_id = module.tgw1.route_table_ids["vpc"]
      attachment_id  = aws_ec2_transit_gateway_peering_attachment.tgw1_tgw2_peering.id
      ipv4_prefixes  = concat(local.hub2_cidr, local.spoke4_cidr, local.spoke5_cidr, local.branch3_cidr, )
    },
    {
      name           = "hub-to-region2"
      route_table_id = module.tgw1.route_table_ids["hub"]
      attachment_id  = aws_ec2_transit_gateway_peering_attachment.tgw1_tgw2_peering.id
      ipv4_prefixes  = concat(local.hub2_cidr, local.spoke4_cidr, local.spoke5_cidr, local.branch3_cidr, )
    },
  ]
  depends_on = [
    time_sleep.wait_for_tgws,
  ]
}

# tgw2

module "tgw2_routes" {
  source          = "../../modules/transit-gateway"
  providers       = { aws = aws.region2 }
  name            = "${local.tgw2_prefix}tgw"
  description     = "tgw2 routes"
  amazon_side_asn = local.tgw2_bgp_asn
  tags            = local.tgw2_tags

  create_tgw         = false
  transit_gateway_id = module.tgw2.id

  transit_gateway_routes = [
    {
      name           = "vpc-to-region1"
      route_table_id = module.tgw2.route_table_ids["vpc"]
      attachment_id  = aws_ec2_transit_gateway_peering_attachment_accepter.tgw2_tgw1_peering.id
      ipv4_prefixes  = concat(local.hub1_cidr, local.spoke1_cidr, local.spoke2_cidr, local.branch1_cidr, )
    },
    {
      name           = "hub-to-region1"
      route_table_id = module.tgw2.route_table_ids["hub"]
      attachment_id  = aws_ec2_transit_gateway_peering_attachment_accepter.tgw2_tgw1_peering.id
      ipv4_prefixes  = concat(local.hub1_cidr, local.spoke1_cidr, local.spoke2_cidr, local.branch1_cidr, )
    },
  ]
  depends_on = [
    time_sleep.wait_for_tgws,
  ]
}

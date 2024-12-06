
####################################################
# vpc peering
####################################################

resource "aws_vpc_peering_connection" "hub1_to_spoke1" {
  provider    = aws.region1
  vpc_id      = module.hub1.vpc_id
  peer_vpc_id = module.spoke1.vpc_id
  peer_region = local.spoke1_region
  tags        = local.hub1_tags

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_vpc_peering_connection_accepter" "hub1_to_spoke1" {
  provider                  = aws.region1
  vpc_peering_connection_id = aws_vpc_peering_connection.hub1_to_spoke1.id
  auto_accept               = true
  tags                      = local.spoke1_tags

  lifecycle {
    ignore_changes = [tags]
  }
}

####################################################
# routes
####################################################

# hub1

resource "aws_route" "hub1_to_spoke1_private" {
  provider                  = aws.region1
  route_table_id            = module.hub1.route_table_ids["private"]
  destination_cidr_block    = local.spoke1_cidr.0
  vpc_peering_connection_id = aws_vpc_peering_connection.hub1_to_spoke1.id
}

resource "aws_route" "hub1_to_spoke1_public" {
  provider                  = aws.region1
  route_table_id            = module.hub1.route_table_ids["public"]
  destination_cidr_block    = local.spoke1_cidr.0
  vpc_peering_connection_id = aws_vpc_peering_connection.hub1_to_spoke1.id
}

# spoke1

resource "aws_route" "spoke1_to_hub1_private" {
  provider                  = aws.region1
  route_table_id            = module.spoke1.route_table_ids["private"]
  destination_cidr_block    = local.hub1_cidr.0
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.hub1_to_spoke1.id
}

resource "aws_route" "spoke1_to_hub1_public" {
  provider                  = aws.region1
  route_table_id            = module.spoke1.route_table_ids["public"]
  destination_cidr_block    = local.hub1_cidr.0
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.hub1_to_spoke1.id
}

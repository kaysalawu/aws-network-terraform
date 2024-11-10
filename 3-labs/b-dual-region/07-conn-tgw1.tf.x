
####################################################
# spoke1
####################################################

# routes

# resource "aws_route" "spoke1_routes_private_ipv4" {
#   for_each               = toset(local.private_prefixes_ipv4)
#   route_table_id         = module.spoke1.private_route_table_id
#   destination_cidr_block = each.key
#   transit_gateway_id     = module.tgw1.ec2_transit_gateway_id
# }

####################################################
# spoke2
####################################################

# routes

# resource "aws_route" "spoke2_routes_private_ipv4" {
#   for_each               = toset(local.private_prefixes_ipv4)
#   route_table_id         = module.spoke2.private_route_table_id
#   destination_cidr_block = each.key
#   transit_gateway_id     = module.tgw1.ec2_transit_gateway_id
# }

####################################################
# hub1
####################################################

# routes

# resource "aws_route" "hub1_routes_private" {
#   for_each               = toset(local.private_prefixes_ipv4)
#   route_table_id         = module.hub1.private_route_table_id
#   destination_cidr_block = each.key
#   transit_gateway_id     = module.tgw1.ec2_transit_gateway_id
# }

####################################################
# branch1
####################################################

# customer gateway

resource "aws_customer_gateway" "branch1_cgw" {
  bgp_asn    = local.branch1_nva_asn
  ip_address = aws_eip.branch1_nva.public_ip
  type       = "ipsec.1"
  tags = {
    Name = "${local.branch1_prefix}cgw"
  }
}

# vpn connection

resource "aws_vpn_connection" "branch1_vpn_conn" {
  transit_gateway_id    = module.tgw1.ec2_transit_gateway_id
  customer_gateway_id   = aws_customer_gateway.branch1_cgw.id
  type                  = aws_customer_gateway.branch1_cgw.type
  tunnel1_preshared_key = local.psk
  tunnel2_preshared_key = local.psk
  tags = {
    Name = "${local.branch1_prefix}vpn-conn"
  }
}

####################################################
# branch1
####################################################

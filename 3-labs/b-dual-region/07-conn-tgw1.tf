
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

resource "aws_ec2_transit_gateway_route_table_association" "branch1_vpn_conn" {
  transit_gateway_attachment_id  = aws_vpn_connection.branch1_vpn_conn.transit_gateway_attachment_id
  transit_gateway_route_table_id = module.tgw1.ec2_transit_gateway_route_table_ids["hub"]
}

resource "aws_ec2_transit_gateway_route_table_propagation" "branch1_vpn_conn" {
  transit_gateway_attachment_id  = aws_vpn_connection.branch1_vpn_conn.transit_gateway_attachment_id
  transit_gateway_route_table_id = module.tgw1.ec2_transit_gateway_route_table_ids["hub"]
}

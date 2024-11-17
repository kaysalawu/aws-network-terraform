
locals {
  tgw2_branch3_vpn_tun1_addr        = aws_vpn_connection.branch3_vpn_conn.tunnel1_address
  tgw2_branch3_vpn_tun2_addr        = aws_vpn_connection.branch3_vpn_conn.tunnel2_address
  tgw2_branch3_vpn_tun1_inside_addr = aws_vpn_connection.branch3_vpn_conn.tunnel1_cgw_inside_address
  tgw2_branch3_vpn_tun2_inside_addr = aws_vpn_connection.branch3_vpn_conn.tunnel2_cgw_inside_address
  tgw2_branch3_vpn_tun1_inside_cidr = aws_vpn_connection.branch3_vpn_conn.tunnel1_inside_cidr
  tgw2_branch3_vpn_tun2_inside_cidr = aws_vpn_connection.branch3_vpn_conn.tunnel2_inside_cidr
  tgw2_vpn_tun1_inside_addr         = cidrhost(local.tgw2_branch3_vpn_tun1_inside_cidr, 1)
  tgw2_vpn_tun2_inside_addr         = cidrhost(local.tgw2_branch3_vpn_tun2_inside_cidr, 1)
}

####################################################
# branch
####################################################

# customer gateway

resource "aws_customer_gateway" "branch3_cgw" {
  provider   = aws.region2
  bgp_asn    = local.branch3_nva_asn
  ip_address = aws_eip.branch3_nva_untrust.public_ip
  type       = "ipsec.1"
  tags = {
    Name = "${local.branch3_prefix}cgw"
  }
}

# tunnels

locals {
  branch3_nva_route_map_onprem    = "ONPREM"
  branch3_nva_route_map_aws       = "AWS"
  branch3_nva_route_map_block_aws = "BLOCK_AWS_PREFIXES"
  branch3_nva_vars = {
    LOCAL_ASN = local.branch3_nva_asn
    LOOPBACK0 = local.branch3_nva_loopback0
    LOOPBACKS = []

    PREFIX_LISTS = [
      "ip prefix-list ${local.branch3_nva_route_map_block_aws} deny 1.2.3.4/32",
      "ip prefix-list ${local.branch3_nva_route_map_block_aws} permit 0.0.0.0/0 le 32",
    ]
    ROUTE_MAPS = [
      # do nothing (placeholder for future use)
      "route-map ${local.branch3_nva_route_map_aws} permit 110",
      "match ip address prefix-list all",
    ]
    STATIC_ROUTES = [
      { prefix = "0.0.0.0/0", next_hop = local.branch3_untrust_default_gw },
      { prefix = "${local.tgw2_branch3_vpn_tun1_inside_addr}/32", next_hop = "tun1" },
      { prefix = "${local.tgw2_branch3_vpn_tun2_inside_addr}/32", next_hop = "tun2" },
      { prefix = local.branch3_subnets["MainSubnet"].cidr, next_hop = local.branch3_untrust_default_gw },
    ]
    TUNNELS = [
      {
        name            = "tun1"
        vti_local_addr  = local.tgw2_branch3_vpn_tun1_inside_addr
        vti_remote_addr = local.tgw2_vpn_tun1_inside_addr
        local_ip        = local.branch3_nva_untrust_addr
        local_id        = aws_eip.branch3_nva_untrust.public_ip
        remote_ip       = local.tgw2_branch3_vpn_tun1_addr
        remote_id       = local.tgw2_branch3_vpn_tun1_addr
        psk             = local.psk
      },
      {
        name            = "tun2"
        vti_local_addr  = local.tgw2_branch3_vpn_tun2_inside_addr
        vti_remote_addr = local.tgw2_vpn_tun2_inside_addr
        local_ip        = local.branch3_nva_untrust_addr
        local_id        = aws_eip.branch3_nva_untrust.public_ip
        remote_ip       = local.tgw2_branch3_vpn_tun2_addr
        remote_id       = local.tgw2_branch3_vpn_tun2_addr
        psk             = local.psk
      },
    ]
    BGP_SESSIONS_IPV4 = [
      {
        peer_asn        = local.tgw2_bgp_asn
        peer_ip         = local.tgw2_vpn_tun1_inside_addr
        ebgp_multihop   = { enable = false, ttl = 2 }
        source_loopback = false
        route_maps      = []
      },
      {
        peer_asn        = local.tgw2_bgp_asn
        peer_ip         = local.tgw2_vpn_tun2_inside_addr
        ebgp_multihop   = { enable = false, ttl = 2 }
        source_loopback = false
        route_maps      = []
      },
    ]
    BGP_ADVERTISED_PREFIXES_IPV4 = [
      local.branch3_subnets["MainSubnet"].cidr,
    ]
  }
  branch3_nva_init = templatefile("../../scripts/linux-nva.sh", merge(local.branch3_nva_vars, {
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = []
    TARGETS_HEAVY_TRAFFIC_GEN = []
    USERNAME                  = local.username
    PASSWORD                  = local.password

    IPTABLES_RULES           = []
    FRR_CONF                 = templatefile("../../scripts/frr/frr.conf", merge(local.branch3_nva_vars, {}))
    STRONGSWAN_VTI_SCRIPT    = templatefile("../../scripts/strongswan/ipsec-vti.sh", local.branch3_nva_vars)
    STRONGSWAN_IPSEC_SECRETS = templatefile("../../scripts/strongswan/ipsec.secrets", local.branch3_nva_vars)
    STRONGSWAN_IPSEC_CONF    = templatefile("../../scripts/strongswan/ipsec.conf", local.branch3_nva_vars)
    STRONGSWAN_AUTO_RESTART  = templatefile("../../scripts/strongswan/ipsec-auto-restart.sh", local.branch3_nva_vars)
  }))
}

# nva

module "branch3_nva" {
  source               = "../../modules/ec2"
  providers            = { aws = aws.region2 }
  name                 = "${local.branch3_prefix}nva"
  availability_zone    = "${local.branch3_region}a"
  iam_instance_profile = module.common_region2.iam_instance_profile.name
  ami                  = data.aws_ami.ubuntu_region2.id
  key_name             = module.common_region2.key_pair_name
  user_data            = base64encode(local.branch3_nva_init)
  tags                 = local.branch3_tags

  interfaces = [
    {
      name               = "${local.branch3_prefix}nva-untrust"
      subnet_id          = module.branch3.subnet_ids["UntrustSubnet"]
      private_ips        = [local.branch3_nva_untrust_addr, ]
      security_group_ids = [module.branch3.nva_security_group_id, ]
      eip_tag_name       = "${local.branch3_prefix}nva-untrust"
      source_dest_check  = false
    },
    {
      name               = "${local.branch3_prefix}nva-trust"
      subnet_id          = module.branch3.subnet_ids["TrustSubnet"]
      private_ips        = [local.branch3_nva_trust_addr, ]
      security_group_ids = [module.branch3.ec2_security_group_id, ]
      source_dest_check  = false
    }
  ]
}

# dns

resource "aws_route53_record" "branch3_nva" {
  provider = aws.region2
  zone_id  = data.aws_route53_zone.public.zone_id
  name     = "branch3-nva.${local.region2_code}"
  type     = "A"
  ttl      = 300
  records = [
    aws_eip.branch3_nva_untrust.public_ip,
  ]
  lifecycle {
    ignore_changes = [
      zone_id,
    ]
  }
}

# static routes

resource "aws_route" "branch3_routes" {
  for_each               = toset(local.private_prefixes_ipv4)
  provider               = aws.region2
  route_table_id         = module.branch3.route_table_ids["private"]
  destination_cidr_block = each.value
  network_interface_id   = module.branch3_nva.interface_ids["${local.branch3_prefix}nva-untrust"]
}

####################################################
# tgw2
####################################################

# connection

resource "aws_vpn_connection" "branch3_vpn_conn" {
  provider              = aws.region2
  transit_gateway_id    = module.tgw2.id
  customer_gateway_id   = aws_customer_gateway.branch3_cgw.id
  type                  = aws_customer_gateway.branch3_cgw.type
  tunnel1_preshared_key = local.psk
  tunnel2_preshared_key = local.psk
  tags = {
    Name = "${local.branch3_prefix}vpn-conn"
  }
}

# association

resource "aws_ec2_transit_gateway_route_table_association" "branch3_vpn_conn" {
  provider                       = aws.region2
  transit_gateway_attachment_id  = aws_vpn_connection.branch3_vpn_conn.transit_gateway_attachment_id
  transit_gateway_route_table_id = module.tgw2.route_table_ids["hub"]
}

# propagation

resource "aws_ec2_transit_gateway_route_table_propagation" "branch3_vpn_conn" {
  provider                       = aws.region2
  transit_gateway_attachment_id  = aws_vpn_connection.branch3_vpn_conn.transit_gateway_attachment_id
  transit_gateway_route_table_id = module.tgw2.route_table_ids["hub"]
}

####################################################
# output files
####################################################

locals {
  conn_tgw2_files = {
    "output/branch3-nva.sh" = local.branch3_nva_init
  }
}

resource "local_file" "conn_tgw2_files" {
  for_each = local.conn_tgw2_files
  filename = each.key
  content  = each.value
}

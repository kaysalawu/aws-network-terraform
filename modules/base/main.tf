
locals {
  prefix = var.prefix == "" ? "" : format("%s-", var.prefix)
  private_prefixes = [
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16",
    "100.64.0.0/10",
  ]
  private_prefixes_v6 = [
    "2000::/3",
    "fd00::/8",
  ]
  public_subnets    = { for k, v in var.subnets : k => v if v.type == "public" }
  private_subnets   = { for k, v in var.subnets : k => v if v.type == "private" }
  public_subnets_a  = { for k, v in local.public_subnets : k => v if v.az == "a" }
  public_subnets_b  = { for k, v in local.public_subnets : k => v if v.az == "b" }
  public_subnets_c  = { for k, v in local.public_subnets : k => v if v.az == "c" }
  private_subnets_a = { for k, v in local.private_subnets : k => v if v.az == "a" }
  private_subnets_b = { for k, v in local.private_subnets : k => v if v.az == "b" }
  private_subnets_c = { for k, v in local.private_subnets : k => v if v.az == "c" }
}

####################################################
# vpc
####################################################

# ipam

resource "aws_vpc_ipam_pool_cidr" "ipv4" {
  count        = var.use_ipv4_ipam_pool ? 1 : 0
  ipam_pool_id = var.ipv4_ipam_pool_id
  cidr         = var.cidr.0
}

resource "aws_vpc_ipam_pool_cidr" "ipv6" {
  count        = var.enable_ipv6 && var.use_ipv6_ipam_pool ? 1 : 0
  ipam_pool_id = var.ipv6_ipam_pool_id
  cidr         = var.ipv6_cidr.0
}

# vpc

resource "aws_vpc" "this" {
  cidr_block          = var.use_ipv4_ipam_pool ? null : var.cidr.0
  ipv4_ipam_pool_id   = var.use_ipv4_ipam_pool ? var.ipv4_ipam_pool_id : null
  ipv4_netmask_length = var.use_ipv4_ipam_pool ? var.ipv4_netmask_length : null

  assign_generated_ipv6_cidr_block     = var.enable_ipv6 && !var.use_ipv6_ipam_pool ? true : null
  ipv6_cidr_block                      = var.enable_ipv6 && var.use_ipv6_ipam_pool ? var.ipv6_cidr.0 : null
  ipv6_ipam_pool_id                    = var.enable_ipv6 && var.use_ipv6_ipam_pool ? var.ipv6_ipam_pool_id : null
  ipv6_netmask_length                  = var.enable_ipv6 && var.use_ipv6_ipam_pool ? var.ipv6_netmask_length : null
  ipv6_cidr_block_network_border_group = var.enable_ipv6 && !var.use_ipv6_ipam_pool ? var.region : null

  instance_tenancy                     = var.instance_tenancy
  enable_dns_hostnames                 = var.enable_dns_hostnames
  enable_dns_support                   = var.enable_dns_support
  enable_network_address_usage_metrics = var.enable_network_address_usage_metrics

  tags = merge(var.tags,
    { Name = "${local.prefix}vpc" }
  )
  depends_on = [
    aws_vpc_ipam_pool_cidr.ipv4,
    aws_vpc_ipam_pool_cidr.ipv6,
  ]
}

# additional cidr blocks

resource "aws_vpc_ipv4_cidr_block_association" "this" {
  count      = length(var.cidr) > 1 ? length(var.cidr) - 1 : 0
  vpc_id     = aws_vpc.this.id
  cidr_block = var.cidr[count.index + 1]
}

# dhcp options

resource "aws_vpc_dhcp_options" "this" {
  count               = var.dhcp_options.enable ? 1 : 0
  domain_name         = var.dhcp_options.domain_name
  domain_name_servers = var.dhcp_options.domain_name_servers
  ntp_servers         = var.dhcp_options.ntp_servers

  tags = {
    Name = "${local.prefix}dhcp-options"
  }
}

resource "aws_vpc_dhcp_options_association" "this" {
  count           = var.dhcp_options.enable ? 1 : 0
  vpc_id          = aws_vpc.this.id
  dhcp_options_id = aws_vpc_dhcp_options.this[count.index].id
}

####################################################
# subnets
####################################################

# public

resource "aws_subnet" "public" {
  for_each          = { for k, v in var.subnets : k => v if v.type == "public" }
  availability_zone = "${var.region}${each.value.az}"
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr

  ipv6_cidr_block = (
    var.enable_ipv6 ?
    cidrsubnet(aws_vpc.this.ipv6_cidr_block, each.value.ipv6_newbits, each.value.ipv6_netnum) :
    null
  )
  map_public_ip_on_launch = each.value.map_public_ip_on_launch

  tags = merge(var.tags,
    {
      Name  = each.key
      Scope = "public"
    }
  )
}

resource "aws_subnet" "private" {
  for_each          = { for k, v in var.subnets : k => v if v.type == "private" }
  availability_zone = "${var.region}${each.value.az}"
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr

  ipv6_cidr_block = (
    var.enable_ipv6 ?
    cidrsubnet(aws_vpc.this.ipv6_cidr_block, each.value.ipv6_newbits, each.value.ipv6_netnum) :
    null
  )

  tags = merge(var.tags,
    {
      Name  = each.key
      Scope = "private"
    }
  )
}

####################################################
# security group
####################################################

# TODO: use prefix lists for private prefixes

# bastion
#--------------------------

# security group

resource "aws_security_group" "bastion_sg" {
  name   = "${local.prefix}bastion-sg"
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags,
    {
      Name  = "${local.prefix}bastion-sg"
      Scope = "public"
    }
  )
}

# ssh ingress

resource "aws_security_group_rule" "bastion_ssh_ingress" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.bastion_sg.id
}

# icmp ingress

resource "aws_security_group_rule" "bastion_icmp_ingress" {
  type              = "ingress"
  from_port         = 8
  to_port           = 0
  protocol          = "icmp"
  cidr_blocks       = local.private_prefixes
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.bastion_sg.id
}

# traceroute ingress

resource "aws_security_group_rule" "bastion_traceroute_ingress" {
  type              = "ingress"
  from_port         = 33434
  to_port           = 33534
  protocol          = "udp"
  cidr_blocks       = local.private_prefixes
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.bastion_sg.id
}

# all egress

resource "aws_security_group_rule" "bastion_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.bastion_sg.id
}

# ec2
#--------------------------

resource "aws_security_group" "ec2_sg" {
  name   = "${local.prefix}ec2-sg"
  vpc_id = aws_vpc.this.id

  tags = {
    Name  = "${local.prefix}ec2-sg"
    Scope = "private"
  }
}

# icmp & traceroute ingress

resource "aws_security_group_rule" "ec2_prv_icmp_ingress" {
  type              = "ingress"
  from_port         = 8
  to_port           = 0
  protocol          = "icmp"
  cidr_blocks       = local.private_prefixes
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.ec2_sg.id
}

resource "aws_security_group_rule" "ec2_prv_traceroute_ingress" {
  type              = "ingress"
  from_port         = 33434
  to_port           = 33534
  protocol          = "udp"
  cidr_blocks       = local.private_prefixes
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.ec2_sg.id
}

# bastion ingress

resource "aws_security_group_rule" "ec2_prv_bastion_ingress" {
  type                     = "ingress"
  from_port                = "0"
  to_port                  = "0"
  protocol                 = "-1"
  source_security_group_id = aws_security_group.bastion_sg.id
  security_group_id        = aws_security_group.ec2_sg.id
}

# dns ingress (for bind server)

resource "aws_security_group_rule" "ec2_prv_tcp_dns_ingress" {
  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = "tcp"
  cidr_blocks       = local.private_prefixes
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.ec2_sg.id
}

resource "aws_security_group_rule" "ec2_prv_udp_dns_ingress" {
  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  cidr_blocks       = local.private_prefixes
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.ec2_sg.id
}

# egress

resource "aws_security_group_rule" "ec2_prv_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.ec2_sg.id
}

# nva
#--------------------------

# security group

resource "aws_security_group" "nva_sg" {
  name   = "${local.prefix}nva-sg"
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags,
    {
      Name  = "${local.prefix}nva-sg"
      Scope = "public"
    }
  )
}

# ssh ingress

resource "aws_security_group_rule" "nva_ssh_ingress" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.nva_sg.id
}

# bastion ingress

resource "aws_security_group_rule" "bastion_ingress" {
  type                     = "ingress"
  from_port                = "0"
  to_port                  = "0"
  protocol                 = "-1"
  source_security_group_id = aws_security_group.bastion_sg.id
  security_group_id        = aws_security_group.nva_sg.id
}

# ike ingress

resource "aws_security_group_rule" "nva_udp_500_ingress" {
  type              = "ingress"
  from_port         = 500
  to_port           = 500
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.nva_sg.id
}

# nat-t ingress

resource "aws_security_group_rule" "nva_udp_4500_ingress" {
  type              = "ingress"
  from_port         = 4500
  to_port           = 4500
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.nva_sg.id
}

# nva ingress

resource "aws_security_group_rule" "nva_ingress" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.nva_sg.id
  security_group_id        = aws_security_group.nva_sg.id
}

# ec2 ingress

resource "aws_security_group_rule" "vpc_ec2_ingress" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.ec2_sg.id
  security_group_id        = aws_security_group.nva_sg.id
}

# egress

resource "aws_security_group_rule" "nva_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.nva_sg.id
}

####################################################
# route tables
####################################################

# default
#--------------------------

# public

resource "aws_route_table" "public_route_table" {
  count  = length(local.public_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.this.id
  tags = merge(var.tags,
    {
      Name  = "${local.prefix}rtb/public/${local.public_subnets[keys(local.public_subnets)[0]].az}"
      Scope = "public"
    }
  )
}

resource "aws_route_table_association" "public_route_table" {
  for_each       = local.public_subnets
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public_route_table[0].id
}

# private

resource "aws_route_table" "private_route_table" {
  count  = length(local.private_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.this.id
  tags = merge(var.tags,
    {
      Name  = "${local.prefix}rtb/private/${local.private_subnets[keys(local.private_subnets)[0]].az}"
      Scope = "private"
    }
  )
}

resource "aws_route_table_association" "private_route_table" {
  for_each       = local.private_subnets
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private_route_table[0].id
}

# custom
#--------------------------

# TODO: add custom route tables per subnet if subnet config custom_rt = true


####################################################
# internet gateway
####################################################

# gateway

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = merge(var.tags,
    {
      Name = "${local.prefix}igw"
    }
  )
}

# routes
#--------------------------

# ipv4

resource "aws_route" "public_internet_route_a" {
  count                  = length(local.public_subnets_a) > 0 ? 1 : 0
  route_table_id         = aws_route_table.public_route_table[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route" "public_internet_route_b" {
  count                  = length(local.public_subnets_b) > 0 ? 1 : 0
  route_table_id         = aws_route_table.public_route_table[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route" "public_internet_route_c" {
  count                  = length(local.public_subnets_c) > 0 ? 1 : 0
  route_table_id         = aws_route_table.public_route_table[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

# ipv6

resource "aws_route" "public_internet_route_a_ipv6" {
  count                       = length(local.public_subnets_a) > 0 ? 1 : 0
  route_table_id              = aws_route_table.public_route_table[0].id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.this.id
}

resource "aws_route" "public_internet_route_b_ipv6" {
  count                       = length(local.public_subnets_b) > 0 ? 1 : 0
  route_table_id              = aws_route_table.public_route_table[0].id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.this.id
}

resource "aws_route" "public_internet_route_c_ipv6" {
  count                       = length(local.public_subnets_c) > 0 ? 1 : 0
  route_table_id              = aws_route_table.public_route_table[0].id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.this.id
}

####################################################
# nat gateways
####################################################

# nat gateways ips
#--------------------------

resource "aws_eip" "eip_natgw_a" {
  count  = length(local.public_subnets_a) > 0 && var.create_nat_gateway ? 1 : 0
  domain = "vpc"
  tags = merge(var.tags,
    {
      Name = "${local.prefix}eip-natgw-a"
    }
  )
}

resource "aws_eip" "eip_natgw_b" {
  count  = length(local.public_subnets_b) > 0 && var.create_nat_gateway ? 1 : 0
  domain = "vpc"
  tags = merge(var.tags,
    {
      Name = "${local.prefix}eip-natgw-b"
    }
  )
}

resource "aws_eip" "eip_natgw_c" {
  count  = length(local.public_subnets_c) > 0 && var.create_nat_gateway ? 1 : 0
  domain = "vpc"
  tags = merge(var.tags,
    {
      Name = "${local.prefix}eip-natgw-c"
    }
  )
}

# nat gateways
#--------------------------

resource "aws_nat_gateway" "natgw_a" {
  count         = length(local.public_subnets_a) > 0 && var.create_nat_gateway ? 1 : 0
  allocation_id = aws_eip.eip_natgw_a[0].id
  subnet_id     = aws_subnet.public[keys(local.public_subnets_a)[0]].id
  tags = merge(var.tags,
    {
      Name  = "${local.prefix}natgw-a"
      Scope = "public"
    }
  )
  depends_on = [aws_internet_gateway.this, ]
}

resource "aws_nat_gateway" "natgw_b" {
  count         = length(local.public_subnets_b) > 0 && var.create_nat_gateway ? 1 : 0
  allocation_id = aws_eip.eip_natgw_b[0].id
  subnet_id     = aws_subnet.public[keys(local.public_subnets_b)[0]].id
  tags = merge(var.tags,
    {
      Name  = "${local.prefix}natgw-b"
      Scope = "public"
    }
  )
  depends_on = [aws_internet_gateway.this, ]
}

resource "aws_nat_gateway" "natgw_c" {
  count         = length(local.public_subnets_c) > 0 && var.create_nat_gateway ? 1 : 0
  allocation_id = aws_eip.eip_natgw_c[0].id
  subnet_id     = aws_subnet.public[keys(local.public_subnets_c)[0]].id
  tags = merge(var.tags,
    {
      Name  = "${local.prefix}natgw-c"
      Scope = "public"
    }
  )
  depends_on = [aws_internet_gateway.this, ]
}

# routes
#--------------------------

resource "aws_route" "private_internet_route_a" {
  count                  = length(local.private_subnets_a) > 0 && var.create_nat_gateway ? 1 : 0
  route_table_id         = aws_route_table.private_route_table[0].id
  nat_gateway_id         = aws_nat_gateway.natgw_a[0].id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "private_internet_route_b" {
  count                  = length(local.private_subnets_b) > 0 && var.create_nat_gateway ? 1 : 0
  route_table_id         = aws_route_table.private_route_table[0].id
  nat_gateway_id         = aws_nat_gateway.natgw_b[0].id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "private_internet_route_c" {
  count                  = length(local.private_subnets_c) > 0 && var.create_nat_gateway ? 1 : 0
  route_table_id         = aws_route_table.private_route_table[0].id
  nat_gateway_id         = aws_nat_gateway.natgw_c[0].id
  destination_cidr_block = "0.0.0.0/0"
}

####################################################
# private dns
####################################################

# dns zone

resource "aws_route53_zone" "private" {
  count = var.private_dns_config.create_zone && var.private_dns_config.zone_name != null ? 1 : 0
  name  = var.private_dns_config.zone_name
  vpc {
    vpc_id = aws_vpc.this.id
  }
  dynamic "vpc" {
    for_each = { for vpc_id in var.private_dns_config.vpc_associations : vpc_id => vpc_id if var.private_dns_config.create_zone && var.private_dns_config.zone_name != null }
    content {
      vpc_id = vpc.value
    }
  }
}

# dns namespace

# resource "aws_service_discovery_private_dns_namespace" "this" {
#   count       = var.private_dns_config.enable_service_discovery ? 1 : 0
#   name        = var.private_dns_config.zone_name
#   description = "Private DNS namespace for ${var.private_dns_config.zone_name}"
#   vpc         = aws_vpc.this.id
# }

# # dns service

# resource "aws_service_discovery_service" "dns" {
#   name = "dns"

#   dns_config {
#     namespace_id = aws_service_discovery_private_dns_namespace.this[0].id

#     dns_records {
#       ttl  = 10
#       type = "A"
#     }

#     routing_policy = "MULTIVALUE"
#   }

#   health_check_custom_config {
#     failure_threshold = 1
#   }
# }

####################################################
# bastion
####################################################

# server
#--------------------------

locals {
  bastion_startup = templatefile("${path.module}/scripts/bastion.sh", {})
}

module "bastion" {
  count                = var.bastion_config.enable ? 1 : 0
  source               = "../ec2"
  name                 = "${local.prefix}bastion"
  availability_zone    = "${var.region}a"
  iam_instance_profile = var.bastion_config.iam_instance_profile
  ami                  = data.aws_ami.ubuntu.id
  key_name             = var.bastion_config.key_name
  user_data            = base64encode(local.bastion_startup)

  tags = merge(var.tags,
    {
      Name  = "${local.prefix}bastion"
      Scope = "public"
    }
  )

  interfaces = [
    {
      name               = "${local.prefix}bastion-untrust"
      subnet_id          = aws_subnet.public["UntrustSubnet"].id
      private_ips        = var.bastion_config.private_ips
      security_group_ids = [aws_security_group.bastion_sg.id, ]
      create_public_ip   = true
    }
  ]
}

# dns zone record
#--------------------------

# public

resource "aws_route53_record" "bastion_public" {
  count   = var.bastion_config.enable && var.bastion_config.public_dns_zone_name != null ? 1 : 0
  zone_id = data.aws_route53_zone.public.0.zone_id
  name = (var.bastion_config.dns_prefix != null ?
    "${var.bastion_config.dns_prefix}.${data.aws_route53_zone.public.0.name}" :
    "${local.prefix}bastion.${data.aws_route53_zone.public.0.name}"
  )
  type    = "A"
  ttl     = "300"
  records = [module.bastion[0].public_ips["${local.prefix}bastion-untrust"], ]
}

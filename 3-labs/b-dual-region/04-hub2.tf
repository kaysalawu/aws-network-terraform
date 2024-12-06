
####################################################
# base
####################################################

# network

module "hub2" {
  source    = "../../modules/base"
  providers = { aws = aws.region2 }
  prefix    = trimsuffix(local.hub2_prefix, "-")
  region    = local.hub2_region
  tags      = local.hub2_tags

  cidr               = local.hub2_cidr
  use_ipv4_ipam_pool = false
  ipv4_ipam_pool_id  = module.common_region2.ipv4_ipam_pool_id

  # enable_ipv6        = local.enable_ipv6
  # ipv6_cidr          = local.hub2_ipv6_cidr
  # use_ipv6_ipam_pool = false
  # ipv6_ipam_pool_id  = module.common_region2.ipv6_ipam_pool_id

  subnets = local.hub2_subnets

  dns_resolver_config = [{
    inbound = [
      { subnet = "DnsInboundSubnetA", ip = local.hub2_dns_in_addr1 },
      { subnet = "DnsInboundSubnetB", ip = local.hub2_dns_in_addr2 }
    ]
    outbound = [
      { subnet = "DnsOutboundSubnetA", ip = local.hub2_dns_out_addr1 },
      { subnet = "DnsOutboundSubnetB", ip = local.hub2_dns_out_addr2 }
    ]
    rules = local.hub2_features.dns_forwarding_rules

    additional_associated_vpc_ids = [
      module.spoke4.vpc_id,
      module.spoke5.vpc_id,
      module.spoke6.vpc_id,
    ]
  }]

  nat_config = [
    { scope = "public", subnet = "UntrustSubnetA", },
  ]

  route_table_config = [
    {
      scope   = "private"
      subnets = [for k, v in local.hub2_subnets : k if v.scope == "private"]
      routes = [
        { ipv4_cidr = "0.0.0.0/0", nat_gateway = true, nat_gateway_subnet = "UntrustSubnetA" },
      ]
    },
    {
      scope   = "public"
      subnets = [for k, v in local.hub2_subnets : k if v.scope == "public"]
      routes = [
        { ipv4_cidr = "0.0.0.0/0", internet_gateway = true },
        { ipv6_cidr = "::/0", internet_gateway = true },
      ]
    },
  ]

  bastion_config = {
    enable               = true
    key_name             = module.common_region2.key_pair_name
    private_ips          = [local.hub2_bastion_addr]
    iam_instance_profile = module.common_region2.iam_instance_profile.name
    public_dns_zone_name = local.domain_name
    dns_prefix           = "bastion.hub2.${local.region2_code}"
  }

  depends_on = [
    module.common_region2,
  ]
}

# private dns

resource "aws_route53_zone" "region2" {
  provider = aws.region2
  name     = local.region2_dns_zone
  vpc {
    vpc_id = module.hub2.vpc_id
  }
  lifecycle {
    ignore_changes = [vpc, ]
  }
}

resource "time_sleep" "hub2" {
  create_duration = "90s"
  depends_on = [
    module.hub2,
    aws_route53_zone.region2,
  ]
}

####################################################
# workload
####################################################

module "hub2_vm" {
  source               = "../../modules/ec2"
  providers            = { aws = aws.region2 }
  name                 = "${local.hub2_prefix}vm"
  availability_zone    = "${local.hub2_region}a"
  iam_instance_profile = module.common_region2.iam_instance_profile.name
  ami                  = data.aws_ami.ubuntu_region2.id
  key_name             = module.common_region2.key_pair_name
  user_data            = base64encode(module.vm_cloud_init.cloud_config)
  tags                 = local.hub2_tags

  interfaces = [
    {
      name               = "${local.hub2_prefix}vm-main"
      subnet_id          = module.hub2.subnet_ids["MainSubnetA"]
      private_ips        = [local.hub2_vm_addr, ]
      security_group_ids = [module.hub2.ec2_sg_id, ]
      dns_config         = { zone_name = local.region2_dns_zone, name = local.hub2_vm_hostname }
    }
  ]
  depends_on = [
    time_sleep.hub2,
  ]
}

####################################################
# output files
####################################################

locals {
  hub2_files = {
  }
}

resource "local_file" "hub2_files" {
  for_each = local.hub2_files
  filename = each.key
  content  = each.value
}

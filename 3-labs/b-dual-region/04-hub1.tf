
####################################################
# base
####################################################

# network

module "hub1" {
  source    = "../../modules/base"
  providers = { aws = aws.region1 }
  prefix    = trimsuffix(local.hub1_prefix, "-")
  region    = local.hub1_region
  tags      = local.hub1_tags

  cidr               = local.hub1_cidr
  use_ipv4_ipam_pool = false
  ipv4_ipam_pool_id  = module.common_region1.ipv4_ipam_pool_id

  # enable_ipv6        = local.enable_ipv6
  # ipv6_cidr          = local.hub1_ipv6_cidr
  # use_ipv6_ipam_pool = false
  # ipv6_ipam_pool_id  = module.common_region1.ipv6_ipam_pool_id

  subnets = local.hub1_subnets

  dns_resolver_config = [{
    inbound = [
      { subnet = "DnsInboundSubnetA", ip = local.hub1_dns_in_addr1 },
      { subnet = "DnsInboundSubnetB", ip = local.hub1_dns_in_addr2 }
    ]
    outbound = [
      { subnet = "DnsOutboundSubnetA", ip = local.hub1_dns_out_addr1 },
      { subnet = "DnsOutboundSubnetB", ip = local.hub1_dns_out_addr2 }
    ]
    rules = [
      {
        domain = local.onprem_domain
        target_ips = [
          local.branch1_dns_addr,
          local.branch3_dns_addr,
        ]
      },
    ]
    additional_associated_vpc_ids = [
      module.spoke1.vpc_id,
      module.spoke2.vpc_id,
      module.spoke3.vpc_id,
    ]
  }]

  nat_config = [
    { scope = "public", subnet = "UntrustSubnetA", },
  ]

  route_table_config = [
    {
      scope   = "private"
      subnets = [for k, v in local.hub1_subnets : k if v.scope == "private"]
      routes = [
        { ipv4_cidr = "0.0.0.0/0", nat_gateway = true, nat_gateway_subnet = "UntrustSubnetA" },
      ]
    },
    {
      scope   = "public"
      subnets = [for k, v in local.hub1_subnets : k if v.scope == "public"]
      routes = [
        { ipv4_cidr = "0.0.0.0/0", internet_gateway = true },
        { ipv6_cidr = "::/0", internet_gateway = true },
      ]
    },
  ]

  bastion_config = {
    enable               = true
    key_name             = module.common_region1.key_pair_name
    private_ips          = [local.hub1_bastion_addr, ]
    iam_instance_profile = module.common_region1.iam_instance_profile.name
    public_dns_zone_name = local.domain_name
    dns_prefix           = "bastion.hub1.${local.region1_code}"
  }

  depends_on = [
    module.common_region1,
  ]
}

# private dns

resource "aws_route53_zone" "region1" {
  provider = aws.region1
  name     = local.region1_dns_zone
  vpc {
    vpc_id = module.hub1.vpc_id
  }
  lifecycle {
    ignore_changes = [vpc, ]
  }
}

resource "time_sleep" "hub1" {
  create_duration = "90s"
  depends_on = [
    module.hub1,
    aws_route53_zone.region1,
  ]
}

####################################################
# workload
####################################################

module "hub1_vm" {
  source               = "../../modules/ec2"
  providers            = { aws = aws.region1 }
  name                 = "${local.hub1_prefix}vm"
  availability_zone    = "${local.hub1_region}a"
  iam_instance_profile = module.common_region1.iam_instance_profile.name
  ami                  = data.aws_ami.ubuntu_region1.id
  key_name             = module.common_region1.key_pair_name
  user_data            = base64encode(module.vm_cloud_init.cloud_config)
  tags                 = local.hub1_tags

  interfaces = [
    {
      name               = "${local.hub1_prefix}vm-main"
      subnet_id          = module.hub1.subnet_ids["MainSubnetA"]
      private_ips        = [local.hub1_vm_addr, ]
      security_group_ids = [module.hub1.ec2_sg_id, ]
      dns_config         = { zone_name = local.region1_dns_zone, name = local.hub1_vm_hostname }
    }
  ]
  depends_on = [
    time_sleep.hub1,
  ]
}

####################################################
# output files
####################################################

locals {
  hub1_files = {
  }
}

resource "local_file" "hub1_files" {
  for_each = local.hub1_files
  filename = each.key
  content  = each.value
}


####################################################
# spoke4
####################################################

# base

module "spoke4" {
  source    = "../../modules/base"
  providers = { aws = aws.region2 }
  prefix    = trimsuffix(local.spoke4_prefix, "-")
  region    = local.spoke4_region
  tags      = local.spoke4_tags

  cidr               = local.spoke4_cidr
  use_ipv4_ipam_pool = false
  ipv4_ipam_pool_id  = module.common_region2.ipv4_ipam_pool_id

  # enable_ipv6        = local.enable_ipv6
  # ipv6_cidr          = local.spoke4_ipv6_cidr
  # use_ipv6_ipam_pool = false
  # ipv6_ipam_pool_id  = module.common_region2.ipv6_ipam_pool_id

  subnets = local.spoke4_subnets

  private_dns_config = {
    zone_name = aws_route53_zone.region2.name
  }

  route_table_config = [
    { scope = "private", subnets = [for k, v in local.spoke4_subnets : k if v.scope == "private"] },
    {
      scope   = "public"
      subnets = [for k, v in local.spoke4_subnets : k if v.scope == "public"]
      routes = [
        { ipv4_cidr = "0.0.0.0/0", internet_gateway = true },
        { ipv6_cidr = "::/0", internet_gateway = true },
      ]
    },
  ]

  depends_on = [
    module.common_region2,
  ]
}

resource "time_sleep" "spoke4" {
  create_duration = "60s"
  depends_on = [
    module.spoke4,
    module.tgw2,
  ]
}

# workload

module "spoke4_vm" {
  source               = "../../modules/ec2"
  providers            = { aws = aws.region2 }
  name                 = "${local.spoke4_prefix}vm"
  availability_zone    = "${local.spoke4_region}a"
  iam_instance_profile = module.common_region2.iam_instance_profile.name
  ami                  = data.aws_ami.ubuntu_region2.id
  key_name             = module.common_region2.key_pair_name
  user_data            = base64encode(module.vm_cloud_init.cloud_config)
  tags                 = local.spoke4_tags

  interfaces = [
    {
      name               = "${local.spoke4_prefix}vm-main"
      subnet_id          = module.spoke4.subnet_ids["MainSubnetA"]
      private_ips        = [local.spoke4_vm_addr, ]
      security_group_ids = [module.spoke4.ec2_security_group_id, ]
      dns_config         = { zone_name = local.region2_dns_zone, name = local.spoke4_vm_hostname }
    }
  ]
  depends_on = [
    time_sleep.spoke4,
  ]
}

####################################################
# spoke5
####################################################

# base

module "spoke5" {
  source    = "../../modules/base"
  providers = { aws = aws.region2 }
  prefix    = trimsuffix(local.spoke5_prefix, "-")
  region    = local.spoke5_region
  tags      = local.spoke5_tags

  cidr               = local.spoke5_cidr
  use_ipv4_ipam_pool = false
  ipv4_ipam_pool_id  = module.common_region2.ipv4_ipam_pool_id

  # enable_ipv6        = local.enable_ipv6
  # ipv6_cidr          = local.spoke5_ipv6_cidr
  # use_ipv6_ipam_pool = false
  # ipv6_ipam_pool_id  = module.common_region2.ipv6_ipam_pool_id

  subnets = local.spoke5_subnets

  private_dns_config = {
    zone_name = aws_route53_zone.region2.name
  }

  route_table_config = [
    { scope = "private", subnets = [for k, v in local.spoke5_subnets : k if v.scope == "private"] },
    {
      scope   = "public"
      subnets = [for k, v in local.spoke5_subnets : k if v.scope == "public"]
      routes = [
        { ipv4_cidr = "0.0.0.0/0", internet_gateway = true },
        { ipv6_cidr = "::/0", internet_gateway = true },
      ]
    },
  ]

  depends_on = [
    module.common_region2,
  ]
}

resource "time_sleep" "spoke5" {
  create_duration = "60s"
  depends_on = [
    module.spoke5,
    module.tgw2,
  ]
}

# workload

module "spoke5_vm" {
  source               = "../../modules/ec2"
  providers            = { aws = aws.region2 }
  name                 = "${local.spoke5_prefix}vm"
  availability_zone    = "${local.spoke5_region}a"
  iam_instance_profile = module.common_region2.iam_instance_profile.name
  ami                  = data.aws_ami.ubuntu_region2.id
  key_name             = module.common_region2.key_pair_name
  user_data            = base64encode(module.vm_cloud_init.cloud_config)
  tags                 = local.spoke5_tags

  interfaces = [
    {
      name               = "${local.spoke5_prefix}vm-main"
      subnet_id          = module.spoke5.subnet_ids["MainSubnetA"]
      private_ips        = [local.spoke5_vm_addr, ]
      security_group_ids = [module.spoke5.ec2_security_group_id, ]
      dns_config         = { zone_name = local.region2_dns_zone, name = local.spoke5_vm_hostname }
    }
  ]
  depends_on = [
    time_sleep.spoke5,
  ]
}

####################################################
# spoke6
####################################################

# base

module "spoke6" {
  source    = "../../modules/base"
  providers = { aws = aws.region2 }
  prefix    = trimsuffix(local.spoke6_prefix, "-")
  region    = local.spoke6_region
  tags      = local.spoke6_tags

  cidr               = local.spoke6_cidr
  use_ipv4_ipam_pool = false
  ipv4_ipam_pool_id  = module.common_region2.ipv4_ipam_pool_id

  # enable_ipv6        = local.enable_ipv6
  # ipv6_cidr          = local.spoke6_ipv6_cidr
  # use_ipv6_ipam_pool = false
  # ipv6_ipam_pool_id  = module.common_region2.ipv6_ipam_pool_id[local.spoke6_region]

  subnets = local.spoke6_subnets

  private_dns_config = {
    zone_name = aws_route53_zone.region2.name
  }

  nat_config = [
    { scope = "public", subnet = "UntrustSubnetA", },
  ]

  route_table_config = [
    {
      scope   = "private"
      subnets = [for k, v in local.spoke6_subnets : k if v.scope == "private"]
      routes = [
        { ipv4_cidr = "0.0.0.0/0", nat_gateway = true, nat_gateway_subnet = "UntrustSubnetA" },
      ]
    },
    {
      scope   = "public"
      subnets = [for k, v in local.spoke6_subnets : k if v.scope == "public"]
      routes = [
        { ipv4_cidr = "0.0.0.0/0", internet_gateway = true },
        { ipv6_cidr = "::/0", internet_gateway = true },
      ]
    },
  ]

  depends_on = [
    module.common_region2,
  ]
}

resource "time_sleep" "spoke6" {
  create_duration = "60s"
  depends_on = [
    module.spoke6,
    module.tgw2,
  ]
}

# workload

module "spoke6_vm" {
  source               = "../../modules/ec2"
  providers            = { aws = aws.region2 }
  name                 = "${local.spoke6_prefix}vm"
  availability_zone    = "${local.spoke6_region}a"
  iam_instance_profile = module.common_region2.iam_instance_profile.name
  ami                  = data.aws_ami.ubuntu_region2.id
  key_name             = module.common_region2.key_pair_name
  user_data            = base64encode(module.vm_cloud_init.cloud_config)
  tags                 = local.spoke6_tags

  interfaces = [
    {
      name               = "${local.spoke6_prefix}vm-main"
      subnet_id          = module.spoke6.subnet_ids["MainSubnetA"]
      private_ips        = [local.spoke6_vm_addr, ]
      security_group_ids = [module.spoke6.ec2_security_group_id, ]
      dns_config         = { zone_name = local.region2_dns_zone, name = local.spoke6_vm_hostname }
    }
  ]
  depends_on = [
    time_sleep.spoke6,
  ]
}

####################################################
# output files
####################################################

locals {
  spokes_region2 = {
  }
}

resource "local_file" "spokes_region2" {
  for_each = local.spokes_region2
  filename = each.key
  content  = each.value
}

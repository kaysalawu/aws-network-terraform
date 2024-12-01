
####################################################
# spoke1
####################################################

# base

module "spoke1" {
  source    = "../../modules/base"
  providers = { aws = aws.region1 }
  prefix    = trimsuffix(local.spoke1_prefix, "-")
  region    = local.spoke1_region
  tags      = local.spoke1_tags

  cidr               = local.spoke1_cidr
  use_ipv4_ipam_pool = false
  ipv4_ipam_pool_id  = module.common_region1.ipv4_ipam_pool_id

  # enable_ipv6        = local.enable_ipv6
  # ipv6_cidr          = local.spoke1_ipv6_cidr
  # use_ipv6_ipam_pool = false
  # ipv6_ipam_pool_id  = module.common_region1.ipv6_ipam_pool_id

  subnets = local.spoke1_subnets

  private_dns_config = {
    zone_name = aws_route53_zone.region1.name
  }

  route_table_config = [
    { scope = "private", subnets = [for k, v in local.spoke1_subnets : k if v.scope == "private"] },
    {
      scope   = "public"
      subnets = [for k, v in local.spoke1_subnets : k if v.scope == "public"]
      routes = [
        { ipv4_cidr = "0.0.0.0/0", internet_gateway = true },
        { ipv6_cidr = "::/0", internet_gateway = true },
      ]
    },
  ]

  depends_on = [
    module.common_region1,
  ]
}

resource "time_sleep" "spoke1" {
  create_duration = "60s"
  depends_on = [
    module.spoke1,
    module.tgw1,
  ]
}

# workload

module "spoke1_vm" {
  source               = "../../modules/ec2"
  providers            = { aws = aws.region1 }
  name                 = "${local.spoke1_prefix}vm"
  availability_zone    = "${local.spoke1_region}a"
  iam_instance_profile = module.common_region1.iam_instance_profile.name
  ami                  = data.aws_ami.ubuntu_region1.id
  key_name             = module.common_region1.key_pair_name
  user_data            = base64encode(module.vm_cloud_init.cloud_config)
  tags                 = local.spoke1_tags

  interfaces = [
    {
      name               = "${local.spoke1_prefix}vm-main"
      subnet_id          = module.spoke1.subnet_ids["MainSubnetA"]
      private_ips        = [local.spoke1_vm_addr, ]
      security_group_ids = [module.spoke1.ec2_sg_id, ]
      dns_config         = { zone_name = local.region1_dns_zone, name = local.spoke1_vm_hostname }
    }
  ]
  depends_on = [
    time_sleep.spoke1,
  ]
}

####################################################
# spoke2
####################################################

# base

module "spoke2" {
  source    = "../../modules/base"
  providers = { aws = aws.region1 }
  prefix    = trimsuffix(local.spoke2_prefix, "-")
  region    = local.spoke2_region
  tags      = local.spoke2_tags

  cidr               = local.spoke2_cidr
  use_ipv4_ipam_pool = false
  ipv4_ipam_pool_id  = module.common_region1.ipv4_ipam_pool_id

  # enable_ipv6        = local.enable_ipv6
  # ipv6_cidr          = local.spoke2_ipv6_cidr
  # use_ipv6_ipam_pool = false
  # ipv6_ipam_pool_id  = module.common_region1.ipv6_ipam_pool_id

  subnets = local.spoke2_subnets

  private_dns_config = {
    zone_name = aws_route53_zone.region1.name
  }

  route_table_config = [
    { scope = "private", subnets = [for k, v in local.spoke2_subnets : k if v.scope == "private"] },
    {
      scope   = "public"
      subnets = [for k, v in local.spoke2_subnets : k if v.scope == "public"]
      routes = [
        { ipv4_cidr = "0.0.0.0/0", internet_gateway = true },
        { ipv6_cidr = "::/0", internet_gateway = true },
      ]
    },
  ]

  depends_on = [
    module.common_region1,
  ]
}

resource "time_sleep" "spoke2" {
  create_duration = "60s"
  depends_on = [
    module.spoke2,
    module.tgw1,
  ]
}

# workload

module "spoke2_vm" {
  source               = "../../modules/ec2"
  providers            = { aws = aws.region1 }
  name                 = "${local.spoke2_prefix}vm"
  availability_zone    = "${local.spoke2_region}a"
  iam_instance_profile = module.common_region1.iam_instance_profile.name
  ami                  = data.aws_ami.ubuntu_region1.id
  key_name             = module.common_region1.key_pair_name
  user_data            = base64encode(module.vm_cloud_init.cloud_config)
  tags                 = local.spoke2_tags

  interfaces = [
    {
      name               = "${local.spoke2_prefix}vm-main"
      subnet_id          = module.spoke2.subnet_ids["MainSubnetA"]
      private_ips        = [local.spoke2_vm_addr, ]
      security_group_ids = [module.spoke2.ec2_sg_id, ]
      dns_config         = { zone_name = local.region1_dns_zone, name = local.spoke2_vm_hostname }
    }
  ]
  depends_on = [
    time_sleep.spoke2,
  ]
}

####################################################
# spoke3
####################################################

# base

module "spoke3" {
  source    = "../../modules/base"
  providers = { aws = aws.region1 }
  prefix    = trimsuffix(local.spoke3_prefix, "-")
  region    = local.spoke3_region
  tags      = local.spoke3_tags

  cidr               = local.spoke3_cidr
  use_ipv4_ipam_pool = false
  ipv4_ipam_pool_id  = module.common_region1.ipv4_ipam_pool_id

  # enable_ipv6        = local.enable_ipv6
  # ipv6_cidr          = local.spoke3_ipv6_cidr
  # use_ipv6_ipam_pool = false
  # ipv6_ipam_pool_id  = module.common_region1.ipv6_ipam_pool_id[local.spoke3_region]

  subnets = local.spoke3_subnets

  private_dns_config = {
    zone_name = aws_route53_zone.region1.name
  }

  nat_config = [
    { scope = "public", subnet = "UntrustSubnetA", },
  ]

  route_table_config = [
    {
      scope   = "private"
      subnets = [for k, v in local.spoke3_subnets : k if v.scope == "private"]
      routes = [
        { ipv4_cidr = "0.0.0.0/0", nat_gateway = true, nat_gateway_subnet = "UntrustSubnetA" },
      ]
    },
    {
      scope   = "public"
      subnets = [for k, v in local.spoke3_subnets : k if v.scope == "public"]
      routes = [
        { ipv4_cidr = "0.0.0.0/0", internet_gateway = true },
        { ipv6_cidr = "::/0", internet_gateway = true },
      ]
    },
  ]

  depends_on = [
    module.common_region1,
  ]
}

resource "time_sleep" "spoke3" {
  create_duration = "60s"
  depends_on = [
    module.spoke3,
    module.tgw1,
  ]
}

# workload

module "spoke3_vm" {
  source               = "../../modules/ec2"
  providers            = { aws = aws.region1 }
  name                 = "${local.spoke3_prefix}vm"
  availability_zone    = "${local.spoke3_region}a"
  iam_instance_profile = module.common_region1.iam_instance_profile.name
  ami                  = data.aws_ami.ubuntu_region1.id
  key_name             = module.common_region1.key_pair_name
  user_data            = base64encode(module.vm_cloud_init.cloud_config)
  tags                 = local.spoke3_tags

  interfaces = [
    {
      name               = "${local.spoke3_prefix}vm-main"
      subnet_id          = module.spoke3.subnet_ids["MainSubnetA"]
      private_ips        = [local.spoke3_vm_addr, ]
      security_group_ids = [module.spoke3.ec2_sg_id, ]
      dns_config         = { zone_name = local.region1_dns_zone, name = local.spoke3_vm_hostname }
    }
  ]
  depends_on = [
    time_sleep.spoke3,
  ]
}

####################################################
# output files
####################################################

locals {
  spokes_region1 = {
  }
}

resource "local_file" "spokes_region1" {
  for_each = local.spokes_region1
  filename = each.key
  content  = each.value
}

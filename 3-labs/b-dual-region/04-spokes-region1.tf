
####################################################
# spoke1
####################################################

# base

module "spoke1" {
  source = "../../modules/base"
  prefix = trimsuffix(local.spoke1_prefix, "-")
  region = local.spoke1_region
  tags   = local.spoke1_tags

  cidr               = local.spoke1_cidr
  use_ipv4_ipam_pool = false
  ipv4_ipam_pool_id  = module.common.ipv4_ipam_pool_id[local.spoke1_region]

  # enable_ipv6        = local.enable_ipv6
  # ipv6_cidr          = local.spoke1_ipv6_cidr
  # use_ipv6_ipam_pool = false
  # ipv6_ipam_pool_id  = module.common.ipv6_ipam_pool_id[local.spoke1_region]

  subnets = local.spoke1_subnets

  route_table_config = [
    { scope = "private", subnets = [for k, v in local.spoke1_subnets : k if v.scope == "private"] },
    { scope = "public", subnets = [for k, v in local.spoke1_subnets : k if v.scope == "public"] },
  ]

  depends_on = [
    module.common,
  ]
}

# workload

module "spoke1_vm" {
  source               = "../../modules/ec2"
  name                 = "${local.spoke1_prefix}vm"
  availability_zone    = "${local.spoke1_region}a"
  iam_instance_profile = module.common.iam_instance_profile.name
  ami                  = data.aws_ami.ubuntu.id
  key_name             = module.common.key_pair_name[local.region1]
  user_data            = base64encode(module.vm_cloud_init.cloud_config)
  tags                 = local.spoke1_tags

  interfaces = [
    {
      name               = "${local.spoke1_prefix}vm-main"
      subnet_id          = module.spoke1.subnet_ids["MainSubnet"]
      private_ips        = [local.spoke1_vm_addr, ]
      security_group_ids = [module.spoke1.ec2_security_group_id, ]
      dns_config         = { zone_name = local.cloud_dns_zone, name = "${local.spoke1_vm_hostname}.${local.region1_code}" }
    }
  ]
  depends_on = [
    module.tgw1,
  ]
}

####################################################
# spoke2
####################################################

# base

module "spoke2" {
  source = "../../modules/base"
  prefix = trimsuffix(local.spoke2_prefix, "-")
  region = local.spoke2_region
  tags   = local.spoke2_tags

  cidr               = local.spoke2_cidr
  use_ipv4_ipam_pool = false
  ipv4_ipam_pool_id  = module.common.ipv4_ipam_pool_id[local.spoke2_region]

  # enable_ipv6        = local.enable_ipv6
  # ipv6_cidr          = local.spoke2_ipv6_cidr
  # use_ipv6_ipam_pool = false
  # ipv6_ipam_pool_id  = module.common.ipv6_ipam_pool_id[local.spoke2_region]

  subnets = local.spoke2_subnets

  route_table_config = [
    { scope = "private", subnets = [for k, v in local.spoke2_subnets : k if v.scope == "private"] },
    { scope = "public", subnets = [for k, v in local.spoke2_subnets : k if v.scope == "public"] },
  ]

  depends_on = [
    module.common,
  ]
}

# workload

module "spoke2_vm" {
  source               = "../../modules/ec2"
  name                 = "${local.spoke2_prefix}vm"
  availability_zone    = "${local.spoke2_region}a"
  iam_instance_profile = module.common.iam_instance_profile.name
  ami                  = data.aws_ami.ubuntu.id
  key_name             = module.common.key_pair_name[local.region1]
  user_data            = base64encode(module.vm_cloud_init.cloud_config)
  tags                 = local.spoke2_tags

  interfaces = [
    {
      name               = "${local.spoke2_prefix}vm-main"
      subnet_id          = module.spoke2.subnet_ids["MainSubnet"]
      private_ips        = [local.spoke2_vm_addr, ]
      security_group_ids = [module.spoke2.ec2_security_group_id, ]
      dns_config         = { zone_name = local.cloud_dns_zone, name = "${local.spoke2_vm_hostname}.${local.region1_code}" }
    }
  ]
  depends_on = [
    module.tgw1,
  ]
}

####################################################
# spoke3
####################################################

# base

module "spoke3" {
  source = "../../modules/base"
  prefix = trimsuffix(local.spoke3_prefix, "-")
  region = local.spoke3_region
  tags   = local.spoke3_tags

  cidr               = local.spoke3_cidr
  use_ipv4_ipam_pool = false
  ipv4_ipam_pool_id  = module.common.ipv4_ipam_pool_id[local.spoke3_region]

  # enable_ipv6        = local.enable_ipv6
  # ipv6_cidr          = local.spoke3_ipv6_cidr
  # use_ipv6_ipam_pool = false
  # ipv6_ipam_pool_id  = module.common.ipv6_ipam_pool_id[local.spoke3_region]

  subnets = local.spoke3_subnets

  nat_config = [
    { scope = "public", subnet = "UntrustSubnet", },
  ]

  route_table_config = [
    {
      scope   = "private"
      subnets = [for k, v in local.spoke3_subnets : k if v.scope == "private"]
      routes = [
        { ipv4_cidr = "0.0.0.0/0", nat_gateway = true, nat_gateway_subnet = "UntrustSubnet" },
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
    module.common,
  ]
}

# workload

module "spoke3_vm" {
  source               = "../../modules/ec2"
  name                 = "${local.spoke3_prefix}vm"
  availability_zone    = "${local.spoke3_region}a"
  iam_instance_profile = module.common.iam_instance_profile.name
  ami                  = data.aws_ami.ubuntu.id
  key_name             = module.common.key_pair_name[local.region1]
  user_data            = base64encode(module.vm_cloud_init.cloud_config)
  tags                 = local.spoke3_tags

  interfaces = [
    {
      name               = "${local.spoke3_prefix}vm-main"
      subnet_id          = module.spoke3.subnet_ids["MainSubnet"]
      private_ips        = [local.spoke3_vm_addr, ]
      security_group_ids = [module.spoke3.ec2_security_group_id, ]
      dns_config         = { zone_name = local.cloud_dns_zone, name = "${local.spoke3_vm_hostname}.${local.region1_code}" }
    }
  ]
  depends_on = [
    module.tgw1,
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

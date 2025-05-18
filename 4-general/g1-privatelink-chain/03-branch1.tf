
####################################################
# base
####################################################

module "branch1" {
  source    = "../../modules/base"
  providers = { aws = aws.region1 }
  prefix    = trimsuffix(local.branch1_prefix, "-")
  region    = local.branch1_region
  tags      = local.branch1_tags

  cidr               = local.branch1_cidr
  use_ipv4_ipam_pool = false
  ipv4_ipam_pool_id  = module.common_region1.ipv4_ipam_pool_id

  # enable_ipv6        = local.enable_ipv6
  # ipv6_cidr          = local.branch1_ipv6_cidr
  # use_ipv6_ipam_pool = false
  # ipv6_ipam_pool_id  = module.common_region1.ipv6_ipam_pool_id

  subnets = local.branch1_subnets

  private_dns_config = {
    zone_name = aws_route53_zone.region1.name
  }

  nat_config = [
    { scope = "public", subnet = "UntrustSubnetA", },
  ]

  route_table_config = [
    {
      scope   = "private"
      subnets = [for k, v in local.branch1_subnets : k if v.scope == "private"]
      routes = [
        { ipv4_cidr = "0.0.0.0/0", nat_gateway = true, nat_gateway_subnet = "UntrustSubnetA" },
      ]
    },
    {
      scope   = "public"
      subnets = [for k, v in local.branch1_subnets : k if v.scope == "public"]
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

resource "time_sleep" "branch1" {
  create_duration = "30s"
  depends_on = [
    module.branch1,
  ]
}

####################################################
# workload
####################################################

module "branch1_vm" {
  source               = "../../modules/ec2"
  providers            = { aws = aws.region1 }
  name                 = "${local.branch1_prefix}vm"
  availability_zone    = "${local.branch1_region}a"
  iam_instance_profile = module.common_region1.iam_instance_profile.name
  ami                  = data.aws_ami.ubuntu_region1.id
  key_name             = module.common_region1.key_pair_name
  user_data            = base64encode(module.vm_cloud_init.cloud_config)
  tags                 = local.branch1_tags

  interfaces = [
    {
      name               = "${local.branch1_prefix}vm-main"
      subnet_id          = module.branch1.subnet_ids["MainSubnetA"]
      private_ips        = [local.branch1_vm_addr, ]
      security_group_ids = [module.branch1.ec2_security_group_id, ]
      dns_config         = { zone_name = local.region1_dns_zone, name = local.branch1_vm_hostname }
    }
  ]
  depends_on = [
    time_sleep.branch1,
  ]
}

####################################################
# output files
####################################################

locals {
  branch1_files = {
  }
}

resource "local_file" "branch1_files" {
  for_each = local.branch1_files
  filename = each.key
  content  = each.value
}

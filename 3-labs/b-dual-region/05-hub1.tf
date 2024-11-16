
####################################################
# base
####################################################

module "hub1" {
  source = "../../modules/base"
  prefix = trimsuffix(local.hub1_prefix, "-")
  region = local.hub1_region
  tags   = local.hub1_tags

  cidr               = local.hub1_cidr
  use_ipv4_ipam_pool = false
  ipv4_ipam_pool_id  = module.common.ipv4_ipam_pool_id[local.hub1_region]

  # enable_ipv6        = local.enable_ipv6
  # ipv6_cidr          = local.hub1_ipv6_cidr
  # use_ipv6_ipam_pool = false
  # ipv6_ipam_pool_id  = module.common.ipv6_ipam_pool_id[local.hub1_region]

  subnets = local.hub1_subnets

  private_dns_config = {
    create_zone = true
    zone_name   = local.cloud_dns_zone
    vpc_associations = [
      module.spoke1.vpc_id,
      module.spoke2.vpc_id,
      module.spoke3.vpc_id,
    ]
  }

  nat_config = [
    { scope = "public", subnet = "UntrustSubnet", },
  ]

  route_table_config = [
    {
      scope   = "private"
      subnets = [for k, v in local.hub1_subnets : k if v.scope == "private"]
      routes = [
        { ipv4_cidr = "0.0.0.0/0", nat_gateway = true, nat_gateway_subnet = "UntrustSubnet" },
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
    key_name             = module.common.key_pair_name[local.region1]
    private_ips          = [local.hub1_bastion_addr, ]
    iam_instance_profile = module.common.iam_instance_profile.name
    public_dns_zone_name = local.domain_name
    dns_prefix           = "bastion.hub1.eu"
  }

  depends_on = [
    module.common,
  ]
}

resource "time_sleep" "hub1" {
  triggers = {
    nat_gateways        = jsonencode(module.hub1.nat_gateways)
    internet_gateway_id = module.hub1.internet_gateway_id
  }
  create_duration = "90s"
  depends_on = [
    module.hub1
  ]
}

####################################################
# workload
####################################################

module "hub1_vm" {
  source               = "../../modules/ec2"
  name                 = "${local.hub1_prefix}vm"
  availability_zone    = "${local.hub1_region}a"
  iam_instance_profile = module.common.iam_instance_profile.name
  ami                  = data.aws_ami.ubuntu.id
  key_name             = module.common.key_pair_name[local.region1]
  user_data            = base64encode(module.vm_cloud_init.cloud_config)
  tags                 = local.hub1_tags

  interfaces = [
    {
      name               = "${local.hub1_prefix}vm-main"
      subnet_id          = module.hub1.subnet_ids["MainSubnet"]
      private_ips        = [local.hub1_vm_addr, ]
      security_group_ids = [module.hub1.ec2_security_group_id, ]
      dns_config         = { zone_name = local.cloud_dns_zone, name = "${local.hub1_vm_hostname}.${local.region1_code}" }
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

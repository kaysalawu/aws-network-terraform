
####################################################
# base
####################################################

module "hub2" {
  source = "../../modules/base"
  prefix = trimsuffix(local.hub2_prefix, "-")
  region = local.hub2_region
  tags   = local.hub2_tags

  cidr               = local.hub2_cidr
  use_ipv4_ipam_pool = false
  ipv4_ipam_pool_id  = module.common.ipv4_ipam_pool_id[local.hub2_region]

  # enable_ipv6        = local.enable_ipv6
  # ipv6_cidr          = local.hub2_ipv6_cidr
  # use_ipv6_ipam_pool = false
  # ipv6_ipam_pool_id  = module.common.ipv6_ipam_pool_id[local.hub2_region]

  subnets = local.hub2_subnets

  create_nat_gateway = true

  private_dns_config = {
    create_zone = true
    zone_name   = local.cloud_dns_zone
    vpc_associations = [
      module.spoke4.vpc_id,
      module.spoke5.vpc_id,
      module.spoke6.vpc_id,
    ]
  }

  bastion_config = {
    enable               = true
    key_name             = module.common.key_pair_name[local.hub2_region]
    private_ips          = [local.hub2_bastion_addr]
    iam_instance_profile = module.common.iam_instance_profile.name
    public_dns_zone_name = local.domain_name
    dns_prefix           = "bastion.hub2.eu"
  }

  depends_on = [
    module.common,
  ]
}

resource "time_sleep" "hub2" {
  triggers = {
    nat_gateways        = jsonencode(module.hub2.nat_gateways)
    internet_gateway_id = module.hub2.internet_gateway_id
  }
  create_duration = "90s"
  depends_on = [
    module.hub2
  ]
}

####################################################
# workload
####################################################

module "hub2_vm" {
  source               = "../../modules/ec2"
  name                 = "${local.hub2_prefix}vm"
  availability_zone    = "${local.hub2_region}a"
  iam_instance_profile = module.common.iam_instance_profile.name
  ami                  = data.aws_ami.ubuntu.id
  key_name             = module.common.key_pair_name[local.hub2_region]
  user_data            = base64encode(module.vm_cloud_init.cloud_config)
  tags                 = local.hub2_tags

  interfaces = [
    {
      name               = "${local.hub2_prefix}vm-main"
      subnet_id          = module.hub2.subnet_ids["MainSubnet"]
      private_ips        = [local.hub2_vm_addr, ]
      security_group_ids = [module.hub2.ec2_security_group_id, ]
      dns_config         = { zone_name = local.cloud_dns_zone, name = "${local.hub2_vm_hostname}.${local.region2_code}" }
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

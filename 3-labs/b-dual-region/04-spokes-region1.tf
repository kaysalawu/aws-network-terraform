
####################################################
# base
####################################################

module "spoke1" {
  source = "../../modules/base"
  prefix = trimsuffix(local.spoke1_prefix, "-")
  region = local.spoke1_region
  tags   = local.spoke1_tags

  cidr               = local.spoke1_cidr
  use_ipv4_ipam_pool = false
  ipv4_ipam_pool_id  = module.common.ipv4_ipam_pool_id[local.spoke1_region]

  enable_ipv6        = local.enable_ipv6
  ipv6_cidr          = local.spoke1_ipv6_cidr
  use_ipv6_ipam_pool = false
  ipv6_ipam_pool_id  = module.common.ipv6_ipam_pool_id[local.spoke1_region]

  subnets = local.spoke1_subnets

  depends_on = [
    module.common,
  ]
}

####################################################
# workload
####################################################

module "spoke1_vm" {
  source               = "../../modules/ec2"
  name                 = "${local.spoke1_prefix}vm"
  availability_zone    = "${local.spoke1_region}a"
  iam_instance_profile = module.common.iam_instance_profile.name
  ami                  = data.aws_ami.ubuntu.id
  key_name             = module.common.key_pair_name[local.spoke1_region]
  user_data            = base64encode(module.vm_cloud_init.cloud_config)
  tags                 = local.spoke1_tags

  interfaces = [
    {
      name               = "${local.spoke1_prefix}vm-main"
      subnet_id          = module.spoke1.private_subnet_ids["MainSubnet"]
      private_ips        = [local.spoke1_vm_addr, ]
      security_group_ids = [module.spoke1.ec2_security_group_id, ]
    }
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


####################################################
# base
####################################################

module "branch1" {
  source = "../../modules/base"
  prefix = trimsuffix(local.branch1_prefix, "-")
  region = local.branch1_region
  tags   = local.branch1_tags

  cidr               = local.branch1_cidr
  use_ipv4_ipam_pool = false
  ipv4_ipam_pool_id  = module.common.ipv4_ipam_pool_id[local.branch1_region]

  enable_ipv6        = local.enable_ipv6
  ipv6_cidr          = local.branch1_ipv6_cidr
  use_ipv6_ipam_pool = false
  ipv6_ipam_pool_id  = module.common.ipv6_ipam_pool_id[local.branch1_region]

  subnets = local.branch1_subnets

  public_dns_zone_name = local.domain_name

  dhcp_options = {
    enable              = true
    domain_name         = local.cloud_dns_zone
    domain_name_servers = [local.branch1_dns_addr, ]
  }

  depends_on = [
    module.common,
  ]
}

resource "time_sleep" "branch1" {
  create_duration = "30s"
  depends_on = [
    module.branch1
  ]
}

####################################################
# dns
####################################################

locals {
  branch1_unbound_startup = templatefile("../../scripts/unbound/unbound.sh", local.branch1_dns_vars)
  branch1_dns_vars = {
    HOSTNAME             = "${local.branch1_prefix}dns"
    ONPREM_LOCAL_RECORDS = local.onprem_local_records
    REDIRECTED_HOSTS     = local.onprem_redirected_hosts
    FORWARD_ZONES        = local.branch1_forward_zones
    TARGETS              = local.vm_script_targets
    ACCESS_CONTROL_PREFIXES = concat(
      local.private_prefixes_ipv4,
      ["127.0.0.0/8", "35.199.192.0/19", "fd00::/8", ]
    )
  }
  branch1_forward_zones = [
    { zone = "${local.region1_dns_zone}.", targets = [local.hub1_dns_in_addr, ] },
    { zone = "${local.region2_dns_zone}.", targets = [local.hub2_dns_in_addr, ] },
    { zone = ".", targets = [local.amazon_dns_ipv4, ] },
  ]
}

module "branch1_dns" {
  source               = "../../modules/ec2"
  name                 = "${local.branch1_prefix}dns"
  availability_zone    = "${local.branch1_region}a"
  iam_instance_profile = module.common.iam_instance_profile.name
  ami                  = data.aws_ami.ubuntu.id
  key_name             = module.common.key_pair_name[local.branch1_region]
  user_data            = base64encode(local.branch1_unbound_startup)
  tags                 = local.branch1_tags

  interfaces = [
    {
      name               = "${local.branch1_prefix}dns-main"
      subnet_id          = module.branch1.private_subnet_ids["MainSubnet"]
      private_ips        = [local.branch1_dns_addr, ]
      security_group_ids = [module.branch1.ec2_security_group_id, ]
    }
  ]
  depends_on = [
    time_sleep.branch1,
  ]
}
resource "time_sleep" "branch1_dns" {
  create_duration = "120s"
  depends_on = [
    module.branch1_dns,
  ]
}

####################################################
# workload
####################################################

module "branch1_vm" {
  source               = "../../modules/ec2"
  name                 = "${local.branch1_prefix}vm"
  availability_zone    = "${local.branch1_region}a"
  iam_instance_profile = module.common.iam_instance_profile.name
  ami                  = data.aws_ami.ubuntu.id
  key_name             = module.common.key_pair_name[local.branch1_region]
  user_data            = base64encode(module.vm_cloud_init.cloud_config)
  tags                 = local.branch1_tags

  interfaces = [
    {
      name               = "${local.branch1_prefix}vm-main"
      subnet_id          = module.branch1.private_subnet_ids["MainSubnet"]
      private_ips        = [local.branch1_vm_addr, ]
      security_group_ids = [module.branch1.ec2_security_group_id, ]
    }
  ]
  depends_on = [
    time_sleep.branch1_dns,
  ]
}

####################################################
# output files
####################################################

locals {
  branch1_files = {
    "output/branch1Dns.sh" = local.branch1_unbound_startup
  }
}

resource "local_file" "branch1_files" {
  for_each = local.branch1_files
  filename = each.key
  content  = each.value
}

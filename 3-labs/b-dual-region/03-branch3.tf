
####################################################
# base
####################################################

module "branch3" {
  source    = "../../modules/base"
  providers = { aws = aws.region2 }
  prefix    = trimsuffix(local.branch3_prefix, "-")
  region    = local.branch3_region
  tags      = local.branch3_tags

  cidr               = local.branch3_cidr
  use_ipv4_ipam_pool = false
  ipv4_ipam_pool_id  = module.common_region2.ipv4_ipam_pool_id

  # enable_ipv6        = local.enable_ipv6
  # ipv6_cidr          = local.branch3_ipv6_cidr
  # use_ipv6_ipam_pool = false
  # ipv6_ipam_pool_id  = module.common_region2.ipv6_ipam_pool_id

  subnets = local.branch3_subnets

  create_internet_gateway = true

  nat_config = [
    { scope = "public", subnet = "UntrustSubnet", },
  ]

  route_table_config = [
    {
      scope   = "private"
      subnets = [for k, v in local.branch3_subnets : k if v.scope == "private"]
      routes = [
        { ipv4_cidr = "0.0.0.0/0", nat_gateway = true, nat_gateway_subnet = "UntrustSubnet" },
      ]
    },
    {
      scope   = "public"
      subnets = [for k, v in local.branch3_subnets : k if v.scope == "public"]
      routes = [
        { ipv4_cidr = "0.0.0.0/0", internet_gateway = true },
        { ipv6_cidr = "::/0", internet_gateway = true },
      ]
    },
  ]

  dhcp_options = {
    enable              = true
    domain_name         = local.domain_name
    domain_name_servers = [local.branch3_dns_addr, ]
  }

  depends_on = [
    module.common_region2,
  ]
}

resource "time_sleep" "branch3" {
  create_duration = "30s"
  depends_on = [
    module.branch3
  ]
}

####################################################
# dns
####################################################

locals {
  branch3_unbound_startup = templatefile("../../scripts/unbound/unbound.sh", local.branch3_dns_vars)
  branch3_dns_vars = {
    HOSTNAME             = "${local.branch3_prefix}dns"
    ONPREM_LOCAL_RECORDS = local.onprem_local_records
    REDIRECTED_HOSTS     = local.onprem_redirected_hosts
    FORWARD_ZONES        = local.branch3_forward_zones
    TARGETS              = local.vm_script_targets
    ACCESS_CONTROL_PREFIXES = concat(
      local.private_prefixes_ipv4,
      ["127.0.0.0/8", "35.199.192.0/19", "fd00::/8", ]
    )
    USERNAME = local.username
    PASSWORD = local.password
  }
  branch3_forward_zones = [
    { zone = "${local.region1_dns_zone}.", targets = [local.hub1_dns_in_addr, ] },
    { zone = "${local.region2_dns_zone}.", targets = [local.hub2_dns_in_addr, ] },
    { zone = ".", targets = [local.amazon_dns_ipv4, ] },
  ]
}

module "branch3_dns" {
  source               = "../../modules/ec2"
  providers            = { aws = aws.region2 }
  name                 = "${local.branch3_prefix}dns"
  availability_zone    = "${local.branch3_region}a"
  iam_instance_profile = module.common_region2.iam_instance_profile.name
  ami                  = data.aws_ami.ubuntu_region2.id
  key_name             = module.common_region2.key_pair_name
  user_data            = base64encode(local.branch3_unbound_startup)
  tags                 = local.branch3_tags

  interfaces = [
    {
      name               = "${local.branch3_prefix}dns-main"
      subnet_id          = module.branch3.subnet_ids["MainSubnet"]
      private_ips        = [local.branch3_dns_addr, ]
      security_group_ids = [module.branch3.ec2_security_group_id, ]
    }
  ]
  depends_on = [
    time_sleep.branch3,
  ]
}

resource "time_sleep" "branch3_dns" {
  create_duration = "120s"
  depends_on = [
    module.branch3_dns,
  ]
}

####################################################
# workload
####################################################

module "branch3_vm" {
  source               = "../../modules/ec2"
  providers            = { aws = aws.region2 }
  name                 = "${local.branch3_prefix}vm"
  availability_zone    = "${local.branch3_region}a"
  iam_instance_profile = module.common_region2.iam_instance_profile.name
  ami                  = data.aws_ami.ubuntu_region2.id
  key_name             = module.common_region2.key_pair_name
  user_data            = base64encode(module.vm_cloud_init.cloud_config)
  tags                 = local.branch3_tags

  interfaces = [
    {
      name               = "${local.branch3_prefix}vm-main"
      subnet_id          = module.branch3.subnet_ids["MainSubnet"]
      private_ips        = [local.branch3_vm_addr, ]
      security_group_ids = [module.branch3.ec2_security_group_id, ]
    }
  ]
  depends_on = [
    time_sleep.branch3_dns,
  ]
}

####################################################
# output files
####################################################,

locals {
  branch3_files = {
    "output/branch3-dns.sh" = local.branch3_unbound_startup
  }
}

resource "local_file" "branch3_files" {
  for_each = local.branch3_files
  filename = each.key
  content  = each.value
}

####################################################
# lab
####################################################

locals {
  # prefix                 = "b"
  lb_name                = "dual-region"
  enable_onprem_wan_link = false
  enable_dashboards      = false
  enable_ipv6            = false
  enable_vpc_flow_logs   = false

  hub1_tags    = { "lab" = var.prefix, "env" = "prod", "nodeType" = "hub" }
  hub2_tags    = { "lab" = var.prefix, "env" = "prod", "nodeType" = "hub" }
  branch1_tags = { "lab" = var.prefix, "env" = "prod", "nodeType" = "branch" }
  branch2_tags = { "lab" = var.prefix, "env" = "prod", "nodeType" = "branch" }
  branch3_tags = { "lab" = var.prefix, "env" = "prod", "nodeType" = "branch" }
  tgw1_tags    = { "lab" = var.prefix, "env" = "prod", "nodeType" = "tgw" }
  tgw2_tags    = { "lab" = var.prefix, "env" = "prod", "nodeType" = "tgw" }
}

resource "random_id" "random" {
  byte_length = 2
}

####################################################
# providers
####################################################

provider "aws" {
  region     = local.region1
  access_key = var.aws_access_key
  secret_key = var.aws_secret_access_key
}

provider "aws" {
  alias      = "default"
  region     = local.region1
  access_key = var.aws_access_key
  secret_key = var.aws_secret_access_key
}

provider "aws" {
  alias      = "region1"
  region     = local.region1
  access_key = var.aws_access_key
  secret_key = var.aws_secret_access_key
}

####################################################
# data
####################################################

data "aws_ami" "ubuntu_region1" {
  provider    = aws.region1
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_route53_zone" "public" {
  provider     = aws.default
  name         = "cloudtuple.org."
  private_zone = false
}

data "aws_caller_identity" "current" {
  provider = aws.default
}

####################################################
# network features
####################################################

locals {
  regions = {
    "region1" = { name = local.region1, dns_zone = local.region1_dns_zone }
  }

  hub1_features = {
    dns_resolver_config = [
      # {
      # inbound = [
      #   { subnet = "DnsInboundSubnetA", ip = local.hub1_dns_in_addr1 },
      #   { subnet = "DnsInboundSubnetB", ip = local.hub1_dns_in_addr2 }
      # ]
      # outbound = [
      #   { subnet = "DnsOutboundSubnetA", ip = local.hub1_dns_out_addr1 },
      #   { subnet = "DnsOutboundSubnetB", ip = local.hub1_dns_out_addr2 }
      # ]
      # rules = [
      #   {
      #     domain = local.onprem_domain
      #     target_ips = [
      #       local.branch1_dns_addr,
      #       local.branch3_dns_addr,
      #     ]
      #   },
      # ]
      # additional_associated_vpc_ids = []
      # }
    ]
  }
}

####################################################
# common resources
####################################################

module "common_region1" {
  source                = "../../modules/common"
  providers             = { aws = aws.region1 }
  env                   = "common"
  prefix                = var.prefix
  region                = local.region1
  private_prefixes_ipv4 = local.private_prefixes_ipv4
  private_prefixes_ipv6 = local.private_prefixes_ipv6
  public_key_path       = var.public_key_path
  tags                  = {}
}

# vm startup scripts
#----------------------------

locals {
  hub1_nva_asn   = "65010"
  hub1_vpngw_asn = "65011"
  hub1_ergw_asn  = "65012"
  hub1_ars_asn   = "65515"

  hub2_nva_asn   = "65020"
  hub2_vpngw_asn = "65021"
  hub2_ergw_asn  = "65022"
  hub2_ars_asn   = "65515"

  init_dir                  = "/var/lib/aws"
  vm_script_targets_region1 = []
  vm_script_targets_misc = [
    { name = "internet", host = "icanhazip.com" },
  ]
  vm_script_targets = concat(
    local.vm_script_targets_region1,
    local.vm_script_targets_misc,
  )
  vm_startup = templatefile("../../scripts/server.sh", {
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = []
    TARGETS_HEAVY_TRAFFIC_GEN = []
    ENABLE_TRAFFIC_GEN        = false
  })
  vm_init_vars = {
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = []
    TARGETS_HEAVY_TRAFFIC_GEN = []
    USERNAME                  = local.username
    PASSWORD                  = local.password
  }
  proxy_init_vars = {
    ONPREM_LOCAL_RECORDS = []
    REDIRECTED_HOSTS     = []
    FORWARD_ZONES        = []
    TARGETS              = local.vm_script_targets
    ACCESS_CONTROL_PREFIXES = concat(
      local.private_prefixes_ipv4,
      ["127.0.0.0/8", "35.199.192.0/19", "fd00::/8", ]
    )
    USERNAME = local.username
    PASSWORD = local.password
  }
  vm_init_files         = {}
  vm_startup_init_files = {}
  onprem_local_records = [
    { name = lower(local.branch1_vm_fqdn), rdata = local.branch1_vm_addr, ttl = "300", type = "A" },
    { name = lower(local.branch2_vm_fqdn), rdata = local.branch2_vm_addr, ttl = "300", type = "A" },
    { name = lower(local.branch3_vm_fqdn), rdata = local.branch3_vm_addr, ttl = "300", type = "A" },
    { name = lower(local.branch1_vm_fqdn), rdata = local.branch1_vm_addr_v6, ttl = "300", type = "AAAA" },
    { name = lower(local.branch2_vm_fqdn), rdata = local.branch2_vm_addr_v6, ttl = "300", type = "AAAA" },
    { name = lower(local.branch3_vm_fqdn), rdata = local.branch3_vm_addr_v6, ttl = "300", type = "AAAA" },
  ]
  onprem_redirected_hosts = []
}

####################################################
# addresses
####################################################

# branch1

resource "aws_eip" "branch1_nva_untrust" {
  provider = aws.region1
  domain   = "vpc"
  tags = {
    Name = "${local.branch1_prefix}nva-untrust"
  }
}

####################################################
# output files
####################################################

locals {
  main_files = {}
}

resource "local_file" "main_files" {
  for_each = local.main_files
  filename = each.key
  content  = each.value
}

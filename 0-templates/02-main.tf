####################################################
# lab
####################################################

locals {
  prefix                 = "b"
  lb_name                = "dual-region"
  enable_onprem_wan_link = false
  enable_diagnostics     = false
  enable_ipv6            = false
  enable_vnet_flow_logs  = false

  hub1_tags    = { "lab" = local.prefix, "env" = "prod", "nodeType" = "hub" }
  hub2_tags    = { "lab" = local.prefix, "env" = "prod", "nodeType" = "hub" }
  branch1_tags = { "lab" = local.prefix, "env" = "prod", "nodeType" = "branch" }
  branch2_tags = { "lab" = local.prefix, "env" = "prod", "nodeType" = "branch" }
  branch3_tags = { "lab" = local.prefix, "env" = "prod", "nodeType" = "branch" }
  spoke1_tags  = { "lab" = local.prefix, "env" = "prod", "nodeType" = "spoke" }
  spoke2_tags  = { "lab" = local.prefix, "env" = "prod", "nodeType" = "spoke" }
  spoke3_tags  = { "lab" = local.prefix, "env" = "prod", "nodeType" = "float" }
  spoke4_tags  = { "lab" = local.prefix, "env" = "prod", "nodeType" = "spoke" }
  spoke5_tags  = { "lab" = local.prefix, "env" = "prod", "nodeType" = "spoke" }
  spoke6_tags  = { "lab" = local.prefix, "env" = "prod", "nodeType" = "float" }
  tgw1_tags    = { "lab" = local.prefix, "env" = "prod", "nodeType" = "tgw" }
  tgw2_tags    = { "lab" = local.prefix, "env" = "prod", "nodeType" = "tgw" }
}

resource "random_id" "random" {
  byte_length = 2
}

####################################################
# providers
####################################################

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

provider "aws" {
  alias      = "region2"
  region     = local.region2
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

data "aws_ami" "ubuntu_region2" {
  provider    = aws.region2
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
    "region2" = { name = local.region2, dns_zone = local.region2_dns_zone }
  }

  hub1_features = {
    config_nva = {
      # enable           = true
      # enable_ipv6      = local.enable_ipv6
      # type             = "linux"
      # scenario_option  = "TwoNics"
      # opn_type         = "TwoNics"
      # custom_data      = base64encode(local.hub1_linux_nva_init)
      # ilb_untrust_ip   = local.hub1_nva_ilb_untrust_addr
      # ilb_trust_ip     = local.hub1_nva_ilb_trust_addr
      # ilb_untrust_ipv6 = local.hub1_nva_ilb_untrust_addr_v6
      # ilb_trust_ipv6   = local.hub1_nva_ilb_trust_addr_v6
    }
  }

  hub2_features = {
    config_nva = {
      # enable           = true
      # enable_ipv6      = local.enable_ipv6
      # type             = "linux"
      # scenario_option  = "TwoNics"
      # opn_type         = "TwoNics"
      # custom_data      = base64encode(local.hub2_linux_nva_init)
      # ilb_untrust_ip   = local.hub2_nva_ilb_untrust_addr
      # ilb_trust_ip     = local.hub2_nva_ilb_trust_addr
      # ilb_untrust_ipv6 = local.hub2_nva_ilb_untrust_addr_v6
      # ilb_trust_ipv6   = local.hub2_nva_ilb_trust_addr_v6
    }
  }

  tgw1_features = {
  }

  tgw2_features = {
  }
}

####################################################
# common resources
####################################################

module "common_region1" {
  source                = "../../modules/common"
  providers             = { aws = aws.region1 }
  env                   = "common"
  prefix                = local.prefix
  region                = local.region1
  private_prefixes_ipv4 = local.private_prefixes_ipv4
  private_prefixes_ipv6 = local.private_prefixes_ipv6
  public_key_path       = var.public_key_path
  private_key_path      = var.private_key_path
  tags                  = {}
}

module "common_region2" {
  source                = "../../modules/common"
  providers             = { aws = aws.region2 }
  env                   = "common"
  prefix                = local.prefix
  region                = local.region2
  private_prefixes_ipv4 = local.private_prefixes_ipv4
  private_prefixes_ipv6 = local.private_prefixes_ipv6
  public_key_path       = var.public_key_path
  private_key_path      = var.private_key_path
  tags                  = {}
}

# private dns zones

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

  init_dir = "/var/lib/aws"
  vm_script_targets_region1 = [
    { name = "branch1", host = local.branch1_vm_fqdn, ipv4 = local.branch1_vm_addr, ipv6 = local.branch1_vm_addr_v6, probe = true },
    { name = "hub1   ", host = local.hub1_vm_fqdn, ipv4 = local.hub1_vm_addr, ipv6 = local.hub1_vm_addr_v6, probe = true },
    # { name = "hub1-spoke3-pep", host = local.hub1_spoke3_pep_fqdn, ping = false, probe = true },
    { name = "spoke1 ", host = local.spoke1_vm_fqdn, ipv4 = local.spoke1_vm_addr, ipv6 = local.spoke1_vm_addr_v6, probe = true },
    { name = "spoke2 ", host = local.spoke2_vm_fqdn, ipv4 = local.spoke2_vm_addr, ipv6 = local.spoke2_vm_addr_v6, probe = true },
  ]
  vm_script_targets_region2 = [
    { name = "branch3", host = local.branch3_vm_fqdn, ipv4 = local.branch3_vm_addr, ipv6 = local.branch3_vm_addr_v6, probe = true },
    { name = "hub2   ", host = local.hub2_vm_fqdn, ipv4 = local.hub2_vm_addr, ipv6 = local.hub2_vm_addr_v6, probe = true },
    # { name = "hub2-spoke6-pep", host = local.hub2_spoke6_pep_fqdn, ping = false, probe = true },
    { name = "spoke4 ", host = local.spoke4_vm_fqdn, ipv4 = local.spoke4_vm_addr, ipv6 = local.spoke4_vm_addr_v6, probe = true },
    { name = "spoke5 ", host = local.spoke5_vm_fqdn, ipv4 = local.spoke5_vm_addr, ipv6 = local.spoke5_vm_addr_v6, probe = true },
  ]
  vm_script_targets_misc = [
    { name = "internet", host = "icanhazip.com" },
  ]
  vm_script_targets = concat(
    local.vm_script_targets_region1,
    local.vm_script_targets_region2,
    local.vm_script_targets_misc,
  )
  vm_startup = templatefile("../../scripts/server.sh", {
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = []
    TARGETS_HEAVY_TRAFFIC_GEN = []
    ENABLE_TRAFFIC_GEN        = false
  })
  probe_init_vars = {
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = local.vm_script_targets
    TARGETS_HEAVY_TRAFFIC_GEN = [for target in local.vm_script_targets : target.host if try(target.probe, false)]
    USERNAME                  = local.username
    PASSWORD                  = local.password
  }
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
  vm_init_files = {
    "${local.init_dir}/fastapi/docker-compose-http-80.yml"   = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/fastapi/docker-compose-http-80.yml", {}) }
    "${local.init_dir}/fastapi/docker-compose-http-8080.yml" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/fastapi/docker-compose-http-8080.yml", {}) }
  }
  vm_startup_init_files = {
    "${local.init_dir}/init/startup.sh" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/startup.sh", local.vm_init_vars) }
    "usr/local/bin/targets.json"        = { owner = "root", permissions = "0744", content = jsonencode(local.vm_script_targets) }
  }
  probe_startup_init_files = {
    "${local.init_dir}/init/startup.sh" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/startup.sh", local.probe_init_vars) }
  }
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

module "vm_cloud_init" {
  source = "../../modules/cloud-config-gen"
  files = merge(
    local.vm_init_files,
    local.vm_startup_init_files
  )
  packages = []
  run_commands = [
    "bash ${local.init_dir}/init/startup.sh",
    "HOSTNAME=$(hostname) docker compose -f ${local.init_dir}/fastapi/docker-compose-http-80.yml up -d",
    "HOSTNAME=$(hostname) docker compose -f ${local.init_dir}/fastapi/docker-compose-http-8080.yml up -d",
  ]
}

module "probe_vm_cloud_init" {
  source = "../../modules/cloud-config-gen"
  files = merge(
    local.vm_init_files,
    local.probe_startup_init_files,
  )
  packages = []
  run_commands = [
    "bash ${local.init_dir}/init/startup.sh",
    "HOSTNAME=$(hostname) docker compose -f ${local.init_dir}/fastapi/docker-compose-http-80.yml up -d",
    "HOSTNAME=$(hostname) docker compose -f ${local.init_dir}/fastapi/docker-compose-http-8080.yml up -d",
  ]
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

# branch3

resource "aws_eip" "branch3_nva_untrust" {
  provider = aws.region2
  domain   = "vpc"
  tags = {
    Name = "${local.branch3_prefix}nva-untrust"
  }
}

####################################################
# output files
####################################################

locals {
  main_files = {
    "output/server.sh"              = local.vm_startup
    "output/startup.sh"             = templatefile("../../scripts/startup.sh", local.vm_init_vars)
    "output/startup-probe.sh"       = templatefile("../../scripts/startup.sh", local.probe_init_vars)
    "output/probe-cloud-config.yml" = module.probe_vm_cloud_init.cloud_config
    "output/vm-cloud-config.yml"    = module.vm_cloud_init.cloud_config
  }
}

resource "local_file" "main_files" {
  for_each = local.main_files
  filename = each.key
  content  = each.value
}

####################################################
# base
####################################################


module "branch1" {
  source = "../../modules/base"
  prefix = trimsuffix(local.branch1_prefix, "-")
  region = local.branch1_region
  tags   = local.branch1_tags

  cidr    = local.branch1_cidr
  subnets = local.branch1_subnets

  depends_on = [
    module.common,
  ]
}

resource "time_sleep" "branch1" {
  create_duration = "90s"
  depends_on = [
    module.branch1
  ]
}

# module "branch1" {
#   source = "terraform-aws-modules/vpc/aws"
#   name   = "${local.branch1_prefix}vpc"
#   cidr   = local.branch1_cidr.0
#   azs    = ["${local.branch1_region}a", ]
#   tags   = local.branch1_tags

#   private_subnet_names = [for k, v in local.branch1_subnets : k if v.type == "private"]
#   public_subnet_names  = [for k, v in local.branch1_subnets : k if v.type == "public"]
#   private_subnets      = [for k, v in local.branch1_subnets : v.address_prefixes[0] if v.type == "private"]
#   public_subnets       = [for k, v in local.branch1_subnets : v.address_prefixes[0] if v.type == "public"]

#   enable_nat_gateway = true
#   enable_vpn_gateway = false
# }

# resource "time_sleep" "branch1" {
#   create_duration = "90s"
#   depends_on = [
#     module.branch1
#   ]
# }

####################################################
# dns
####################################################

locals {
  branch1_unbound_startup = templatefile("../../scripts/unbound/unbound.sh", local.branch1_dns_vars)
  branch1_dns_vars = {
    ONPREM_LOCAL_RECORDS = local.onprem_local_records
    REDIRECTED_HOSTS     = local.onprem_redirected_hosts
    FORWARD_ZONES        = local.branch1_forward_zones
    TARGETS              = local.vm_script_targets
    ACCESS_CONTROL_PREFIXES = concat(
      local.private_prefixes,
      ["127.0.0.0/8", "35.199.192.0/19", "fd00::/8", ]
    )
  }
  branch1_forward_zones = [
    { zone = "${local.region1_dns_zone}.", targets = [local.hub1_dns_in_addr, ] },
    { zone = "${local.region2_dns_zone}.", targets = [local.hub2_dns_in_addr, ] },
    { zone = "privatelink.blob.core.windows.net.", targets = [local.hub1_dns_in_addr, ] },
    { zone = "privatelink.azurewebsites.net.", targets = [local.hub1_dns_in_addr, ] },
    { zone = "privatelink.database.windows.net.", targets = [local.hub1_dns_in_addr, ] },
    { zone = "privatelink.table.cosmos.azure.com.", targets = [local.hub1_dns_in_addr, ] },
    { zone = "privatelink.queue.core.windows.net.", targets = [local.hub1_dns_in_addr, ] },
    { zone = "privatelink.file.core.windows.net.", targets = [local.hub1_dns_in_addr, ] },
    { zone = ".", targets = [local.amazon_dns4, ] },
  ]
}

# module "branch1_dns" {
#   source                 = "terraform-aws-modules/ec2-instance/aws"
#   name                   = "${local.branch1_prefix}dns"
#   instance_type          = local.vmsize
#   key_name               = module.common.key_pair_name
#   monitoring             = true
#   vpc_security_group_ids = ["sg-12345678"]
#   subnet_id              = "subnet-eddcdzz4"

#   tags = {
#     Terraform   = "true"
#     Environment = "dev"
#   }
# }

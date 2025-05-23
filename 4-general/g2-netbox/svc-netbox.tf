
####################################################
# base
####################################################

# network

module "hub1" {
  source    = "../../modules/base"
  providers = { aws = aws.region1 }
  prefix    = trimsuffix(local.hub1_prefix, "-")
  region    = local.hub1_region
  tags      = local.hub1_tags

  cidr               = local.hub1_cidr
  use_ipv4_ipam_pool = false
  ipv4_ipam_pool_id  = module.common_region1.ipv4_ipam_pool_id

  # enable_ipv6        = local.enable_ipv6
  # ipv6_cidr          = local.hub1_ipv6_cidr
  # use_ipv6_ipam_pool = false
  # ipv6_ipam_pool_id  = module.common_region1.ipv6_ipam_pool_id

  subnets             = local.hub1_subnets
  dns_resolver_config = local.hub1_features.dns_resolver_config

  nat_config = [
    { scope = "public", subnet = "UntrustSubnetA", },
  ]

  route_table_config = [
    {
      scope   = "private"
      subnets = [for k, v in local.hub1_subnets : k if v.scope == "private"]
      routes = [
        { ipv4_cidr = "0.0.0.0/0", nat_gateway = true, nat_gateway_subnet = "UntrustSubnetA" },
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
    key_name             = module.common_region1.key_pair_name
    private_ip_list      = [local.hub1_bastion_addr, ]
    iam_instance_profile = module.common_region1.iam_instance_profile.name
  }

  depends_on = [
    module.common_region1,
  ]
}

# private dns

resource "aws_route53_zone" "region1" {
  provider = aws.region1
  name     = local.region1_dns_zone
  vpc {
    vpc_id = module.hub1.vpc_id
  }
  lifecycle {
    ignore_changes = [vpc, ]
  }
}

####################################################
# ssm parameters
####################################################

# netbox

resource "aws_ssm_parameter" "netbox_admin_username" {
  provider    = aws.region1
  name        = "netbox_admin_username"
  description = "NetBox admin username"
  type        = "String"
  value       = "admin"
}

resource "aws_ssm_parameter" "netbox_admin_password" {
  provider    = aws.region1
  name        = "netbox_admin_password"
  description = "NetBox admin password"
  type        = "SecureString"
  value       = "Password123"
}

resource "aws_ssm_parameter" "netbox_admin_email" {
  provider    = aws.region1
  name        = "netbox_admin_email"
  description = "NetBox admin email"
  type        = "String"
  value       = "admin@example.com"
}

# postgresql

resource "aws_ssm_parameter" "postgresql_db_name" {
  provider    = aws.region1
  name        = "postgresql_db_name"
  description = "NetBox PostgreSQL database name"
  type        = "String"
  value       = "netbox"
}

resource "aws_ssm_parameter" "postgresql_username" {
  provider    = aws.region1
  name        = "postgresql_username"
  description = "NetBox PostgreSQL user"
  type        = "String"
  value       = "netbox"
}

resource "aws_ssm_parameter" "postgresql_password" {
  provider    = aws.region1
  name        = "postgresql_password"
  description = "NetBox PostgreSQL user"
  type        = "SecureString"
  value       = "Password123"
}

####################################################
# rds
####################################################

module "rds_postgres" {
  providers           = { aws = aws.region1 }
  source              = "../../modules/rds-postgres"
  identifier          = "${local.hub1_prefix}netbox-rds"
  vpc_id              = module.hub1.vpc_id
  allowed_cidr_blocks = local.private_prefixes_ipv4
  subnet_ids = [
    module.hub1.subnet_ids["DatabaseSubnetA"],
    module.hub1.subnet_ids["DatabaseSubnetB"],
  ]
  db_name              = aws_ssm_parameter.postgresql_db_name.value
  db_username          = aws_ssm_parameter.postgresql_username.value
  db_password          = aws_ssm_parameter.postgresql_password.value
  parameter_group_name = "default.postgres13"
  tags                 = local.hub1_tags
}

####################################################
# workload
####################################################

locals {
  netbox_init_dir = "/var/lib/aws"
  netbox_init_vars = {
    USERNAME        = local.username
    PASSWORD        = local.password
    RDS_DB_ENDPOINT = split(":", module.rds_postgres.endpoint)[0]
  }
  netbox_startup_files = {
    "${local.netbox_init_dir}/netbox/netbox.sh" = { owner = "root", permissions = "0744", content = templatefile("./scripts/netbox/netbox.sh", local.netbox_init_vars) }
  }
}

module "netbox_cloud_init" {
  source = "../../modules/cloud-config-gen"
  files = merge(
    local.vm_init_files,
    local.netbox_startup_files
  )
  packages = []
  run_commands = [
    "${local.netbox_init_dir}/netbox/netbox.sh",
  ]
}

module "hub1_vm" {
  source               = "../../modules/ec2"
  providers            = { aws = aws.region1 }
  name                 = "${local.hub1_prefix}vm"
  availability_zone    = "${local.hub1_region}a"
  instance_type        = "t3.small"
  iam_instance_profile = module.common_region1.iam_instance_profile.name
  ami                  = data.aws_ami.ubuntu_region1.id
  key_name             = module.common_region1.key_pair_name
  user_data            = base64encode(module.netbox_cloud_init.cloud_config)
  tags                 = local.hub1_tags

  interfaces = [
    {
      name               = "${local.hub1_prefix}vm-main"
      subnet_id          = module.hub1.subnet_ids["MainSubnetA"]
      private_ip_list    = [local.hub1_vm_addr, ]
      security_group_ids = [module.hub1.ec2_security_group_id, ]
      dns_config         = { zone_name = local.region1_dns_zone, name = local.hub1_vm_hostname }
    }
  ]
  depends_on = [
    aws_ssm_parameter.netbox_admin_username,
    aws_ssm_parameter.netbox_admin_password,
    aws_ssm_parameter.netbox_admin_email,
    aws_ssm_parameter.postgresql_db_name,
    aws_ssm_parameter.postgresql_username,
    aws_ssm_parameter.postgresql_password,
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

output "bastion_public_ip" {
  value = module.hub1.bastion_public_ip
  depends_on = [
    module.hub1,
  ]
}

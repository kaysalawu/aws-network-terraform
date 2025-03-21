
####################################################
# netbox
####################################################

locals {
  netbox_init_dir = "/var/lib/cloudtuple/init"
  netbox_app_dir  = "/var/lib/cloudtuple/netbox"
  netbox_repo     = "https://github.com/netbox-community/netbox-docker.git"
  netbox_vars = {
    NETBOX_INIT_DIR = local.netbox_init_dir
    NETBOX_APP_DIR  = local.netbox_app_dir
    NETBOX_REPO     = local.netbox_repo
    NETBOX_PORT     = 80
  }
  netbox_init_files = {
    "${local.netbox_init_dir}/startup.sh" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/startup.sh", local.vm_init_vars) }
    "${local.netbox_init_dir}/docker.sh"  = { owner = "root", permissions = "0744", content = templatefile("scripts/netbox/docker.sh", local.netbox_vars) }
  }
  netbox_startup_init_files = {
    "${local.netbox_app_dir}/netbox.sh" = { owner = "root", permissions = "0744", content = templatefile("scripts/netbox/netbox.sh", local.netbox_vars) }
  }
}

module "netbox_cloud_init" {
  source = "../../modules/cloud-config-gen"
  files = merge(
    local.netbox_init_files,
    local.netbox_startup_init_files
  )
  run_commands = [
    ". ${local.netbox_init_dir}/startup.sh",
    ". ${local.netbox_init_dir}/docker.sh",
    ". ${local.netbox_app_dir}/netbox.sh",
  ]
}

####################################################
# workload
####################################################

module "netbox_vm" {
  source               = "../../modules/ec2"
  providers            = { aws = aws.region1 }
  name                 = "${local.hub1_prefix}netbox"
  availability_zone    = "${local.hub1_region}a"
  iam_instance_profile = module.common_region1.iam_instance_profile.name
  ami                  = var.ami_ids["netbox-community"]
  key_name             = module.common_region1.key_pair_name
  tags                 = local.hub1_tags

  root_block_device = {
    volume_size = 32
    volume_type = "gp2"
  }

  interfaces = [
    {
      name               = "${local.hub1_prefix}netbox-main"
      subnet_id          = module.hub1.subnet_ids["MainSubnetA"]
      security_group_ids = [module.hub1.ec2_security_group_id, ]
      create_eip         = true
    }
  ]
  depends_on = [
    time_sleep.hub1,
  ]
}

output "netbox_instance_id" {
  value = module.netbox_vm.instance_id
}

output "netbox_url" {
  value = "http://${module.netbox_vm.public_ip}:8000"
}

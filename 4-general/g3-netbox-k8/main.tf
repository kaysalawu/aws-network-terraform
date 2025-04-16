locals {
  vpc_name = "${local.hub1_prefix}-vpc"
  # ami_id               = module.ami.id
  teleport_sg          = "teleport_sg"
  prometheus_lb_cidr_1 = "172.22.13.0/24"
  prometheus_lb_cidr_2 = "172.22.14.0/24"
  service              = "${var.prefix}-k8"
  owner                = "platform-integrations"
  maintainer           = "platform-integrations"
  environment          = "shared-service"
}

data "aws_region" "default" {
  name = local.default_region
}


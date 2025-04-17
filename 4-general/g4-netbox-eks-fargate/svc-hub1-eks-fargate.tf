
locals {
  cluster_version = "1.32"
}

####################################################
# netbox-eks-fargate
####################################################

module "eks" {
  source = "../../modules/terraform-aws-eks"

  cluster_name    = "${local.hub1_prefix}eks-fargate"
  cluster_version = local.cluster_version

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  vpc_id = module.hub1.vpc_id
  subnet_ids = [
    module.hub1.subnet_ids["MainSubnetA"],
    module.hub1.subnet_ids["MainSubnetB"],
  ]
  control_plane_subnet_ids = [
    module.hub1.subnet_ids["ManagementSubnetA"],
    module.hub1.subnet_ids["ManagementSubnetB"],
  ]
}

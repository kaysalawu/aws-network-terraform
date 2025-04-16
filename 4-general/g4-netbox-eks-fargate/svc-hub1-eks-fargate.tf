
locals {
  cluster_version = "1.32"
}

####################################################
# EKS Module
####################################################

module "eks" {
  source = "../../modules/terraform-aws-eks-20.35.0"

  cluster_name    = local.name
  cluster_version = local.cluster_version

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  vpc_id = module.hub1.vpc_id
  subnets = [
    module.hub1.subnet_ids["MainSubnetA"],
    module.hub1.subnet_ids["MainSubnetB"],
  ]
  control_plane_subnet_ids = [
    module.hub1.subnet_ids["ManagementSubnetA"],
    module.hub1.subnet_ids["ManagementSubnetB"],
  ]

  fargate_profiles = {
    default = {
      name = "default"
      selectors = [
        {
          namespace = "kube-system"
          labels = {
            k8s-app = "kube-dns"
          }
        },
        {
          namespace = "default"
          labels = {
            WorkerType = "fargate"
          }
        }
      ]

      tags = {
        Owner = "default"
      }

      timeouts = {
        create = "20m"
        delete = "20m"
      }
    }

    secondary = {
      name = "secondary"
      selectors = [
        {
          namespace = "default"
          labels = {
            Environment = "test"
            GithubRepo  = "terraform-aws-eks"
            GithubOrg   = "terraform-aws-modules"
          }
        }
      ]

      # Using specific subnets instead of the ones configured in EKS (`subnets` and `fargate_subnets`)
      subnets = [module.vpc.private_subnets[1]]

      tags = {
        Owner = "secondary"
      }
    }
  }
}

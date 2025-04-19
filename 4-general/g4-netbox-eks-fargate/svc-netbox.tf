

# data "aws_availability_zones" "available" {}

locals {
  name            = "${local.hub1_prefix}-netbox"
  cluster_version = "1.29"
  # region          = "eu-west-1"

  # vpc_cidr = "10.0.0.0/16"
  # azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Example    = local.name
    GithubRepo = "terraform-aws-eks"
    GithubOrg  = "terraform-aws-modules"
  }
}

################################################################################
# netbox eks fargate cluster
################################################################################

# https://github.com/terraform-aws-modules/terraform-aws-eks/blob/v20.14.0/examples/fargate_profile/main.tf

module "netbox" {
  source = "../../modules/terraform-aws-eks"

  cluster_name                   = local.name
  cluster_version                = local.cluster_version
  cluster_endpoint_public_access = true

  cluster_addons = {
    kube-proxy = {}
    vpc-cni    = {}
    coredns = {
      configuration_values = jsonencode({
        computeType = "fargate"
      })
    }
  }

  vpc_id = module.hub1.vpc_id
  subnet_ids = [
    module.hub1.subnet_ids["MainSubnetA"],
    module.hub1.subnet_ids["MainSubnetB"],
  ]
  control_plane_subnet_ids = [
    module.hub1.subnet_ids["ManagementSubnetA"],
    module.hub1.subnet_ids["ManagementSubnetB"],
  ]

  # Fargate profiles use the cluster primary security group so these are not utilized
  create_cluster_security_group = false
  create_node_security_group    = false

  fargate_profile_defaults = {
    iam_role_additional_policies = {
      additional = aws_iam_policy.hub1_netbox_additional.arn
    }
  }

  fargate_profiles = {
    netbox = {
      name = "netbox"
      selectors = [
        {
          namespace = "netbox"
          labels = {
            app = "netbox"
          }
        },
        # {
        #   namespace = "backend"
        #   labels = {
        #     Application = "backend"
        #   }
        # },
        # {
        #   namespace = "app-*"
        #   labels = {
        #     Application = "app-wildcard"
        #   }
        # }
      ]

      # Using specific subnets instead of the subnets supplied for the cluster itself
      subnet_ids = [
        module.hub1.subnet_ids["MainSubnetA"],
        module.hub1.subnet_ids["MainSubnetB"],
      ]

      tags = {
        Owner = "secondary"
      }
    }
    kube-system = {
      selectors = [
        { namespace = "kube-system" }
      ]
    }
  }
  tags = local.hub1_tags
}

################################################################################
# Sub-Module Usage on Existing/Separate Cluster
################################################################################

# module "fargate_profile" {
#   source       = "../../modules/terraform-aws-eks/modules/fargate-profile"
#   name         = "separate-fargate-profile"
#   cluster_name = module.eks.cluster_name
#   subnet_ids   = module.vpc.private_subnets
#   selectors = [{
#     namespace = "kube-system"
#   }]
#   tags = merge(local.tags, { Separate = "fargate-profile" })
# }

# module "disabled_fargate_profile" {
#   source = "../../modules/terraform-aws-eks/modules/fargate-profile"
#   create = false
# }

################################################################################
# Supporting Resources
################################################################################

# module "vpc" {
#   source  = "terraform-aws-modules/vpc/aws"
#   version = "~> 5.0"

#   name = local.name
#   cidr = local.vpc_cidr

#   azs             = local.azs
#   private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
#   public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]
#   intra_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 52)]

#   enable_nat_gateway = true
#   single_nat_gateway = true

#   public_subnet_tags = {
#     "kubernetes.io/role/elb" = 1
#   }

#   private_subnet_tags = {
#     "kubernetes.io/role/internal-elb" = 1
#   }

#   tags = local.tags
# }

resource "aws_iam_policy" "hub1_netbox_additional" {
  name = "${local.hub1_prefix}-netbox-additional"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}



# data "aws_availability_zones" "available" {}

locals {
  name            = "${local.hub1_prefix}netbox"
  cluster_version = "1.29"
}

####################################################
# netbox eks fargate cluster
####################################################

# https://github.com/terraform-aws-modules/terraform-aws-eks/blob/v20.14.0/examples/fargate_profile/main.tf

module "netbox" {
  source = "../../modules/terraform-aws-eks"

  cluster_name                   = local.name
  cluster_version                = local.cluster_version
  cluster_endpoint_public_access = true
  create_iam_role                = true

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

# data "aws_iam_user" "kayodesalawu" {
#   user_name = "kayode.salawu@wise.com"
# }

# resource "aws_eks_access_entry" "kayodesalawu" {
#   cluster_name  = module.netbox.cluster_id
#   principal_arn = data.aws_iam_user.kayodesalawu.arn
#   type          = "STANDARD"
# }

# resource "aws_eks_access_policy_association" "kayodesalawu_AmazonEKSAdminPolicy" {
#   cluster_name  = module.netbox.cluster_id
#   policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
#   principal_arn = aws_eks_access_entry.kayodesalawu.principal_arn

#   access_scope {
#     type = "cluster"
#   }
# }

# resource "aws_eks_access_policy_association" "kayodesalawu_AmazonEKSClusterAdminPolicy" {
#   cluster_name  = module.netbox.cluster_id
#   policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
#   principal_arn = aws_eks_access_entry.kayodesalawu.principal_arn

#   access_scope {
#     type = "cluster"
#   }
# }

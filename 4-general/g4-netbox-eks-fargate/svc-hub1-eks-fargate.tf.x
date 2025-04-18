
locals {
  cluster_version = "1.32"
}

####################################################
# netbox-eks-fargate
####################################################

# module "netbox_eks" {
#   providers = { aws = aws.region1 }
#   source    = "../../modules/terraform-aws-eks"

#   cluster_name    = "${local.hub1_prefix}eks-fargate"
#   cluster_version = local.cluster_version

#   cluster_endpoint_private_access = true
#   cluster_endpoint_public_access  = true

#   vpc_id = module.hub1.vpc_id
#   subnet_ids = [
#     module.hub1.subnet_ids["MainSubnetA"],
#     module.hub1.subnet_ids["MainSubnetB"],
#   ]

#   control_plane_subnet_ids = [
#     module.hub1.subnet_ids["ManagementSubnetA"],
#     module.hub1.subnet_ids["ManagementSubnetB"],
#   ]

#   cluster_addons = {
#     kube-proxy = {}
#     vpc-cni    = {}
#     coredns = {
#       configuration_values = jsonencode({
#         computeType = "fargate"
#       })
#     }
#   }

#   fargate_profiles = {
#     name            = "netbox"
#     cluster_name    = "${local.hub1_prefix}eks-fargate"
#     create_iam_role = true
#     subnet_ids = [
#       module.hub1.subnet_ids["MainSubnetA"],
#       module.hub1.subnet_ids["MainSubnetB"],
#     ]
#   }
# }

# resource "aws_eks_fargate_profile" "example" {
#   cluster_name           = aws_eks_cluster.example.name
#   fargate_profile_name   = "example"
#   pod_execution_role_arn = aws_iam_role.example.arn
#   subnet_ids             = aws_subnet.example[*].id

#   selector {
#     namespace = "example"
#   }
# }

resource "aws_iam_policy" "hub1_eks_fargate_additional_policy" {
  name = "${local.hub1_prefix}-eks-fargate-additional-policy"
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

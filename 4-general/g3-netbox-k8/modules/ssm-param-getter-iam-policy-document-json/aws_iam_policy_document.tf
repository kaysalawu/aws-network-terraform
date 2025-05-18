data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  region     = data.aws_region.current.name
  account_id = data.aws_caller_identity.current.account_id

  resources = [
    for pn in var.parameter_names : "arn:aws:ssm:${local.region}:${local.account_id}:parameter/${pn}"
  ]
}

data "aws_iam_policy_document" "this" {
  statement {
    sid       = "SSMParametersPermissions"
    actions   = ["ssm:GetParameter", "ssm:GetParameters"]
    resources = local.resources
  }
}

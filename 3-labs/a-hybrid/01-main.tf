####################################################
# lab
####################################################

locals {
  eu_ecs_host  = "eu-docker.pkg.dev"
  us_ecs_host  = "us-docker.pkg.dev"
  eu_repo_name = ""
  us_repo_name = ""
  httpbin_port = 80

  hub_eu_fargate_httpbin_host = ""

  enable_ipv6 = false
}

####################################################
# common resources
####################################################

# aws ecr repositories

resource "aws_ecr_repository" "eu_repo" {
  name = "${local.hub_prefix}eu-repo"
}

resource "aws_ecr_repository" "us_repo" {
  name = "${local.hub_prefix}us-repo"
}


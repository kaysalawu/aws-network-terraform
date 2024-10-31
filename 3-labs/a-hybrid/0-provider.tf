
####################################################
# provider
####################################################

provider "aws" {
  region     = "eu-west-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_access_key
}

provider "random" {
}

####################################################
# backend
####################################################

# terraform {
#   backend "gcs" {
#     bucket = "tf-shk"
#     prefix = "states/aws/cloudtuple/1-vpc/eu-w1/vpc1"
#   }
# }


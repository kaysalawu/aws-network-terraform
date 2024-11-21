
####################################################
# elastic ip
####################################################

resource "aws_eip" "spoke1_nlb_eip_a" {
  provider = aws.region1
  domain   = "vpc"
  tags = {
    Name = "${local.spoke1_prefix}-nlb-eip-a"
  }
}

resource "aws_eip" "spoke1_nlb_eip_b" {
  provider = aws.region1
  domain   = "vpc"
  tags = {
    Name = "${local.spoke1_prefix}-nlb-eip-b"
  }
}

####################################################
# s3 bucket (logs)
####################################################

resource "aws_s3_bucket" "spoke1_nlb_logs" {
  provider      = aws.region1
  bucket        = replace("${local.spoke1_prefix}nlblogs", "-", "")
  force_destroy = true
  tags          = local.spoke1_tags
}

####################################################
# network load balancer
####################################################

module "spoke1_nlb" {
  source    = "../../modules/aws-lb"
  providers = { aws = aws.region1 }

  name               = "${local.spoke1_prefix}nlb"
  load_balancer_type = "network"
  vpc_id             = module.spoke1.vpc_id

  dns_record_client_routing_policy = "availability_zone_affinity"

  security_group_ids = [
    module.spoke1.elb_sg_id
  ]

  subnet_mapping = [
    { allocation_id = aws_eip.spoke1_nlb_eip_a.id, subnet_id = module.spoke1.subnet_ids["ExternalNLBSubnetA"] },
    { allocation_id = aws_eip.spoke1_nlb_eip_b.id, subnet_id = module.spoke1.subnet_ids["ExternalNLBSubnetB"] },
  ]

  access_logs = {
    enabled = false
    bucket  = aws_s3_bucket.spoke1_nlb_logs.id
    prefix  = "${local.spoke1_prefix}nlb"
  }

  connection_logs = {
    enabled = false
    bucket  = aws_s3_bucket.spoke1_nlb_logs.id
    prefix  = "${local.spoke1_prefix}nlb"
  }

  listeners = [
    {
      name = "neo4j-fe"
      port = 80

      protocol = "TCP"
      forward = {
        default      = true
        order        = 10
        target_group = "neo4j-be"
      }
      authenticate_cognito = {
        order               = 20
        user_pool_arn       = "arn:aws:cognito-idp:us-east-1:123412341234:userpool/us-east-1_123412341"
        user_pool_client_id = "user_pool_client_id"
        user_pool_domain    = "user_pool_domain"
      }
      authenticate_oidc = {
        order                  = 30
        authorization_endpoint = "https://example.com"
        client_id              = "client_id"
        client_secret          = "client_secret"
        issuer                 = "https://example.com"
        token_endpoint         = "https://example.com"
        user_info_endpoint     = "https://example.com"
      }
      fixed_response = {
        order        = 10
        status_code  = "200"
        content_type = "text/plain"
        message_body = "hello world"
      }

      # mutual_authentication = [{
      #   mode            = "passthrough"
      #   trust_store_arn = "arn:aws:acm:us-east-1:123412341234:certificate/12341234-1234-1234-1234-123412341234"
      # }]
    },
    # {
    #   name     = "neo4j-fe2"
    #   port     = 8080
    #   protocol = "TCP"
    # },
  ]

  target_groups = [
    {
      name         = "neo4j-be"
      protocol     = "TCP"
      port         = 80
      target       = { type = "instance", id = module.spoke1_vm.instance_id }
      vpc_id       = module.spoke1.vpc_id
      health_check = { path = "/healthz" }
    }
  ]

  tags = local.spoke1_tags
}

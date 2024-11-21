
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
      name     = "nlb-fe-80"
      port     = 80
      protocol = "TCP"
      forward = {
        default      = true
        order        = 10
        target_group = "nlb-be-80"
      }
    },
    {
      name     = "nlb-fe-8080"
      port     = 8080
      protocol = "TCP"
      forward = {
        default      = true
        target_group = "nlb-be-8080"
      }
    }
  ]

  target_groups = [
    {
      name         = "nlb-be-80"
      protocol     = "TCP"
      port         = 80
      target       = { type = "instance", id = module.spoke1_vm.instance_id }
      vpc_id       = module.spoke1.vpc_id
      health_check = { path = "/healthz" }
    },
    {
      name         = "nlb-be-8080"
      protocol     = "TCP"
      port         = 8080
      target       = { type = "instance", id = module.spoke1_vm.instance_id }
      vpc_id       = module.spoke1.vpc_id
      health_check = { path = "/healthz" }
    }
  ]

  tags = local.spoke1_tags
}

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


####################################################
# network load balancer
####################################################

module "spoke1_ext_alb" {
  source    = "../../modules/aws-lb"
  providers = { aws = aws.region1 }

  name               = "${local.spoke1_prefix}ext-alb"
  load_balancer_type = "application"
  vpc_id             = module.spoke1.vpc_id

  dns_record_client_routing_policy = "availability_zone_affinity"

  security_group_ids = [
    module.spoke1.elb_security_group_id
  ]

  subnets = [
    module.spoke1.subnet_ids["ExternalALBSubnetA"],
    module.spoke1.subnet_ids["ExternalALBSubnetB"],
  ]

  access_logs = {
    enabled = false
    bucket  = aws_s3_bucket.spoke1_ext_alb_logs.id
    prefix  = "${local.spoke1_prefix}ext-alb"
  }

  connection_logs = {
    enabled = false
    bucket  = aws_s3_bucket.spoke1_ext_alb_logs.id
    prefix  = "${local.spoke1_prefix}ext-alb"
  }

  listeners = [
    {
      name     = "ext-alb-fe-80"
      port     = 80
      protocol = "HTTP"
      forward = {
        default      = true
        order        = 10
        target_group = "ext-alb-be-80"
      }
    },
    {
      name     = "ext-alb-fe-8080"
      port     = 8080
      protocol = "HTTP"
      forward = {
        default      = true
        target_group = "ext-alb-be-8080"
      }
    }
  ]

  target_groups = [
    {
      name         = "ext-alb-be-80"
      protocol     = "HTTP"
      port         = 80
      target       = { type = "instance", id = module.spoke1_vm.instance_id }
      vpc_id       = module.spoke1.vpc_id
      health_check = { path = "/healthz" }
    },
    {
      name         = "ext-alb-be-8080"
      protocol     = "HTTP"
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

resource "aws_eip" "spoke1_ext_alb_eip_a" {
  provider = aws.region1
  domain   = "vpc"
  tags = {
    Name = "${local.spoke1_prefix}ext-alb-eip-a"
  }
}

resource "aws_eip" "spoke1_ext_alb_eip_b" {
  provider = aws.region1
  domain   = "vpc"
  tags = {
    Name = "${local.spoke1_prefix}ext-alb-eip-b"
  }
}

####################################################
# s3 bucket (logs)
####################################################

resource "aws_s3_bucket" "spoke1_ext_alb_logs" {
  provider      = aws.region1
  bucket        = replace("${local.spoke1_prefix}extalblogs", "-", "")
  force_destroy = true
  tags          = local.spoke1_tags
}

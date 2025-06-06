
####################################################
# network load balancer
####################################################

module "spoke3_ext_nlb" {
  source    = "../../modules/aws-lb"
  providers = { aws = aws.region1 }

  name               = "${local.spoke3_prefix}ext-nlb"
  load_balancer_type = "network"
  vpc_id             = module.spoke3.vpc_id

  dns_record_client_routing_policy = "availability_zone_affinity"

  security_group_ids = [
    module.spoke3.elb_security_group_id
  ]

  subnet_mapping = [
    { allocation_id = aws_eip.spoke3_ext_nlb_eip_a.id, subnet_id = module.spoke3.subnet_ids["ExternalNLBSubnetA"] },
    { allocation_id = aws_eip.spoke3_ext_nlb_eip_b.id, subnet_id = module.spoke3.subnet_ids["ExternalNLBSubnetB"] },
  ]

  access_logs = {
    enabled = false
    bucket  = aws_s3_bucket.spoke3_ext_nlb_logs.id
    prefix  = "${local.spoke3_prefix}ext-nlb"
  }

  connection_logs = {
    enabled = false
    bucket  = aws_s3_bucket.spoke3_ext_nlb_logs.id
    prefix  = "${local.spoke3_prefix}ext-nlb"
  }

  listeners = [
    {
      name     = "ext-nlb-fe-80"
      port     = 80
      protocol = "TCP"
      forward = {
        default      = true
        order        = 10
        target_group = "ext-nlb-be-80"
      }
    },
    {
      name     = "ext-nlb-fe-8080"
      port     = 8080
      protocol = "TCP"
      forward = {
        default      = true
        target_group = "ext-nlb-be-8080"
      }
    }
  ]

  target_groups = [
    {
      name         = "ext-nlb-be-80"
      protocol     = "TCP"
      port         = 80
      target       = { type = "instance", id = module.spoke3_vm.instance_id }
      vpc_id       = module.spoke3.vpc_id
      health_check = { path = "/healthz" }
    },
    {
      name         = "ext-nlb-be-8080"
      protocol     = "TCP"
      port         = 8080
      target       = { type = "instance", id = module.spoke3_vm.instance_id }
      vpc_id       = module.spoke3.vpc_id
      health_check = { path = "/healthz" }
    }
  ]

  # route53_records = [{
  #   zone_id = aws_route53_zone.region1.zone_id
  #   name    = "spoke3-ext-nlb.${data.aws_route53_zone.public.name}"
  # }]

  tags = local.spoke3_tags
}

####################################################
# elastic ip
####################################################

resource "aws_eip" "spoke3_ext_nlb_eip_a" {
  provider = aws.region1
  domain   = "vpc"
  tags = {
    Name = "${local.spoke3_prefix}ext-nlb-eip-a"
  }
}

resource "aws_eip" "spoke3_ext_nlb_eip_b" {
  provider = aws.region1
  domain   = "vpc"
  tags = {
    Name = "${local.spoke3_prefix}ext-nlb-eip-b"
  }
}

####################################################
# s3 bucket (logs)
####################################################

resource "aws_s3_bucket" "spoke3_ext_nlb_logs" {
  provider      = aws.region1
  bucket        = replace("${local.spoke3_prefix}extnlblogs", "-", "")
  force_destroy = true
  tags          = local.spoke3_tags
}

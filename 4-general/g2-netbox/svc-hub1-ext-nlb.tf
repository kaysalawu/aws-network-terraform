
####################################################
# network load balancer
####################################################

module "hub1_ext_nlb" {
  source    = "../../modules/aws-lb"
  providers = { aws = aws.region1 }

  name               = "${local.hub1_prefix}ext-nlb"
  load_balancer_type = "network"
  vpc_id             = module.hub1.vpc_id

  dns_record_client_routing_policy = "availability_zone_affinity"

  security_group_ids = [
    module.hub1.elb_security_group_id
  ]

  subnet_mapping = [
    { allocation_id = aws_eip.hub1_ext_nlb_eip_a.id, subnet_id = module.hub1.subnet_ids["ExternalNLBSubnetA"] },
    { allocation_id = aws_eip.hub1_ext_nlb_eip_b.id, subnet_id = module.hub1.subnet_ids["ExternalNLBSubnetB"] },
  ]

  access_logs = {
    enabled = false
    bucket  = aws_s3_bucket.hub1_ext_nlb_logs.id
    prefix  = "${local.hub1_prefix}ext-nlb"
  }

  connection_logs = {
    enabled = false
    bucket  = aws_s3_bucket.hub1_ext_nlb_logs.id
    prefix  = "${local.hub1_prefix}ext-nlb"
  }

  listeners = [
    {
      name     = "ext-nlb-fe-8000"
      port     = 80
      protocol = "TCP"
      forward = {
        default      = true
        order        = 10
        target_group = "ext-nlb-be-8000"
      }
    },
  ]

  target_groups = [
    {
      name     = "ext-nlb-be-8000"
      protocol = "TCP"
      port     = 8000
      target   = { type = "instance", id = module.hub1_vm.instance_id }
      vpc_id   = module.hub1.vpc_id
    },
  ]

  tags = local.hub1_tags
}

####################################################
# elastic ip
####################################################

resource "aws_eip" "hub1_ext_nlb_eip_a" {
  provider = aws.region1
  domain   = "vpc"
  tags = {
    Name = "${local.hub1_prefix}ext-nlb-eip-a"
  }
}

resource "aws_eip" "hub1_ext_nlb_eip_b" {
  provider = aws.region1
  domain   = "vpc"
  tags = {
    Name = "${local.hub1_prefix}ext-nlb-eip-b"
  }
}

####################################################
# dns
####################################################

resource "aws_route53_record" "hub1_ext_nlb" {
  provider = aws.region1
  zone_id  = data.aws_route53_zone.public.zone_id
  name     = "netbox.${data.aws_route53_zone.public.name}"
  type     = "A"
  ttl      = 300
  records = [
    aws_eip.hub1_ext_nlb_eip_a.public_ip,
    aws_eip.hub1_ext_nlb_eip_b.public_ip,
  ]
}

####################################################
# s3 bucket (logs)
####################################################

resource "aws_s3_bucket" "hub1_ext_nlb_logs" {
  provider      = aws.region1
  bucket        = replace("${local.hub1_prefix}extnlblogs", "-", "")
  force_destroy = true
  tags          = local.hub1_tags
}

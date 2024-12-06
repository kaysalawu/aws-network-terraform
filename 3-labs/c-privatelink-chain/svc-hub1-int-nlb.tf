
####################################################
# network load balancer
####################################################

locals {
  hub1_ep1 = [for config in aws_vpc_endpoint.spoke1_int_nlb_hub1.subnet_configuration : config.ipv4][0]
  hub1_ep2 = [for config in aws_vpc_endpoint.spoke1_int_nlb_hub1.subnet_configuration : config.ipv4][1]
}

module "hub1_int_nlb" {
  source    = "../../modules/aws-lb"
  providers = { aws = aws.region1 }

  name               = "${local.hub1_prefix}int-nlb"
  load_balancer_type = "network"
  vpc_id             = module.hub1.vpc_id
  ip_address_type    = local.enable_ipv6 ? "dualstack" : "ipv4"
  internal           = true

  dns_record_client_routing_policy = "availability_zone_affinity"

  security_group_ids = [
    module.hub1.elb_sg_id
  ]

  subnet_mapping = [
    { private_ipv4_address = local.hub1_int_nlb_addr_a, subnet_id = module.hub1.subnet_ids["InternalNLBSubnetA"] },
    { private_ipv4_address = local.hub1_int_nlb_addr_b, subnet_id = module.hub1.subnet_ids["InternalNLBSubnetB"] },
  ]

  access_logs = {
    enabled = false
    bucket  = aws_s3_bucket.hub1_int_nlb_logs.id
    prefix  = "${local.hub1_prefix}int-nlb"
  }

  connection_logs = {
    enabled = false
    bucket  = aws_s3_bucket.hub1_int_nlb_logs.id
    prefix  = "${local.hub1_prefix}int-nlb"
  }

  listeners = [
    {
      name     = "${local.hub1_prefix}int-nlb-fe-80"
      port     = 80
      protocol = "TCP"
      forward = {
        default      = true
        order        = 10
        target_group = "${local.hub1_prefix}int-nlb-be-80"
      }
    },
    {
      name     = "${local.hub1_prefix}int-nlb-fe-8080"
      port     = 8080
      protocol = "TCP"
      forward = {
        default      = true
        target_group = "${local.hub1_prefix}int-nlb-be-8080"
      }
    }
  ]

  target_groups = [
    {
      name         = "${local.hub1_prefix}int-nlb-be-80"
      protocol     = "TCP"
      port         = 80
      target       = { type = "ip", id = local.hub1_ep1 }
      vpc_id       = module.hub1.vpc_id
      health_check = { path = "/healthz" }
    },
    {
      name         = "${local.hub1_prefix}int-nlb-be-8080"
      protocol     = "TCP"
      port         = 8080
      target       = { type = "ip", id = local.hub1_ep2 }
      vpc_id       = module.hub1.vpc_id
      health_check = { path = "/healthz" }
    }
  ]

  endpoint_service = {
    enabled          = true
    private_dns_name = "${local.hub1_prefix}int-nlb.${data.aws_route53_zone.public.name}"
  }

  route53_records = [{
    zone_id = aws_route53_zone.region1.zone_id
    name    = "hub1-int-nlb"
  }]

  tags = local.hub1_tags
}

####################################################
# vpc endpoint
####################################################

# branch1

resource "aws_vpc_endpoint" "branch1_int_nlb_hub1" {
  provider          = aws.region1
  vpc_id            = module.branch1.vpc_id
  service_name      = module.hub1_int_nlb.endpoint_service_name
  auto_accept       = true
  vpc_endpoint_type = "Interface"
  subnet_ids = [
    module.branch1.subnet_ids["EndpointSubnetA"],
    module.branch1.subnet_ids["EndpointSubnetB"],
  ]
  security_group_ids = [
    module.branch1.ec2_sg_id
  ]
  tags = merge(local.branch1_tags, {
    "Name" = "${local.branch1_prefix}int-nlb-hub1"
  })
}

####################################################
# dns
####################################################

# nlb

resource "aws_route53_record" "branch1_int_nlb" {
  provider = aws.region1
  zone_id  = aws_route53_zone.region1.zone_id
  name     = local.hub1_int_nlb_hostname
  type     = "A"
  ttl      = "60"
  records = [
    local.hub1_int_nlb_addr_a,
    local.hub1_int_nlb_addr_b,
  ]
}

resource "aws_route53_record" "branch1_int_nlb_hub1_pep" {
  provider = aws.region1
  zone_id  = aws_route53_zone.region1.zone_id
  name     = "hub1pls.${local.hub1_dns_zone}"
  type     = "A"
  ttl      = "60"
  records  = [for v in aws_vpc_endpoint.branch1_int_nlb_hub1.subnet_configuration : v.ipv4]
}

####################################################
# s3 bucket (logs)
####################################################

resource "aws_s3_bucket" "hub1_int_nlb_logs" {
  provider      = aws.region1
  bucket        = replace("${local.hub1_prefix}intnlblogs", "-", "")
  force_destroy = true
  tags          = local.hub1_tags
}

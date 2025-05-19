
####################################################
# network load balancer
####################################################

module "spoke3_int_nlb" {
  source    = "../../modules/aws-lb"
  providers = { aws = aws.region1 }

  name               = "${local.spoke3_prefix}int-nlb"
  load_balancer_type = "network"
  vpc_id             = module.spoke3.vpc_id
  ip_address_type    = local.enable_ipv6 ? "dualstack" : "ipv4"
  internal           = true

  dns_record_client_routing_policy = "availability_zone_affinity"

  security_group_ids = [
    module.spoke3.elb_security_group_id
  ]

  subnet_mapping = [
    { private_ipv4_address = local.spoke3_int_nlb_addr_a, subnet_id = module.spoke3.subnet_ids["InternalNLBSubnetA"] },
    { private_ipv4_address = local.spoke3_int_nlb_addr_b, subnet_id = module.spoke3.subnet_ids["InternalNLBSubnetB"] },
  ]

  access_logs = {
    enabled = false
    bucket  = aws_s3_bucket.spoke3_int_nlb_logs.id
    prefix  = "${local.spoke3_prefix}int-nlb"
  }

  connection_logs = {
    enabled = false
    bucket  = aws_s3_bucket.spoke3_int_nlb_logs.id
    prefix  = "${local.spoke3_prefix}int-nlb"
  }

  listeners = [
    {
      name     = "int-nlb-fe-80"
      port     = 80
      protocol = "TCP"
      forward = {
        default      = true
        order        = 10
        target_group = "int-nlb-be-80"
      }
    },
    {
      name     = "int-nlb-fe-8080"
      port     = 8080
      protocol = "TCP"
      forward = {
        default      = true
        target_group = "int-nlb-be-8080"
      }
    }
  ]

  target_groups = [
    {
      name         = "int-nlb-be-80"
      protocol     = "TCP"
      port         = 80
      target       = { type = "instance", id = module.spoke3_vm.instance_id }
      vpc_id       = module.spoke3.vpc_id
      health_check = { path = "/healthz" }
    },
    {
      name         = "int-nlb-be-8080"
      protocol     = "TCP"
      port         = 8080
      target       = { type = "instance", id = module.spoke3_vm.instance_id }
      vpc_id       = module.spoke3.vpc_id
      health_check = { path = "/healthz" }
    }
  ]

  endpoint_service = {
    enabled          = true
    private_dns_name = "${local.spoke3_prefix}int-nlb.${aws_route53_zone.region1.name}"
  }

  route53_records = [{
    zone_id = aws_route53_zone.region1.zone_id
    name    = "spoke3-int-nlb"
  }]

  tags = local.spoke3_tags
}

####################################################
# vpc endpoint
####################################################

# hub1

resource "aws_vpc_endpoint" "spoke3_int_nlb_hub1" {
  provider          = aws.region1
  vpc_id            = module.hub1.vpc_id
  service_name      = module.spoke3_int_nlb.endpoint_service_name
  auto_accept       = true
  vpc_endpoint_type = "Interface"
  subnet_ids = [
    module.hub1.subnet_ids["EndpointSubnetA"],
    module.hub1.subnet_ids["EndpointSubnetB"],
  ]
  security_group_ids = [
    module.hub1.ec2_security_group_id
  ]
}

# hub1
## dummy for testing multiple endpoint associations to same service

resource "aws_vpc_endpoint" "spoke3_int_nlb_hub1_dummy" {
  provider          = aws.region1
  vpc_id            = module.hub1.vpc_id
  service_name      = module.spoke3_int_nlb.endpoint_service_name
  auto_accept       = true
  vpc_endpoint_type = "Interface"
  subnet_ids = [
    module.hub1.subnet_ids["EndpointSubnetA"],
    module.hub1.subnet_ids["EndpointSubnetB"],
  ]
  security_group_ids = [
    module.hub1.ec2_security_group_id
  ]
}

####################################################
# dns
####################################################

# nlb

resource "aws_route53_record" "spoke3_int_nlb" {
  provider = aws.region1
  zone_id  = aws_route53_zone.region1.zone_id
  name     = local.hub1_int_nlb_hostname
  type     = "A"
  ttl      = "60"
  records = [
    local.spoke3_int_nlb_addr_a,
    local.spoke3_int_nlb_addr_b,
  ]
}

# endpoint (hub1)

resource "aws_route53_record" "spoke3_int_nlb_hub1_pep" {
  provider = aws.region1
  zone_id  = aws_route53_zone.region1.zone_id
  name     = local.hub1_spoke3_pep_fqdn
  type     = "A"
  ttl      = "60"
  records  = [for v in aws_vpc_endpoint.spoke3_int_nlb_hub1.subnet_configuration : v.ipv4]
}

####################################################
# s3 bucket (logs)
####################################################

resource "aws_s3_bucket" "spoke3_int_nlb_logs" {
  provider      = aws.region1
  bucket        = replace("${local.spoke3_prefix}intnlblogs", "-", "")
  force_destroy = true
  tags          = local.spoke3_tags
}

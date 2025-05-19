
####################################################
# network load balancer
####################################################

module "spoke6_int_nlb" {
  source    = "../../modules/aws-lb"
  providers = { aws = aws.region2 }

  name               = "${local.spoke6_prefix}int-nlb"
  load_balancer_type = "network"
  vpc_id             = module.spoke6.vpc_id
  ip_address_type    = local.enable_ipv6 ? "dualstack" : "ipv4"
  internal           = true

  dns_record_client_routing_policy = "availability_zone_affinity"

  security_group_ids = [
    module.spoke6.elb_security_group_id
  ]

  subnet_mapping = [
    { private_ipv4_address = local.spoke6_int_nlb_addr_a, subnet_id = module.spoke6.subnet_ids["InternalNLBSubnetA"] },
    { private_ipv4_address = local.spoke6_int_nlb_addr_b, subnet_id = module.spoke6.subnet_ids["InternalNLBSubnetB"] },
  ]

  access_logs = {
    enabled = false
    bucket  = aws_s3_bucket.spoke6_int_nlb_logs.id
    prefix  = "${local.spoke6_prefix}int-nlb"
  }

  connection_logs = {
    enabled = false
    bucket  = aws_s3_bucket.spoke6_int_nlb_logs.id
    prefix  = "${local.spoke6_prefix}int-nlb"
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
      target       = { type = "instance", id = module.spoke6_vm.instance_id }
      vpc_id       = module.spoke6.vpc_id
      health_check = { path = "/healthz" }
    },
    {
      name         = "int-nlb-be-8080"
      protocol     = "TCP"
      port         = 8080
      target       = { type = "instance", id = module.spoke6_vm.instance_id }
      vpc_id       = module.spoke6.vpc_id
      health_check = { path = "/healthz" }
    }
  ]

  endpoint_service = {
    enabled          = true
    private_dns_name = "${local.spoke6_prefix}int-nlb.${aws_route53_zone.region2.name}"
  }

  route53_records = [{
    zone_id = aws_route53_zone.region2.zone_id
    name    = "spoke6-int-nlb"
  }]

  tags = local.spoke6_tags
}

####################################################
# vpc endpoint
####################################################

# hub2

resource "aws_vpc_endpoint" "spoke6_int_nlb_hub2" {
  provider          = aws.region2
  vpc_id            = module.hub2.vpc_id
  service_name      = module.spoke6_int_nlb.endpoint_service_name
  auto_accept       = true
  vpc_endpoint_type = "Interface"
  subnet_ids = [
    module.hub2.subnet_ids["EndpointSubnetA"],
    module.hub2.subnet_ids["EndpointSubnetB"],
  ]
  security_group_ids = [
    module.hub2.ec2_security_group_id
  ]
}

# hub2
## dummy for testing multiple endpoint associations to same service

resource "aws_vpc_endpoint" "spoke6_int_nlb_hub2_dummy" {
  provider          = aws.region2
  vpc_id            = module.hub2.vpc_id
  service_name      = module.spoke6_int_nlb.endpoint_service_name
  auto_accept       = true
  vpc_endpoint_type = "Interface"
  subnet_ids = [
    module.hub2.subnet_ids["EndpointSubnetA"],
    module.hub2.subnet_ids["EndpointSubnetB"],
  ]
  security_group_ids = [
    module.hub2.ec2_security_group_id
  ]
}

####################################################
# dns
####################################################

# nlb

resource "aws_route53_record" "spoke6_int_nlb" {
  provider = aws.region2
  zone_id  = aws_route53_zone.region2.zone_id
  name     = local.hub2_int_nlb_hostname
  type     = "A"
  ttl      = "60"
  records = [
    local.spoke6_int_nlb_addr_a,
    local.spoke6_int_nlb_addr_b,
  ]
}

# endpoint (hub2)

resource "aws_route53_record" "spoke6_int_nlb_hub2_pep" {
  provider = aws.region2
  zone_id  = aws_route53_zone.region2.zone_id
  name     = local.hub2_spoke6_pep_fqdn
  type     = "A"
  ttl      = "60"
  records  = [for v in aws_vpc_endpoint.spoke6_int_nlb_hub2.subnet_configuration : v.ipv4]
}

####################################################
# s3 bucket (logs)
####################################################

resource "aws_s3_bucket" "spoke6_int_nlb_logs" {
  provider      = aws.region2
  bucket        = replace("${local.spoke6_prefix}intnlblogs", "-", "")
  force_destroy = true
  tags          = local.spoke6_tags
}

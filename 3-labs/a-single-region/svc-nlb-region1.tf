
resource "aws_eip" "spoke1_nlb" {
  provider = aws.region1
  domain   = "vpc"
  tags = {
    Name = "${local.spoke1_prefix}-nlb-eip"
  }
}

module "spoke1_nlb" {
  source    = "../../modules/aws-lb"
  providers = { aws = aws.region1 }

  name               = "${local.spoke1_prefix}-nlb"
  load_balancer_type = "network"
  vpc_id             = module.spoke1.vpc_id

  dns_record_client_routing_policy = "availability_zone_affinity"

  subnet_mapping = [{
    allocation_id = aws_eip.spoke1_nlb.id
    subnet_id     = module.spoke1.subnet_ids["LoadBalancerSubnet"]
  }]

  #   # For example only
  #   enable_deletion_protection = false

  #   # Security Group
  #   enforce_security_group_inbound_rules_on_private_link_traffic = "off"
  #   security_group_ingress_rules = {
  #     all_tcp = {
  #       from_port   = 80
  #       to_port     = 84
  #       ip_protocol = "tcp"
  #       description = "TCP traffic"
  #       cidr_ipv4   = "0.0.0.0/0"
  #     }
  #     all_udp = {
  #       from_port   = 80
  #       to_port     = 84
  #       ip_protocol = "udp"
  #       description = "UDP traffic"
  #       cidr_ipv4   = "0.0.0.0/0"
  #     }
  #   }
  #   security_group_egress_rules = {
  #     all = {
  #       ip_protocol = "-1"
  #       cidr_ipv4   = module.vpc.vpc_cidr_block
  #     }
  #   }

  #   listeners = {
  #     ex-one = {
  #       port     = 81
  #       protocol = "TCP_UDP"
  #       forward = {
  #         target_group_key = "ex-target-one"
  #       }
  #     }

  #     ex-two = {
  #       port     = 82
  #       protocol = "UDP"
  #       forward = {
  #         target_group_key = "ex-target-two"
  #       }
  #     }

  #     ex-three = {
  #       port                     = 83
  #       protocol                 = "TCP"
  #       tcp_idle_timeout_seconds = 60
  #       forward = {
  #         target_group_key = "ex-target-three"
  #       }
  #     }

  #     ex-four = {
  #       port            = 84
  #       protocol        = "TLS"
  #       certificate_arn = module.acm.acm_certificate_arn
  #       forward = {
  #         target_group_key = "ex-target-four"
  #       }
  #     }
  #   }

  #   target_groups = {
  #     ex-target-one = {
  #       name_prefix            = "t1-"
  #       protocol               = "TCP_UDP"
  #       port                   = 81
  #       target_type            = "instance"
  #       target_id              = aws_instance.this.id
  #       connection_termination = true
  #       preserve_client_ip     = true

  #       stickiness = {
  #         type = "source_ip"
  #       }

  #       tags = {
  #         tcp_udp = true
  #       }
  #     }

  #     ex-target-two = {
  #       name_prefix = "t2-"
  #       protocol    = "UDP"
  #       port        = 82
  #       target_type = "instance"
  #       target_id   = aws_instance.this.id
  #     }

  #     ex-target-three = {
  #       name_prefix          = "t3-"
  #       protocol             = "TCP"
  #       port                 = 83
  #       target_type          = "ip"
  #       target_id            = aws_instance.this.private_ip
  #       deregistration_delay = 10
  #       health_check = {
  #         enabled             = true
  #         interval            = 30
  #         path                = "/healthz"
  #         port                = "traffic-port"
  #         healthy_threshold   = 3
  #         unhealthy_threshold = 3
  #         timeout             = 6
  #       }
  #     }

  #     ex-target-four = {
  #       name_prefix = "t4-"
  #       protocol    = "TLS"
  #       port        = 84
  #       target_type = "instance"
  #       target_id   = aws_instance.this.id
  #       target_health_state = {
  #         enable_unhealthy_connection_termination = false
  #         unhealthy_draining_interval             = 600
  #       }
  #     }
  #   }

  #   tags = local.tags
}

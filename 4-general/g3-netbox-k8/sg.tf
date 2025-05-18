resource "aws_security_group" "secure" {
  name   = "k8-secure"
  vpc_id = module.hub1.vpc_id
  tags = {
    "kubernetes.io/cluster/${local.service}" = "shared"
  }
}

# resource "aws_security_group_rule" "secure_allow_incomming_node_exporter" {
#   description       = "Allow incoming node exporter"
#   security_group_id = aws_security_group.secure.id
#   protocol          = "TCP"
#   type              = "ingress"
#   from_port         = "9100"
#   to_port           = "9100"
#   cidr_blocks       = [local.prometheus_lb_cidr_1, local.prometheus_lb_cidr_2]
# }

resource "aws_security_group_rule" "secure_allow_outgoing_https" {
  description       = "Allow outgoing https access"
  security_group_id = aws_security_group.secure.id
  protocol          = "TCP"
  type              = "egress"
  from_port         = "443"
  to_port           = "443"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "secure_allow_outgoing_ssh" {
  description       = "Allow outgoing ssh access"
  security_group_id = aws_security_group.secure.id
  protocol          = "TCP"
  type              = "egress"
  from_port         = "22"
  to_port           = "22"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "interface_egress_http" {
  description       = "Allow outgoing http access for CodeDeploy"
  security_group_id = aws_security_group.secure.id
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "interface_egress_github_ssh" {
  description       = "Allow outgoing ssh access to github"
  security_group_id = aws_security_group.secure.id
  from_port         = 0
  to_port           = 0
  protocol          = "tcp"
  type              = "egress"
  cidr_blocks       = data.github_ip_ranges.github_ip_cidrs.git_ipv4
}

data "github_ip_ranges" "github_ip_cidrs" {
}

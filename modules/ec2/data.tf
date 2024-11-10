
data "aws_route53_zone" "private" {
  for_each     = { for interface in var.interfaces : interface.name => interface if interface.dns_config.zone_name != null && !interface.dns_config.public }
  name         = each.value.dns_config.zone_name
  private_zone = true
}

data "aws_route53_zone" "public" {
  for_each     = { for interface in var.interfaces : interface.name => interface if interface.dns_config.zone_name != null && interface.dns_config.public }
  name         = each.value.dns_config.zone_name
  private_zone = false
}

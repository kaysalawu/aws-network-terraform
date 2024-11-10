
data "aws_route53_zone" "this" {
  for_each     = { for interface in var.interfaces : interface.name => interface if interface.dns_config.zone_name != null }
  name         = each.value.dns_config.zone_name
  private_zone = true
}

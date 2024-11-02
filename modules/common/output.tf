
output "bucket" {
  value = aws_s3_bucket.bucket
}

output "iam_instance_profile" {
  value = aws_iam_instance_profile.ec2_instance_profile
}

output "ipam_id" {
  value = aws_vpc_ipam.this.id
}

output "ipv4_ipam_pool_id" {
  value = { for k, v in aws_vpc_ipam_pool.ipam_scope_id_ipv4 : k => v.id }
}

output "ipv6_ipam_pool_id" {
  value = { for k, v in aws_vpc_ipam_pool.ipam_scope_id_ipv6 : k => v.id }
}

output "key_pair_name" {
  value = { for k, v in aws_key_pair.this : k => v.key_name }
}

# output "log_analytics_workspaces" {
#   value = azurerm_log_analytics_workspace.log_analytics_workspaces
# }

# output "nsg_default" {
#   value = azurerm_network_security_group.nsg_default
# }

# output "nsg_main" {
#   value = azurerm_network_security_group.nsg_main
# }

# output "nsg_aks" {
#   value = azurerm_network_security_group.nsg_aks
# }

# output "nsg_nva" {
#   value = azurerm_network_security_group.nsg_nva
# }

# output "nsg_lb" {
#   value = azurerm_network_security_group.nsg_lb
# }

# output "private_dns_zones" {
#   value = azurerm_private_dns_zone.private_dns_zones
# }

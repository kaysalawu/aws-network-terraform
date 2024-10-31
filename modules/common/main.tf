
locals {
  prefix       = var.prefix == "" ? "" : format("%s-", var.prefix)
  my_public_ip = chomp(data.http.my_public_ip.response_body)
}

data "http" "my_public_ip" {
  url = "http://ipv4.icanhazip.com"
}

####################################################
# log analytics workspace
####################################################



####################################################
# private dns zone
####################################################



####################################################
# s3
####################################################



####################################################
# nsg
####################################################

# default
#----------------------------

# resource "azurerm_network_security_group" "nsg_default" {
#   for_each            = var.regions
#   resource_group_name = var.resource_group
#   name                = "${local.prefix}nsg-${each.key}-default"
#   location            = each.value.name
#   tags                = var.tags
# }

# main
#----------------------------

# resource "azurerm_network_security_group" "nsg_main" {
#   for_each            = var.regions
#   resource_group_name = var.resource_group
#   name                = "${local.prefix}nsg-${each.key}-main"
#   location            = each.value.name
#   tags                = var.tags
# }

# resource "azurerm_network_security_rule" "nsg_main_private_inbound" {
#   for_each                    = var.regions
#   resource_group_name         = var.resource_group
#   network_security_group_name = azurerm_network_security_group.nsg_main[each.key].name
#   name                        = "private-inbound"
#   direction                   = "Inbound"
#   access                      = "Allow"
#   priority                    = 100
#   source_address_prefixes     = var.private_prefixes
#   source_port_range           = "*"
#   destination_address_prefix  = "*"
#   destination_port_range      = "*"
#   protocol                    = "*"
#   description                 = "Allow all private prefixes"
# }

# resource "azurerm_network_security_rule" "nsg_main_private_inbound_v6" {
#   for_each                    = var.regions
#   resource_group_name         = var.resource_group
#   network_security_group_name = azurerm_network_security_group.nsg_main[each.key].name
#   name                        = "private-inbound-v6"
#   direction                   = "Inbound"
#   access                      = "Allow"
#   priority                    = 105
#   source_address_prefixes     = var.private_prefixes_v6
#   source_port_range           = "*"
#   destination_address_prefix  = "*"
#   destination_port_range      = "*"
#   protocol                    = "*"
#   description                 = "Allow all private prefixes"
# }

# resource "azurerm_network_security_rule" "nsg_main_private_outbound" {
#   for_each                    = var.regions
#   resource_group_name         = var.resource_group
#   network_security_group_name = azurerm_network_security_group.nsg_main[each.key].name
#   name                        = "all-outbound"
#   direction                   = "Outbound"
#   access                      = "Allow"
#   priority                    = 100
#   source_address_prefix       = "*"
#   source_port_range           = "*"
#   destination_address_prefix  = "*"
#   destination_port_range      = "*"
#   protocol                    = "*"
#   description                 = "Allow all outbound"
# }

# resource "azurerm_network_security_rule" "nsg_main_internet_inbound" {
#   for_each                    = var.regions
#   resource_group_name         = var.resource_group
#   network_security_group_name = azurerm_network_security_group.nsg_main[each.key].name
#   name                        = "internet-inbound"
#   direction                   = "Inbound"
#   access                      = "Allow"
#   priority                    = 120
#   source_address_prefix       = "*"
#   source_port_range           = "*"
#   destination_address_prefix  = "*"
#   destination_port_ranges     = ["80", "443", "8080", "8081", "3000", ]
#   protocol                    = "Tcp"
#   description                 = "Allow inbound web traffic"
# }

# resource "azurerm_network_security_rule" "nsg_main_internet_inbound_ipv6" {
#   for_each                     = var.regions
#   resource_group_name          = var.resource_group
#   network_security_group_name  = azurerm_network_security_group.nsg_main[each.key].name
#   name                         = "internet-inbound-self-ipv6"
#   direction                    = "Inbound"
#   access                       = "Allow"
#   priority                     = 130
#   source_address_prefixes      = ["::/0"]
#   source_port_range            = "*"
#   destination_address_prefixes = ["::/0"]
#   destination_port_ranges      = ["80", "443", "8080", "8081", "3000"]
#   protocol                     = "Tcp"
#   description                  = "Allow inbound web traffic over IPv6"
# }


# aks
#----------------------------

# resource "azurerm_network_security_group" "nsg_aks" {
#   for_each            = var.regions
#   resource_group_name = var.resource_group
#   name                = "${local.prefix}nsg-${each.key}-aks"
#   location            = each.value.name
#   tags                = var.tags
# }

# resource "azurerm_network_security_rule" "nsg_aks_private_inbound" {
#   for_each                    = var.regions
#   resource_group_name         = var.resource_group
#   network_security_group_name = azurerm_network_security_group.nsg_aks[each.key].name
#   name                        = "private-inbound"
#   direction                   = "Inbound"
#   access                      = "Allow"
#   priority                    = 100
#   source_address_prefixes     = var.private_prefixes
#   source_port_range           = "*"
#   destination_address_prefix  = "*"
#   destination_port_range      = "*"
#   protocol                    = "*"
#   description                 = "Allow all private prefixes"
# }

# resource "azurerm_network_security_rule" "nsg_aks_private_inbound_v6" {
#   for_each                    = var.regions
#   resource_group_name         = var.resource_group
#   network_security_group_name = azurerm_network_security_group.nsg_aks[each.key].name
#   name                        = "private-inbound-v6"
#   direction                   = "Inbound"
#   access                      = "Allow"
#   priority                    = 105
#   source_address_prefixes     = var.private_prefixes_v6
#   source_port_range           = "*"
#   destination_address_prefix  = "*"
#   destination_port_range      = "*"
#   protocol                    = "*"
#   description                 = "Allow all private prefixes"
# }

# resource "azurerm_network_security_rule" "nsg_aks_private_outbound" {
#   for_each                    = var.regions
#   resource_group_name         = var.resource_group
#   network_security_group_name = azurerm_network_security_group.nsg_aks[each.key].name
#   name                        = "all-outbound"
#   direction                   = "Outbound"
#   access                      = "Allow"
#   priority                    = 100
#   source_address_prefix       = "*"
#   source_port_range           = "*"
#   destination_address_prefix  = "*"
#   destination_port_range      = "*"
#   protocol                    = "*"
#   description                 = "Allow all outbound"
# }

# resource "azurerm_network_security_rule" "nsg_aks_internet_inbound" {
#   for_each                    = var.regions
#   resource_group_name         = var.resource_group
#   network_security_group_name = azurerm_network_security_group.nsg_aks[each.key].name
#   name                        = "internet-inbound"
#   direction                   = "Inbound"
#   access                      = "Allow"
#   priority                    = 120
#   source_address_prefix       = "*"
#   source_port_range           = "*"
#   destination_address_prefix  = "*"
#   destination_port_range      = "*"
#   protocol                    = "Tcp"
#   description                 = "Allow inbound web traffic"
# }

# resource "azurerm_network_security_rule" "nsg_aks_internet_inbound_ipv6" {
#   for_each                     = var.regions
#   resource_group_name          = var.resource_group
#   network_security_group_name  = azurerm_network_security_group.nsg_aks[each.key].name
#   name                         = "internet-inbound-self-ipv6"
#   direction                    = "Inbound"
#   access                       = "Allow"
#   priority                     = 130
#   source_address_prefixes      = ["::/0"]
#   source_port_range            = "*"
#   destination_address_prefixes = ["::/0"]
#   destination_port_range       = "*"
#   protocol                     = "Tcp"
#   description                  = "Allow inbound web traffic over IPv6"
# }

# nva
#----------------------------

# resource "azurerm_network_security_group" "nsg_nva" {
#   for_each            = var.regions
#   resource_group_name = var.resource_group
#   name                = "${local.prefix}nsg-${each.key}-nva"
#   location            = each.value.name
#   tags                = var.tags
# }

# resource "azurerm_network_security_rule" "nsg_nva_private_inbound" {
#   for_each                    = var.regions
#   resource_group_name         = var.resource_group
#   network_security_group_name = azurerm_network_security_group.nsg_nva[each.key].name
#   name                        = "private-inbound"
#   direction                   = "Inbound"
#   access                      = "Allow"
#   priority                    = 100
#   source_address_prefixes     = var.private_prefixes
#   source_port_range           = "*"
#   destination_address_prefix  = "*"
#   destination_port_range      = "*"
#   protocol                    = "*"
#   description                 = "Allow all private prefixes"
# }

# resource "azurerm_network_security_rule" "nsg_nva_private_inbound_v6" {
#   for_each                    = var.regions
#   resource_group_name         = var.resource_group
#   network_security_group_name = azurerm_network_security_group.nsg_nva[each.key].name
#   name                        = "private-inbound-v6"
#   direction                   = "Inbound"
#   access                      = "Allow"
#   priority                    = 105
#   source_address_prefixes     = var.private_prefixes_v6
#   source_port_range           = "*"
#   destination_address_prefix  = "*"
#   destination_port_range      = "*"
#   protocol                    = "*"
#   description                 = "Allow all private prefixes"
# }

# resource "azurerm_network_security_rule" "nsg_nva_ipsec_inbound" {
#   for_each                    = var.regions
#   resource_group_name         = var.resource_group
#   network_security_group_name = azurerm_network_security_group.nsg_nva[each.key].name
#   name                        = "allow-ipsec-inbound"
#   direction                   = "Inbound"
#   access                      = "Allow"
#   priority                    = 110
#   source_address_prefix       = "*"
#   source_port_range           = "*"
#   destination_address_prefix  = "*"
#   destination_port_ranges     = ["500", "4500"]
#   protocol                    = "Udp"
#   description                 = "Inbound Allow UDP 500, 4500"
# }

# resource "azurerm_network_security_rule" "nsg_nva_internet_inbound" {
#   for_each                    = var.regions
#   resource_group_name         = var.resource_group
#   network_security_group_name = azurerm_network_security_group.nsg_nva[each.key].name
#   name                        = "internet-inbound"
#   direction                   = "Inbound"
#   access                      = "Allow"
#   priority                    = 120
#   source_address_prefix       = "*"
#   source_port_range           = "*"
#   destination_address_prefix  = "*"
#   destination_port_ranges     = ["443", "50443", "50444", ]
#   protocol                    = "Tcp"
#   description                 = "Allow inbound web traffic"
# }

# resource "azurerm_network_security_rule" "nsg_nva_outbound" {
#   for_each                    = var.regions
#   resource_group_name         = var.resource_group
#   network_security_group_name = azurerm_network_security_group.nsg_nva[each.key].name
#   name                        = "all-outbound"
#   direction                   = "Outbound"
#   access                      = "Allow"
#   priority                    = 100
#   source_address_prefix       = "*"
#   source_port_range           = "*"
#   destination_address_prefix  = "*"
#   destination_port_range      = "*"
#   protocol                    = "*"
#   description                 = "Allow all outbound"
# }

# load balancer
#----------------------------

# resource "azurerm_network_security_group" "nsg_lb" {
#   for_each            = var.regions
#   resource_group_name = var.resource_group
#   name                = "${local.prefix}nsg-${each.key}-appgw"
#   location            = each.value.name
#   tags                = var.tags
# }

# resource "azurerm_network_security_rule" "nsg_lb_appgw_v2sku_inbound" {
#   for_each                    = var.regions
#   resource_group_name         = var.resource_group
#   network_security_group_name = azurerm_network_security_group.nsg_lb[each.key].name
#   name                        = "allow-appgw-v2sku-inbound"
#   direction                   = "Inbound"
#   access                      = "Allow"
#   priority                    = 200
#   source_address_prefix       = "GatewayManager"
#   source_port_range           = "*"
#   destination_address_prefix  = "*"
#   destination_port_range      = "65200-65535"
#   protocol                    = "*"
#   description                 = "Allow Inbound Azure infrastructure communication"
# }

# resource "azurerm_network_security_rule" "nsg_lb_web_external_inbound" {
#   for_each                    = var.regions
#   resource_group_name         = var.resource_group
#   network_security_group_name = azurerm_network_security_group.nsg_lb[each.key].name
#   name                        = "allow-web-external-inbound"
#   direction                   = "Inbound"
#   access                      = "Allow"
#   priority                    = 210
#   source_address_prefix       = "*"
#   source_port_range           = "*"
#   destination_address_prefix  = "VirtualNetwork"
#   destination_port_ranges     = ["80", "443", "8080", "8081", "3000"]
#   protocol                    = "Tcp"
#   description                 = "Allow inbound web traffic"
# }

# resource "azurerm_network_security_rule" "nsg_lb_outbound" {
#   for_each                    = var.regions
#   resource_group_name         = var.resource_group
#   network_security_group_name = azurerm_network_security_group.nsg_lb[each.key].name
#   name                        = "all-outbound"
#   direction                   = "Outbound"
#   access                      = "Allow"
#   priority                    = 100
#   source_address_prefix       = "*"
#   source_port_range           = "*"
#   destination_address_prefix  = "*"
#   destination_port_range      = "*"
#   protocol                    = "*"
#   description                 = "Allow all outbound"
# }

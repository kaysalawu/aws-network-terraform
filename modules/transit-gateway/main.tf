locals {
  # List of maps with key and route values
  vpc_attachments_with_routes = chunklist(flatten([
    for k, v in var.vpc_attachments : setproduct([{ key = k }], v.tgw_routes) if var.create_tgw && can(v.tgw_routes)
  ]), 2)

  tgw_default_route_table_tags_merged = merge(
    var.tags,
    { Name = var.name },
    var.tgw_default_route_table_tags,
  )

  vpc_route_table_destination_cidr = flatten([
    for k, v in var.vpc_attachments : [
      for rtb_id in try(v.vpc_route_table_ids, []) : {
        rtb_id = rtb_id
        cidr   = v.tgw_destination_cidr
        tgw_id = var.create_tgw ? aws_ec2_transit_gateway.this[0].id : v.tgw_id
      }
    ]
  ])
  flattened_vpc_routes_ipv4 = flatten([
    for index, attachment in var.vpc_attachments : [
      for route_index, route in attachment.vpc_routes : [
        for cidr in route.ipv4_prefixes : {
          key                         = "${route.name}-${cidr}"
          route_table_id              = route.route_table_id
          destination_cidr_block      = cidr
          destination_ipv6_cidr_block = null
        }
      ]
    ]
  ])
  flattened_vpc_routes_ipv6 = flatten([
    for index, attachment in var.vpc_attachments : [
      for route_index, route in attachment.vpc_routes : [
        for cidr in route.ipv6_prefixes : {
          key                         = "${route.name}-${cidr}"
          route_table_id              = route.route_table_id
          destination_cidr_block      = null
          destination_ipv6_cidr_block = cidr
        }
      ]
    ]
  ])
  flattened_vpc_routes = concat(
    local.flattened_vpc_routes_ipv4,
    local.flattened_vpc_routes_ipv6,
  )
  flattened_transit_gateway_routes_ipv4 = flatten([
    for index, attachment in var.vpc_attachments : [
      for route_index, route in attachment.transit_gateway_routes : [
        for cidr in route.ipv4_prefixes : {
          key                    = "${route.name}-${cidr}"
          destination_cidr_block = cidr
          route_table_name       = route.route_table_name
          blackhole              = try(route.blackhole, false)
          attachment_name        = try(route.attachment_name, null)
        }
      ]
    ]
  ])
  flattened_transit_gateway_routes_ipv6 = []
  flattened_transit_gateway_routes = concat(
    local.flattened_transit_gateway_routes_ipv4,
    local.flattened_transit_gateway_routes_ipv6,
  )
  transit_gateway_id = var.create_tgw ? aws_ec2_transit_gateway.this[0].id : var.transit_gateway_id
}

# ################################################################################
# # Transit Gateway
# ################################################################################

resource "aws_ec2_transit_gateway" "this" {
  count                              = var.create_tgw ? 1 : 0
  amazon_side_asn                    = var.amazon_side_asn
  auto_accept_shared_attachments     = var.auto_accept_shared_attachments
  default_route_table_association    = var.default_route_table_association
  default_route_table_propagation    = var.default_route_table_propagation
  description                        = coalesce(var.description, var.name)
  dns_support                        = var.dns_support
  security_group_referencing_support = var.security_group_referencing_support
  multicast_support                  = var.multicast_support
  transit_gateway_cidr_blocks        = var.transit_gateway_cidr_blocks
  vpn_ecmp_support                   = var.vpn_ecmp_support

  timeouts {
    create = try(var.timeouts.create, null)
    update = try(var.timeouts.update, null)
    delete = try(var.timeouts.delete, null)
  }

  tags = merge(
    var.tags,
    { Name = var.name },
    var.tgw_tags,
  )
}

resource "aws_ec2_tag" "this" {
  for_each    = { for k, v in local.tgw_default_route_table_tags_merged : k => v if var.create_tgw && var.default_route_table_association == "enable" }
  resource_id = aws_ec2_transit_gateway.this[0].association_default_route_table_id
  key         = each.key
  value       = each.value
}

# ################################################################################
# # VPC Attachment
# ################################################################################

resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  for_each = { for index, attachment in var.vpc_attachments : attachment.name => attachment }

  transit_gateway_id     = local.transit_gateway_id
  vpc_id                 = each.value.vpc_id
  subnet_ids             = each.value.subnet_ids
  dns_support            = each.value.dns_support
  ipv6_support           = each.value.ipv6_support
  appliance_mode_support = each.value.appliance_mode_support

  transit_gateway_default_route_table_association = each.value.transit_gateway_default_route_table_association
  transit_gateway_default_route_table_propagation = each.value.transit_gateway_default_route_table_propagation

  tags = merge(
    var.tags,
    var.tgw_vpc_attachment_tags,
    { Name = each.value.name },
  )
}

# ################################################################################
# # Route Table
# ################################################################################

# resource

resource "aws_ec2_transit_gateway_route_table" "this" {
  for_each           = { for rt in var.route_tables : rt.name => rt }
  transit_gateway_id = local.transit_gateway_id

  tags = merge(
    var.tags,
    { Name = "${each.value.name}-rt" },
  )
}

# association

resource "aws_ec2_transit_gateway_route_table_association" "this" {
  for_each = { for index, attachment in var.vpc_attachments :
    attachment.name => attachment if var.create_tgw && var.default_route_table_association == "disable"
  }
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this[each.key].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this[each.value.route_table].id
}

# propagation

resource "aws_ec2_transit_gateway_route_table_propagation" "this" {
  for_each = { for index, attachment in var.vpc_attachments :
    attachment.name => attachment if var.create_tgw && var.default_route_table_propagation == "disable"
  }
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this[each.key].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this[each.value.route_table].id
}

# transit gateway routes

resource "aws_ec2_transit_gateway_route" "this" {
  for_each                       = { for route in local.flattened_transit_gateway_routes : route.key => route }
  destination_cidr_block         = each.value.destination_cidr_block
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this[each.value.route_table_name].id
  transit_gateway_attachment_id  = try(aws_ec2_transit_gateway_vpc_attachment.this[each.value.attachment_name].id, null)
  blackhole                      = each.value.blackhole
}

# vpc routes

resource "aws_route" "this" {
  for_each                    = { for route in local.flattened_vpc_routes : route.key => route }
  route_table_id              = each.value.route_table_id
  destination_cidr_block      = each.value.destination_cidr_block
  destination_ipv6_cidr_block = each.value.destination_ipv6_cidr_block
  transit_gateway_id          = local.transit_gateway_id
}

# ################################################################################
# # Resource Access Manager
# ################################################################################

resource "aws_ram_resource_share" "this" {
  count = var.create_tgw && var.share_tgw ? 1 : 0

  name                      = coalesce(var.ram_name, var.name)
  allow_external_principals = var.ram_allow_external_principals

  tags = merge(
    var.tags,
    { Name = coalesce(var.ram_name, var.name) },
    var.ram_tags,
  )
}

resource "aws_ram_resource_association" "this" {
  count = var.create_tgw && var.share_tgw ? 1 : 0

  resource_arn       = aws_ec2_transit_gateway.this[0].arn
  resource_share_arn = aws_ram_resource_share.this[0].id
}

resource "aws_ram_principal_association" "this" {
  count = var.create_tgw && var.share_tgw ? length(var.ram_principals) : 0

  principal          = var.ram_principals[count.index]
  resource_share_arn = aws_ram_resource_share.this[0].arn
}

resource "aws_ram_resource_share_accepter" "this" {
  count = !var.create_tgw && var.share_tgw ? 1 : 0

  share_arn = var.ram_resource_share_arn
}

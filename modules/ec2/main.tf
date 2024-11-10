
####################################################
# interface
####################################################

# interface

resource "aws_network_interface" "this" {
  for_each        = { for interface in var.interfaces : interface.name => interface }
  subnet_id       = each.value.subnet_id
  private_ips     = each.value.private_ips != [] ? each.value.private_ips : null
  ipv6_addresses  = each.value.ipv6_addresses != [] ? each.value.ipv6_addresses : null
  security_groups = each.value.security_group_ids

  tags = merge(var.tags,
    {
      Name = each.value.name
    }
  )
}

# elastic ip

resource "aws_eip" "this" {
  for_each                  = { for interface in var.interfaces : interface.name => interface if interface.create_public_ip }
  domain                    = "vpc"
  network_interface         = aws_network_interface.this[each.key].id
  associate_with_private_ip = each.value.private_ips != null && length(each.value.private_ips) > 0 ? each.value.private_ips[0] : null

  tags = merge(var.tags,
    {
      Name = each.value.name
    }
  )
}

####################################################
# instance
####################################################

# instance

resource "aws_instance" "this" {
  instance_type        = var.instance_type
  availability_zone    = var.availability_zone
  ami                  = var.ami
  key_name             = var.key_name != null ? var.key_name : null
  iam_instance_profile = var.iam_instance_profile != null ? var.iam_instance_profile : null
  user_data            = var.user_data != null ? var.user_data : null

  dynamic "network_interface" {
    for_each = { for index, interface in var.interfaces : interface.name => merge(interface, { device_index = index }) }
    content {
      device_index         = network_interface.value.device_index
      network_interface_id = aws_network_interface.this[network_interface.key].id
    }
  }

  metadata_options {
    instance_metadata_tags = var.instance_metadata_tags
  }

  tags = merge(var.tags,
    {
      Name = var.name
    }
  )
}

####################################################
# dns record
####################################################

# dns record

resource "aws_route53_record" "this" {
  for_each = { for interface in var.interfaces : interface.name => interface if interface.dns_config.zone_name != null }
  zone_id  = data.aws_route53_zone.this[each.key].id
  name     = each.value.dns_config.name != null ? each.value.dns_config.name : aws_instance.this.tags.Name
  type     = each.value.dns_config.type
  ttl      = each.value.dns_config.ttl
  records  = [aws_instance.this.private_ip, ]

  depends_on = [
    aws_instance.this,
  ]
  lifecycle {
    ignore_changes = [
      zone_id,
    ]
  }
}




output "public_ips" {
  value = coalesce(
    { for k, v in aws_eip.this : k => v.public_ip }
  )
}

output "private_ip_list" {
  value = { for k, v in aws_network_interface.this : k => v.private_ip_list }
}

output "private_ip" {
  value = aws_instance.this.private_ip
}

output "public_ip" {
  value = aws_instance.this.public_ip
}

output "instance_id" {
  value = aws_instance.this.id
}

output "interface_ids" {
  value = { for k, v in aws_network_interface.this : k => v.id }
}

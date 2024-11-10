
output "public_ips" {
  value = { for k, v in aws_eip.this : k => v.public_ip }
}

output "private_ips" {
  value = { for k, v in aws_network_interface.this : k => v.private_ips }
}

output "private_ip" {
  value = aws_instance.this.private_ip
}

output "instance_id" {
  value = aws_instance.this.id
}

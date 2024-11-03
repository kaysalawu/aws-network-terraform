
output "vpc_id" {
  value = aws_vpc.this.id
}

output "vpc_cidr_block" {
  value = aws_vpc.this.cidr_block
}

output "additional_cidr_blocks" {
  value = aws_vpc_ipv4_cidr_block_association.this[*].cidr_block
}

output "vpc_ipv6_cidr_block" {
  value = aws_vpc.this.ipv6_cidr_block
}

output "bastion_security_group_id" {
  value = aws_security_group.bastion_sg.id
}

output "nva_security_group_id" {
  value = aws_security_group.bastion_sg.id
}

output "ec2_security_group_id" {
  value = aws_security_group.ec2_sg.id
}

output "public_subnet_ids" {
  value = { for k, v in aws_subnet.public : k => v.id }
}

output "private_subnet_ids" {
  value = { for k, v in aws_subnet.private : k => v.id }
}

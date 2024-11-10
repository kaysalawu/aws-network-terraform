
####################################################
# vpc
####################################################

output "vpc_name" {
  value = aws_vpc.this.tags.Name
}

output "vpc_id" {
  value = aws_vpc.this.id
}

output "vpc_cidr_block" {
  value = aws_vpc.this.cidr_block
}

output "vpc_ipv6_cidr_block" {
  value = aws_vpc.this.ipv6_cidr_block
}

output "public_subnet_ids" {
  value = { for k, v in aws_subnet.public : k => v.id }
}

output "private_subnet_ids" {
  value = { for k, v in aws_subnet.private : k => v.id }
}

####################################################
# security group
####################################################

output "bastion_security_group_id" {
  value = aws_security_group.bastion_sg.id
}

output "nva_security_group_id" {
  value = aws_security_group.nva_sg.id
}

output "ec2_security_group_id" {
  value = aws_security_group.ec2_sg.id
}

####################################################
# bastion
####################################################

output "bastion_id" {
  value = try(module.bastion[0].instance_id, "")
}

output "public_route_table_id" {
  value = aws_route_table.public_route_table[0].id
}

output "private_route_table_id" {
  value = aws_route_table.private_route_table[0].id
}

####################################################
# gateways
####################################################

output "internet_gateway_id" {
  value = aws_internet_gateway.this.id
}

output "nat_gateways" {
  value = merge(
    { for index, gateway in aws_nat_gateway.natgw_a : gateway.id => gateway.id },
    { for index, gateway in aws_nat_gateway.natgw_b : gateway.id => gateway.id },
    { for index, gateway in aws_nat_gateway.natgw_c : gateway.id => gateway.id },
  )
}

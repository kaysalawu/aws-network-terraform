
output "bastion_pub_sg" {
  value = aws_security_group.bastion_pub_sg.id
}

output "nva_pub_sg" {
  value = aws_security_group.bastion_pub_sg.id
}

output "ec2_prv_sg" {
  value = aws_security_group.ec2_prv_sg.id
}

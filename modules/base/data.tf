
############################################
# data
############################################

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}

data "aws_route53_zone" "public" {
  count        = var.public_dns_zone_name != null ? 1 : 0
  name         = "${var.public_dns_zone_name}."
  private_zone = false
}

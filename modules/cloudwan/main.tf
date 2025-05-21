
data "aws_organizations_organization" "this" {}

resource "aws_networkmanager_global_network" "this" {
  description = "Wise Global Network"
  tags = {
    Name = var.global_network_name
  }
}

resource "aws_networkmanager_core_network" "this" {
  global_network_id   = aws_networkmanager_global_network.this.id
  base_policy_regions = var.base_policy_regions
  create_base_policy  = true
}

resource "aws_networkmanager_core_network_policy_attachment" "this" {
  core_network_id = aws_networkmanager_core_network.this.id
  policy_document = data.aws_networkmanager_core_network_policy_document.this.json
}

resource "aws_ram_resource_share" "this" {
  name                      = "corenet"
  allow_external_principals = false
  permission_arns           = ["arn:aws:ram::aws:permission/AWSRAMDefaultPermissionsNetworkManagerCoreNetwork"]
}

resource "aws_ram_resource_association" "this" {
  resource_share_arn = aws_ram_resource_share.this.arn
  resource_arn       = aws_networkmanager_core_network.this.arn
}

resource "aws_ram_principal_association" "this" {
  principal          = data.aws_organizations_organization.this.arn
  resource_share_arn = aws_ram_resource_share.this.arn
}

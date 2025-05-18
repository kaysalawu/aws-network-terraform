# AWX Operator Controller Manager IAM Role
module "k8_awx_operator_controller_manager_iam_role_policy" {
  source = "./modules/ssm-param-getter-iam-policy-document-json"

  parameter_names = [
    "awx/admin_password",
    "awx/secret_key",
    "awx/rds-endpoint",
    "awx/rds-username",
    "awx/rds-password",
    "awx/rds-database",
    "awx/rds-port",
    "awx/rds-sslmode",
    "awx/rds-type",
    "awx/deployer-pi-user-ssh-key",
    "awx/github/machine-user-ssh-key",
    "awx/ansible_vault_password"
  ]
}

module "k8_awx_operator_controller_manager" {
  source               = "./modules/k8-pod-iam-role"
  name                 = "k8-awx-operator-controller-manager"
  oidc_provider_arn    = aws_iam_openid_connect_provider.irsa.arn
  policy_document_json = module.k8_awx_operator_controller_manager_iam_role_policy.json
}

resource "aws_iam_role_policy_attachment" "k8_awx_operator_controller_attach_ec2_read_only_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
  role       = module.k8_awx_operator_controller_manager.role_name
}

# AWX Bootstrap K8 Job IAM Role
# This is the role that runs the job to bootstrap the AWX installation and restore it's configuration

module "k8_ansible_awx_bootstrap_iam_role_policy" {
  source = "./modules/ssm-param-getter-iam-policy-document-json"

  parameter_names = [
    "awx/admin_password",
    "awx/ansible_vault_password",
    "awx/github/machine-user-ssh-key",
    "awx/deployer-pi-user-ssh-key",
    "awx/rds-endpoint",
    "awx/rds-username",
    "awx/rds-password",
    "awx/deployer-pi-user-ssh-key"
  ]
}

module "k8_ansible_awx_bootstrap" {
  source               = "./modules/k8-pod-iam-role"
  name                 = "k8-ansible-awx-bootstrap"
  oidc_provider_arn    = aws_iam_openid_connect_provider.irsa.arn
  policy_document_json = module.k8_ansible_awx_bootstrap_iam_role_policy.json
}

# Not needed for the bootstrap role - but let's confirm and remove this later
#resource "aws_iam_role_policy_attachment" "k8_ansible_awx_bootstrap_attach_ec2_read_only_policy" {
#  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
#  role       = module.k8_ansible_awx_bootstrap.role_name
#}


## NETBOX

# Netbox IAM Role
module "k8_netbox_iam_role_policy" {
  source = "./modules/ssm-param-getter-iam-policy-document-json"

  parameter_names = [
    "netbox/rds_password",
    "netbox/okta_client_id",
    "netbox/okta_client_secret",
    "netbox/redis_password",
    "netbox/redis_cache_password",
    "netbox/secret_key"
  ]
}

module "k8_netbox" {
  source               = "./modules/k8-pod-iam-role"
  name                 = "k8-netbox"
  oidc_provider_arn    = aws_iam_openid_connect_provider.irsa.arn
  policy_document_json = module.k8_netbox_iam_role_policy.json
}
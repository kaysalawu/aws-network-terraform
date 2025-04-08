# SSM Parameters for K8
# Read by K8 in the k8-pod-iam-roles.tf module
module "ssm_parameters" {
  source = "./modules/ssm-parameters"
  random = false
  secure_strings = [
    "/awx/rds-password",
    "/awx/admin_password",
    "/awx/secret_key",
    "/awx/ansible_vault_password",
    "/awx/github/machine-user-ssh-key",
    "/awx/deployer-pi-user-ssh-key",
    "/netbox/admin_password",
    "/netbox/rds_password",
    "/netbox/elasticache_password"
  ]
  strings = [
    "/awx/rds-endpoint",
    "/awx/rds-username",
    "/awx/rds-database",
    "/awx/rds-port",
    "/awx/rds-type",
    "/awx/rds-sslmode",
  ]
}

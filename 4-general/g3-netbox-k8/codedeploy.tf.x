module "code-deploy-k8" {
  source    = "cloudposse/code-deploy/aws"
  version   = "0.2.3"
  delimiter = "-"
  deployment_style = {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  autoscaling_groups = [module.asg.asg_name[0]]

  enabled          = true
  label_value_case = "lower"
  name             = local.service
  minimum_healthy_hosts = {
    type  = "HOST_COUNT"
    value = "0"
  }
  compute_platform            = "Server"
  create_default_service_role = true
  create_default_sns_topic    = true
  trigger_events = ["DeploymentStart", "DeploymentSuccess", "DeploymentFailure",
  "DeploymentRollback", "InstanceFailure"]
}

resource "random_password" "securestring" {
  for_each = var.random ? toset(var.secure_strings) : toset([])
  length   = 20
  special  = true
}

resource "aws_ssm_parameter" "securestring" {
  for_each = toset(var.secure_strings)
  name     = each.value
  type     = "SecureString"
  value    = var.random ? random_password.securestring[each.value].result : "changeme"

  # Ignoring changes to the value allows the user to set these manually:
  lifecycle {
    ignore_changes = [value]
  }
}

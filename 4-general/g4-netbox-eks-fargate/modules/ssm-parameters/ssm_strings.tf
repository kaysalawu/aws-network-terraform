resource "random_string" "string" {
  for_each = var.random ? toset(var.strings) : toset([])
  length   = 20
  special  = true
}

resource "aws_ssm_parameter" "string" {
  for_each = toset(var.strings)
  name     = each.value
  type     = "String"
  value    = var.random ? random_string.string[each.value].result : "changeme"

  # Ignoring changes to the value allows the user to set these manually:
  lifecycle {
    ignore_changes = [value]
  }
}

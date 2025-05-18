variable "parameter_names" {
  description = "The parameter name(s) (AKA paths) to allow the Pod to read. Accepts the '*' wildcard."
  type        = list(string)
}
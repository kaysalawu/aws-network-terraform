variable "secure_strings" {
  description = "Parameters to create as SecureString (secret, encrypted) type"
  type        = list(string)
}

variable "strings" {
  description = "Parameters to create as String (non-secret, plaintext) type"
  type        = list(string)
}

variable "random" {
  description = "Whether to generate a random value for these parameters. If false each parameter uses the value 'changeme'"
  type        = bool
}
variable "namespace" {
  type        = string
  description = "The context namespace."
}

variable "create_provider" {
  type        = bool
  default     = true
  description = "Whether the module creates the GitHub Actions OIDC provider. The CI test sets this to false because the sandbox account already has one."
}

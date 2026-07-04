variable "context" {
  type = object({
    attributes     = list(string)
    dns_namespace  = string
    environment    = string
    instance       = string
    instance_short = string
    namespace      = string
    region         = string
    region_short   = string
    role           = string
    role_short     = string
    project        = string
    tags           = map(string)
  })
  description = "Shared context from the 'bendoerr-terraform-modules/terraform-null-context' module."
}

variable "name" {
  type        = string
  default     = "github-oidc"
  description = "A descriptive but short name used for labels by the 'bendoerr-terraform-modules/terraform-null-label' module."
  nullable    = false
}

variable "create_provider" {
  type        = bool
  default     = true
  description = "Whether to create the GitHub Actions OIDC identity provider. AWS allows a single provider per URL per account, so set this to false when the account already has one and it will be discovered with a data source instead."
  nullable    = false
}

variable "thumbprint_list" {
  type        = list(string)
  default     = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
  description = "Server certificate thumbprints for the OIDC provider. AWS now validates GitHub's tokens against trusted root CAs and ignores these values, but the field is still required by the API."
  nullable    = false
}

variable "roles" {
  type = map(object({
    repository           = string
    subjects             = optional(list(string), ["*"])
    description          = optional(string)
    policy_arns          = optional(list(string), [])
    inline_policies      = optional(map(string), {})
    max_session_duration = optional(number, 3600)
    permissions_boundary = optional(string)
    path                 = optional(string)
  }))
  default     = {}
  description = <<-EOT
    IAM roles assumable by GitHub Actions through the OIDC provider, keyed by a short
    name used for the role's label. Each role trusts a single GitHub 'repository'
    ('owner/name') and a list of 'subjects' — subject suffixes appended to
    'repo:<repository>:' in the trust policy's StringLike condition, for example
    'ref:refs/heads/main', 'ref:refs/tags/v*', 'environment:production' or
    'pull_request'. The default '*' trusts every workflow in the repository.
    Permissions come from 'policy_arns' (attached managed policies) and
    'inline_policies' (a map of policy name to JSON document).
  EOT
  nullable    = false

  validation {
    condition     = alltrue([for role in var.roles : can(regex("^[^/]+/[^/]+$", role.repository))])
    error_message = "Each role's repository must be in 'owner/name' format."
  }

  validation {
    condition     = alltrue([for role in var.roles : length(role.subjects) > 0])
    error_message = "Each role's subjects list must contain at least one entry; an empty list would render a trust policy with no subject condition values."
  }

  validation {
    condition     = alltrue([for role in var.roles : role.max_session_duration >= 3600 && role.max_session_duration <= 43200])
    error_message = "Each role's max_session_duration must be between 3600 and 43200 seconds."
  }
}

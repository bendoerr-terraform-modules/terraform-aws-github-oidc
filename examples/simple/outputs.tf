output "oidc_provider_arn" {
  value       = module.this.oidc_provider_arn
  description = "ARN of the GitHub Actions OIDC identity provider."
}

output "roles" {
  value       = module.this.roles
  description = "Created IAM roles keyed by the input role key."
}

output "id" {
  value       = module.this.id
  description = "The normalized ID from the 'bendoerr-terraform-modules/terraform-null-label' module."
}

output "tags" {
  value       = module.this.tags
  description = "The normalized tags from the 'bendoerr-terraform-modules/terraform-null-label' module."
}

output "name" {
  value       = module.this.name
  description = "The provided name given to the module."
}

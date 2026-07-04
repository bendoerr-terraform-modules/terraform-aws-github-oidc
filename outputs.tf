output "oidc_provider_arn" {
  value       = local.oidc_provider_arn
  description = "ARN of the GitHub Actions OIDC identity provider, whether created by this module or discovered in the account."
}

output "roles" {
  value = {
    for key, role in aws_iam_role.this : key => {
      arn       = role.arn
      name      = role.name
      unique_id = role.unique_id
    }
  }
  description = "Created IAM roles keyed by the input role key, each with its arn, name and unique_id."
}

output "id" {
  value       = module.label.id
  description = "The normalized ID from the 'bendoerr-terraform-modules/terraform-null-label' module."
}

output "tags" {
  value       = module.label.tags
  description = "The normalized tags from the 'bendoerr-terraform-modules/terraform-null-label' module."
}

output "name" {
  value       = var.name
  description = "The provided name given to the module."
}

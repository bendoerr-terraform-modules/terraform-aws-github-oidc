module "context" {
  source    = "bendoerr-terraform-modules/context/null"
  version   = "0.5.1"
  namespace = var.namespace
  role      = "terraform-aws-github-oidc"
  region    = "us-east-1"
  project   = "simple"
  long_dns  = true
}

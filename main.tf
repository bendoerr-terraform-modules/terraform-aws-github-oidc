module "label" {
  source  = "bendoerr-terraform-modules/label/null"
  version = "1.0.0"
  context = var.context
  name    = var.name
}

# AWS allows a single OIDC identity provider per URL per account, so the
# provider is optionally created here or discovered when one already exists.
resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_provider ? 1 : 0

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  # AWS validates GitHub's OIDC tokens against trusted root CAs and ignores
  # these thumbprints, but the API still requires the field to be set.
  thumbprint_list = var.thumbprint_list

  tags = module.label.tags
}

data "aws_iam_openid_connect_provider" "github" {
  count = var.create_provider ? 0 : 1

  url = "https://token.actions.githubusercontent.com"
}

locals {
  oidc_provider_arn = try(
    aws_iam_openid_connect_provider.github[0].arn,
    data.aws_iam_openid_connect_provider.github[0].arn,
    null,
  )
}

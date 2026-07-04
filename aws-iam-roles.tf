module "label_role" {
  source   = "bendoerr-terraform-modules/label/null"
  version  = "1.0.0"
  for_each = var.roles
  context  = var.context
  name     = each.key
}

data "aws_iam_policy_document" "trust" {
  for_each = var.roles

  statement {
    sid     = "GitHubActionsAssumeRoleWithWebIdentity"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [for s in each.value.subjects : "repo:${each.value.repository}:${s}"]
    }
  }
}

resource "aws_iam_role" "this" {
  for_each = var.roles

  name                 = module.label_role[each.key].id
  description          = each.value.description
  assume_role_policy   = data.aws_iam_policy_document.trust[each.key].json
  max_session_duration = each.value.max_session_duration
  permissions_boundary = each.value.permissions_boundary
  path                 = each.value.path

  tags = module.label_role[each.key].tags
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = {
    for pair in flatten([
      for role_key, role in var.roles : [
        for policy_arn in role.policy_arns : {
          role_key   = role_key
          policy_arn = policy_arn
        }
      ]
    ]) : "${pair.role_key}:${pair.policy_arn}" => pair
  }

  role       = aws_iam_role.this[each.value.role_key].name
  policy_arn = each.value.policy_arn
}

resource "aws_iam_role_policy" "this" {
  for_each = {
    for pair in flatten([
      for role_key, role in var.roles : [
        for policy_name, policy_json in role.inline_policies : {
          role_key    = role_key
          policy_name = policy_name
          policy_json = policy_json
        }
      ]
    ]) : "${pair.role_key}:${pair.policy_name}" => pair
  }

  role   = aws_iam_role.this[each.value.role_key].name
  name   = each.value.policy_name
  policy = each.value.policy_json
}

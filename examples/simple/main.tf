terraform {
  # Anything greater than the 1.0.0 release should be sufficient
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.10"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "this" {
  source          = "../.."
  context         = module.context.shared
  name            = "github-oidc"
  create_provider = var.create_provider

  roles = {
    ci = {
      repository  = "bendoerr-terraform-modules/terraform-aws-github-oidc"
      subjects    = ["ref:refs/heads/main", "pull_request"]
      description = "Example CI role assumable from this repository's main branch and pull requests."
      inline_policies = {
        describe-regions = data.aws_iam_policy_document.example.json
      }
    }
  }
}

data "aws_iam_policy_document" "example" {
  statement {
    sid       = "Example"
    effect    = "Allow"
    actions   = ["ec2:DescribeRegions"]
    resources = ["*"]
  }
}

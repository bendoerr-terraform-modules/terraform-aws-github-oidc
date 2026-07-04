<br/>
<p align="center">
  <a href="https://github.com/bendoerr-terraform-modules/terraform-aws-github-oidc">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://github.com/bendoerr-terraform-modules/terraform-aws-github-oidc/raw/main/docs/logo-dark.png">
      <img src="https://github.com/bendoerr-terraform-modules/terraform-aws-github-oidc/raw/main/docs/logo-light.png" alt="Logo">
    </picture>
  </a>

<h3 align="center">Ben's GitHub Actions OIDC Terraform Module</h3>

<p align="center">
    Keyless CI access to AWS, scoped to the repos and refs that need it.
    <br/>
    <br/>
    <a href="https://github.com/bendoerr-terraform-modules/terraform-aws-github-oidc"><strong>Explore the docs »</strong></a>
    <br/>
    <br/>
    <a href="https://github.com/bendoerr-terraform-modules/terraform-aws-github-oidc/issues">Report Bug</a>
    .
    <a href="https://github.com/bendoerr-terraform-modules/terraform-aws-github-oidc/issues">Request Feature</a>
  </p>
</p>

[<img alt="GitHub contributors" src="https://img.shields.io/github/contributors/bendoerr-terraform-modules/terraform-aws-github-oidc?logo=github">](https://github.com/bendoerr-terraform-modules/terraform-aws-github-oidc/graphs/contributors)
[<img alt="GitHub issues" src="https://img.shields.io/github/issues/bendoerr-terraform-modules/terraform-aws-github-oidc?logo=github">](https://github.com/bendoerr-terraform-modules/terraform-aws-github-oidc/issues)
[<img alt="GitHub pull requests" src="https://img.shields.io/github/issues-pr/bendoerr-terraform-modules/terraform-aws-github-oidc?logo=github">](https://github.com/bendoerr-terraform-modules/terraform-aws-github-oidc/pulls)
[<img alt="GitHub workflow: Terratest" src="https://img.shields.io/github/actions/workflow/status/bendoerr-terraform-modules/terraform-aws-github-oidc/test.yml?logo=githubactions&label=terratest">](https://github.com/bendoerr-terraform-modules/terraform-aws-github-oidc/actions/workflows/test.yml)
[<img alt="GitHub workflow: Linting" src="https://img.shields.io/github/actions/workflow/status/bendoerr-terraform-modules/terraform-aws-github-oidc/lint.yml?logo=githubactions&label=linting">](https://github.com/bendoerr-terraform-modules/terraform-aws-github-oidc/actions/workflows/lint.yml)
[<img alt="GitHub tag (with filter)" src="https://img.shields.io/github/v/tag/bendoerr-terraform-modules/terraform-aws-github-oidc?filter=v*&label=latest%20tag&logo=terraform">](https://registry.terraform.io/modules/bendoerr-terraform-modules/github-oidc/aws/latest)
[<img alt="OSSF-Scorecard Score" src="https://img.shields.io/ossf-scorecard/github.com/bendoerr-terraform-modules/terraform-aws-github-oidc?logo=securityscorecard&label=ossf%20scorecard&link=https%3A%2F%2Fsecurityscorecards.dev%2Fviewer%2F%3Furi%3Dgithub.com%2Fbendoerr-terraform-modules%2Fterraform-aws-github-oidc">](https://securityscorecards.dev/viewer/?uri=github.com/bendoerr-terraform-modules/terraform-aws-github-oidc)
[<img alt="GitHub License" src="https://img.shields.io/github/license/bendoerr-terraform-modules/terraform-aws-github-oidc?logo=opensourceinitiative">](https://github.com/bendoerr-terraform-modules/terraform-aws-github-oidc/blob/main/LICENSE.txt)

## About The Project

This module wires GitHub Actions to AWS without long-lived credentials. It
manages the GitHub Actions OIDC identity provider
(`token.actions.githubusercontent.com`) and a set of IAM roles that workflows
assume with `sts:AssumeRoleWithWebIdentity`, each scoped to a single repository
and an explicit list of OIDC subjects — a branch, a tag pattern, a deployment
environment, or pull requests.

AWS allows exactly one OIDC provider per URL per account. The module owns that
singleton when `create_provider = true` (the default) and discovers the
existing one with a data source when it is `false`, so role-only instantiations
compose cleanly with an account that was bootstrapped elsewhere.

Every role's trust policy pins the audience to `sts.amazonaws.com` and matches
subjects with `StringLike` on `repo:<repository>:<subject>`, following the
[GitHub OIDC hardening guidance](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect).

## Usage

Bootstrap an account: create the provider and a role that lets a repository's
`main` branch deploy.

```hcl
module "github_oidc" {
  source  = "bendoerr-terraform-modules/github-oidc/aws"
  version = "x.x.x"
  context = module.context.shared

  roles = {
    deploy = {
      repository  = "my-org/my-infra"
      subjects    = ["ref:refs/heads/main"]
      policy_arns = ["arn:aws:iam::aws:policy/PowerUserAccess"]
    }
  }
}
```

Add scoped roles to an account that already has the provider — for example a
read-only plan role for pull requests and a tag-gated release role.

```hcl
module "github_oidc" {
  source  = "bendoerr-terraform-modules/github-oidc/aws"
  version = "x.x.x"
  context = module.context.shared

  create_provider = false

  roles = {
    plan = {
      repository  = "my-org/my-infra"
      subjects    = ["pull_request"]
      policy_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
    }
    release = {
      repository      = "my-org/my-app"
      subjects        = ["ref:refs/tags/v*"]
      inline_policies = { publish = data.aws_iam_policy_document.publish.json }
    }
  }
}
```

Workflows assume the role with
[`aws-actions/configure-aws-credentials`](https://github.com/aws-actions/configure-aws-credentials)
and `permissions: id-token: write`.

> 📖 **New to this org?** Read the
> [Module Usage Guide](MODULE-USAGE-GUIDE.md) to understand the context/label
> naming pattern used across all modules.

<!-- BEGIN_TF_DOCS -->

### Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement_aws) | ~> 6.10 |

### Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider_aws) | ~> 6.10 |

### Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_label"></a> [label](#module_label) | bendoerr-terraform-modules/label/null | 1.0.1 |
| <a name="module_label_role"></a> [label_role](#module_label_role) | bendoerr-terraform-modules/label/null | 1.0.1 |

### Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_openid_connect_provider.github](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_openid_connect_provider.github](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_openid_connect_provider) | data source |
| [aws_iam_policy_document.trust](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

### Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_context"></a> [context](#input_context) | Shared context from the 'bendoerr-terraform-modules/terraform-null-context' module. | <pre>object({<br/>    attributes     = list(string)<br/>    dns_namespace  = string<br/>    environment    = string<br/>    instance       = string<br/>    instance_short = string<br/>    namespace      = string<br/>    region         = string<br/>    region_short   = string<br/>    role           = string<br/>    role_short     = string<br/>    project        = string<br/>    tags           = map(string)<br/>  })</pre> | n/a | yes |
| <a name="input_create_provider"></a> [create_provider](#input_create_provider) | Whether to create the GitHub Actions OIDC identity provider. AWS allows a single provider per URL per account, so set this to false when the account already has one and it will be discovered with a data source instead. | `bool` | `true` | no |
| <a name="input_name"></a> [name](#input_name) | A descriptive but short name used for labels by the 'bendoerr-terraform-modules/terraform-null-label' module. | `string` | `"github-oidc"` | no |
| <a name="input_roles"></a> [roles](#input_roles) | IAM roles assumable by GitHub Actions through the OIDC provider, keyed by a short<br/>name used for the role's label. Each role trusts a single GitHub 'repository'<br/>('owner/name') and a list of 'subjects' — subject suffixes appended to<br/>'repo:<repository>:' in the trust policy's StringLike condition, for example<br/>'ref:refs/heads/main', 'ref:refs/tags/v\*', 'environment:production' or<br/>'pull_request'. The default '*' trusts every workflow in the repository.<br/>Permissions come from 'policy_arns' (attached managed policies) and<br/>'inline_policies' (a map of policy name to JSON document). | <pre>map(object({<br/>    repository           = string<br/>    subjects             = optional(list(string), \["*"\])<br/>    description          = optional(string)<br/>    policy_arns          = optional(list(string), \[\])<br/>    inline_policies      = optional(map(string), {})<br/>    max_session_duration = optional(number, 3600)<br/>    permissions_boundary = optional(string)<br/>    path                 = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_thumbprint_list"></a> [thumbprint_list](#input_thumbprint_list) | Server certificate thumbprints for the OIDC provider. AWS now validates GitHub's tokens against trusted root CAs and ignores these values, but the field is still required by the API. | `list(string)` | <pre>\[<br/>  "6938fd4d98bab03faadb97b34396831e3780aea1",<br/>  "1c58a3a8518e8759bf075b76b750d4f2df264fcd"<br/>\]</pre> | no |

### Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_id"></a> [id](#output_id) | The normalized ID from the 'bendoerr-terraform-modules/terraform-null-label' module. |
| <a name="output_name"></a> [name](#output_name) | The provided name given to the module. |
| <a name="output_oidc_provider_arn"></a> [oidc_provider_arn](#output_oidc_provider_arn) | ARN of the GitHub Actions OIDC identity provider, whether created by this module or discovered in the account. |
| <a name="output_roles"></a> [roles](#output_roles) | Created IAM roles keyed by the input role key, each with its arn, name and unique_id. |
| <a name="output_tags"></a> [tags](#output_tags) | The normalized tags from the 'bendoerr-terraform-modules/terraform-null-label' module. |

<!-- END_TF_DOCS -->

## Roadmap

[<img alt="GitHub issues" src="https://img.shields.io/github/issues/bendoerr-terraform-modules/terraform-aws-github-oidc?logo=github">](https://github.com/bendoerr-terraform-modules/terraform-aws-github-oidc/issues)

See the [open issues](https://github.com/bendoerr-terraform-modules/terraform-aws-github-oidc/issues) for a list of
proposed features (and known issues).

## Contributing

[<img alt="GitHub pull requests" src="https://img.shields.io/github/issues-pr/bendoerr-terraform-modules/terraform-aws-github-oidc?logo=github">](https://github.com/bendoerr-terraform-modules/terraform-aws-github-oidc/pulls)

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any
contributions you make are **greatly appreciated**.

- If you have suggestions for adding or removing projects, feel free to
  [open an issue](https://github.com/bendoerr-terraform-modules/terraform-aws-github-oidc/issues/new) to discuss it,
  or directly create a pull request after you edit the _README.md_ file with necessary changes.
- Please make sure you check your spelling and grammar.
- Create individual PR for each suggestion.

### Creating A Pull Request

1. Fork the Project
1. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
1. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
1. Push to the Branch (`git push origin feature/AmazingFeature`)
1. Open a Pull Request

## License

[<img alt="GitHub License" src="https://img.shields.io/github/license/bendoerr-terraform-modules/terraform-aws-github-oidc?logo=opensourceinitiative">](https://github.com/bendoerr-terraform-modules/terraform-aws-github-oidc/blob/main/LICENSE.txt)

Distributed under the MIT License. See
[LICENSE](https://github.com/bendoerr-terraform-modules/terraform-aws-github-oidc/blob/main/LICENSE.txt) for more
information.

## Authors

[<img alt="GitHub contributors" src="https://img.shields.io/github/contributors/bendoerr-terraform-modules/terraform-aws-github-oidc?logo=github">](https://github.com/bendoerr-terraform-modules/terraform-aws-github-oidc/graphs/contributors)

- **Benjamin R. Doerr** - _Terraformer_ - [Benjamin R. Doerr](https://github.com/bendoerr/) - _Built Ben's Terraform Modules_

## Supported Versions

Only the latest tagged version is supported.

## Reporting a Vulnerability

See [SECURITY.md](SECURITY.md).

## Acknowledgements

- [ShaanCoding (ReadME Generator)](https://github.com/ShaanCoding/ReadME-Generator)
- [OpenSSF - Helping me follow best practices](https://openssf.org/)
- [StepSecurity - Helping me follow best practices](https://app.stepsecurity.io/)
- [Infracost - Better than AWS Calculator](https://www.infracost.io/)

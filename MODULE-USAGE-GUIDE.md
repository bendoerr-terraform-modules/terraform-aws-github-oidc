# Module Usage Guide: The Context/Label Pattern

This guide explains the **context/label pattern** used across all
[bendoerr-terraform-modules](https://github.com/bendoerr-terraform-modules). If
you're contributing a new module or trying to understand how resource naming and
tagging works in this org, start here.

## Table of Contents

- [Overview](#overview)
- [How It Works](#how-it-works)
- [Real Example](#real-example)
- [Variable Conventions](#variable-conventions)
- [Troubleshooting](#troubleshooting)
- [Advanced Configuration](#advanced-configuration)
- [Best Practices](#best-practices)

## Overview

Every module in this org follows a two-layer naming pattern:

1. **`terraform-null-context`** — Defines the _environment context_: who you
   are, where you're deploying, and what role the account plays. Think of it as
   the "identity" of your deployment.

1. **`terraform-null-label`** — Takes that context and a resource `name` to
   produce a unique, consistent ID and a standard set of tags. Think of it as
   the "name tag factory."

**Why does this exist?**

- **Consistent naming** across every resource in every module — no more
  hand-crafted name strings that drift over time.
- **Automatic tagging** — Role, Region, Instance, Project, and Workspace tags
  are applied everywhere without manual effort.
- **Composability** — The context object flows from root module to child modules
  unchanged. Every module speaks the same language.
- **Short, readable IDs** — The pattern automatically shortens regions
  (`us-east-1` → `ue1`) and roles (`production` → `prod`) so resource names
  stay compact.

## How It Works

The flow looks like this:

```text
┌─────────────────────────────────┐
│   Root Module / Terragrunt      │
│                                 │
│   module "context" {            │
│     source = "...context"       │
│     namespace  = "brd"          │
│     role       = "production"   │
│     region     = "us-east-1"    │
│   }                             │
└──────────┬──────────────────────┘
           │ context.shared (object)
           ▼
┌─────────────────────────────────┐
│   Your Module                   │
│                                 │
│   variable "context" {}         │  ← receives the shared context
│                                 │
│   module "label" {              │
│     source  = "...label"        │
│     context = var.context       │  ← passes context through
│     name    = "my-bucket"       │  ← adds a resource-specific name
│   }                             │
│                                 │
│   module.label.id   →           │  "brd-prod-ue1-my-bucket"
│   module.label.tags →           │  { Role = "production", ... }
└─────────────────────────────────┘
```

### Step 1: Create the Context

The
[terraform-null-context](https://github.com/bendoerr-terraform-modules/terraform-null-context)
module accepts high-level inputs and produces a `shared` output object:

```hcl
module "context" {
  source  = "bendoerr-terraform-modules/context/null"
  version = "0.5.0"

  namespace = "brd"          # Short identifier (e.g., your initials)
  role      = "production"   # Account role: production, development, etc.
  region    = "us-east-1"    # AWS region (or any provider region)
  project   = "web-app"      # Optional project name
}
```

The context module automatically:

- Shortens `role` → `role_short` (e.g., `production` → `prod`,
  `development` → `dev`)
- Shortens `region` → `region_short` (e.g., `us-east-1` → `ue1`)
- Builds an `environment` string: `prod-ue1`
- Builds a `dns_namespace`: `ue1` (or `mn.ue1` if an instance is set)
- Generates standard tags: `Role`, `Region`, `Instance`, `Project`, `Workspace`

The key output is **`module.context.shared`** — an object containing all of
these computed values, ready to pass to child modules.

### Step 2: Pass Context to Your Module

Every module in this org declares a `context` variable with a specific shape:

```hcl
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
```

Callers pass the context through:

```hcl
module "my_module" {
  source  = "bendoerr-terraform-modules/my-module/aws"
  version = "1.0.0"

  context = module.context.shared   # ← the whole context object
  name    = "api"                   # ← resource-specific name
}
```

### Step 3: Generate Labels

Inside your module, the
[terraform-null-label](https://github.com/bendoerr-terraform-modules/terraform-null-label)
module consumes the context and produces naming outputs:

```hcl
module "label" {
  source  = "bendoerr-terraform-modules/label/null"
  version = "1.0.0"

  context = var.context
  name    = var.name
}
```

The label module wraps
[cloudposse/label/null](https://github.com/cloudposse/terraform-null-label)
under the hood, mapping the context fields to Cloud Posse's label inputs:

| Context Field  | Label Input   | Example        |
| -------------- | ------------- | -------------- |
| `namespace`    | `namespace`   | `brd`          |
| `environment`  | `environment` | `prod-ue1`     |
| `project`      | `stage`       | `web-app`      |
| `name` (param) | `name`        | `api`          |
| `attributes`   | `attributes`  | `["blue"]`     |
| `tags`         | `tags`        | `{Role = ...}` |

The resulting `module.label.id` follows the pattern:

```text
<namespace>-<environment>-<project>-<name>(-<attributes>)
brd-prod-ue1-web-app-api
brd-prod-ue1-web-app-api-blue    # with attributes
```

## Real Example

Here's a complete, working example — an S3 bucket module that follows the
pattern.

**Root module (`main.tf`):**

```hcl
module "context" {
  source  = "bendoerr-terraform-modules/context/null"
  version = "0.5.0"

  namespace = "brd"
  role      = "production"
  region    = "us-east-1"
  project   = "media"
}

module "assets_bucket" {
  source = "./modules/s3-bucket" # the module you build from this template

  context = module.context.shared
  name    = "assets"
}
```

**Inside the S3 bucket module:**

```hcl
# variables.tf
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
  description = "Name for the S3 bucket label."
  nullable    = false
}

# main.tf
module "label" {
  source  = "bendoerr-terraform-modules/label/null"
  version = "1.0.0"
  context = var.context
  name    = var.name
}

resource "aws_s3_bucket" "this" {
  bucket = module.label.id    # → "brd-prod-ue1-media-assets"
  tags   = module.label.tags  # → { Name = "brd-prod-ue1-media-assets",
                              #      Role = "production",
                              #      Region = "us-east-1",
                              #      Project = "media",
                              #      Workspace = "default", ... }
}

# outputs.tf
output "id" {
  value       = module.label.id
  description = "The normalized ID from the label module."
}

output "tags" {
  value       = module.label.tags
  description = "The normalized tags from the label module."
}
```

**What the caller sees:**

```text
module.assets_bucket.id   = "brd-prod-ue1-media-assets"
module.assets_bucket.tags = {
  Instance  = ""
  Name      = "brd-prod-ue1-media-assets"
  Project   = "media"
  Region    = "us-east-1"
  Role      = "production"
  Workspace = "default"
}
```

## Variable Conventions

### The `context` Variable

Every module **must** declare a `context` variable with the exact object type
shown above. This is the contract between modules.

| Field            | Type           | Purpose                                   |
| ---------------- | -------------- | ----------------------------------------- |
| `namespace`      | `string`       | Global uniqueness prefix (e.g., initials) |
| `environment`    | `string`       | Computed: `<role_short>-<region_short>`   |
| `role`           | `string`       | Account role: `production`, `development` |
| `role_short`     | `string`       | Auto-shortened role: `prod`, `dev`        |
| `region`         | `string`       | Full region: `us-east-1`                  |
| `region_short`   | `string`       | Auto-shortened region: `ue1`              |
| `instance`       | `string`       | Optional: blue/green or tenant identifier |
| `instance_short` | `string`       | Auto-shortened instance                   |
| `project`        | `string`       | Project or application name               |
| `dns_namespace`  | `string`       | DNS-friendly namespace fragment           |
| `attributes`     | `list(string)` | Additional ID segments                    |
| `tags`           | `map(string)`  | Additional tags merged into all resources |

### The `name` Variable

Every module declares a `name` variable — a short, descriptive name for the
specific resource. This is the only thing that changes between different
resources in the same context.

```hcl
variable "name" {
  type        = string
  default     = "thing"
  description = "A descriptive but short name used for labels."
  nullable    = false
}
```

**Naming rules** (enforced by the label module):

- Lowercase alphanumeric and hyphens only: `^[a-z0-9]([a-z0-9-]*[a-z0-9])?$`
- 1–32 characters
- Cannot start or end with a hyphen

### Passing Context Between Modules

The context flows as a single object — no need to decompose it:

```hcl
# ✅ Correct: pass the whole shared object
module "child" {
  source  = "..."
  context = module.context.shared
  name    = "child-resource"
}

# ❌ Wrong: don't manually construct the context
module "child" {
  source      = "..."
  namespace   = "brd"
  environment = "prod-ue1"
  # ... this defeats the purpose
}
```

### DNS Names

The label module also produces a `dns_name` output:

```text
<name>.<project>.<dns_namespace>
assets.media.ue1
```

This is useful for Route 53 records or service discovery.

## Troubleshooting

### "Missing context" Errors

**Symptom:** `The argument "context" is required, but no definition was found.`

**Fix:** Make sure you're passing `module.context.shared`, not `module.context`:

```hcl
# ✅ Correct
context = module.context.shared

# ❌ Wrong — this is the module reference, not the output object
context = module.context
```

### Unexpected ID Format

**Symptom:** The generated ID doesn't match what you expected.

**Check:** The label module constructs the ID as
`<namespace>-<environment>-<project>-<name>-<attributes>`. Empty segments are
omitted. If `project` is empty, you'll get `brd-prod-ue1-api` instead of
`brd-prod-ue1--api`.

### Context Type Mismatch

**Symptom:**
`Inappropriate value for attribute "context": ... is required.`

**Fix:** The context object has a strict type. All fields must be present, even
if empty. The context module's `shared` output guarantees this. If you're
constructing a context manually (not recommended), ensure every field is
populated:

```hcl
# If you must construct manually, include ALL fields:
context = {
  attributes     = []
  dns_namespace  = ""
  environment    = "prod-ue1"
  instance       = ""
  instance_short = ""
  namespace      = "brd"
  region         = "us-east-1"
  region_short   = "ue1"
  role           = "production"
  role_short     = "prod"
  project        = ""
  tags           = {}
}
```

### Tags Not Appearing

**Symptom:** Resources are missing expected tags.

**Check:** Make sure you're using `module.label.tags` (not `var.context.tags`).
The label module merges context tags with computed tags (Name, Role, Region,
etc.). Using `var.context.tags` directly skips the label module's tag
enrichment.

### Label Validation Failures

**Symptom:** `name must contain only lowercase alphanumeric characters and hyphens`

**Fix:** The `name` variable is validated by the label module. Use only
lowercase letters, numbers, and hyphens. No underscores, spaces, or uppercase.

## Advanced Configuration

### Overriding the Project Per-Module

The label module accepts its own `project` variable that overrides the context's
project:

```hcl
module "label" {
  source  = "bendoerr-terraform-modules/label/null"
  version = "1.0.0"
  context = var.context
  name    = "cache"
  project = "auth-service"   # Overrides context.project
}
# ID: brd-prod-ue1-auth-service-cache
```

### Using Attributes for Variants

Attributes add extra segments to the ID. Useful for blue/green deployments or
resource variants:

```hcl
module "context" {
  source  = "bendoerr-terraform-modules/context/null"
  version = "0.5.0"

  namespace  = "brd"
  role       = "production"
  region     = "us-east-1"
  attributes = ["blue"]
}
# IDs will end with: ...-blue
```

### Instance-Based Naming

The `instance` variable is for multi-tenant or blue/green scenarios:

```hcl
module "context" {
  source  = "bendoerr-terraform-modules/context/null"
  version = "0.5.0"

  namespace = "brd"
  role      = "production"
  region    = "us-east-1"
  instance  = "main"
}
# environment: prod-ue1-mn
# dns_namespace: mn.ue1
```

### Custom Tags

Pass additional tags through the context:

```hcl
module "context" {
  source  = "bendoerr-terraform-modules/context/null"
  version = "0.5.0"

  namespace = "brd"
  role      = "production"
  region    = "us-east-1"
  tags = {
    CostCenter = "engineering"
    ManagedBy  = "terraform"
  }
}
# All downstream modules will inherit these tags
```

### Environment-Specific Naming

For different environments, create separate contexts:

```hcl
module "prod_context" {
  source    = "bendoerr-terraform-modules/context/null"
  version   = "0.5.0"
  namespace = "brd"
  role      = "production"
  region    = "us-east-1"
}

module "dev_context" {
  source    = "bendoerr-terraform-modules/context/null"
  version   = "0.5.0"
  namespace = "brd"
  role      = "development"
  region    = "us-west-2"
}

# prod: brd-prod-ue1-...
# dev:  brd-dev-uw2-...
```

## Best Practices

### Do

- ✅ **Always use `module.context.shared`** to pass context — never construct
  the object manually.
- ✅ **Always use `module.label.id` for resource names** and
  `module.label.tags` for tags.
- ✅ **Keep `name` short and descriptive** — it's a label, not a sentence.
  `"api"`, `"cache"`, `"assets"` — not `"my-application-api-server-v2"`.
- ✅ **Expose `id` and `tags` as outputs** from your module so callers can
  reference them.
- ✅ **Use the exact `context` variable type** from this guide — don't add or
  remove fields.
- ✅ **Use `dns_name` output** for DNS records instead of building DNS names
  manually.

### Don't

- ❌ **Don't hardcode resource names** — use the label module.
- ❌ **Don't manually construct environment strings** like `"prod-ue1"` — let
  the context module compute them.
- ❌ **Don't use `var.context.tags` directly on resources** — use
  `module.label.tags` which includes the computed Name tag.
- ❌ **Don't skip the label module** even for "simple" resources — consistency
  matters more than convenience.
- ❌ **Don't put uppercase, underscores, or spaces in `name`** — the label
  module will reject them.
- ❌ **Don't override `environment` in the context module** unless you have a
  specific reason — the auto-computed value is the convention.

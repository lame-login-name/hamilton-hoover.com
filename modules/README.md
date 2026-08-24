# modules/ — Reusable Terraform Modules

The vetted building blocks for this platform. Anything created in the org goes through a
module here rather than being written inline, so the guardrails live in one place instead
of being re-derived every time.

## Available modules

| Module | Purpose |
|---|---|
| [`project`](project) | Project factory. Every GCP project in the org is created through it. |

That's the whole list right now. Modules get added when there's a second real consumer for
the pattern, not in anticipation of one.

## `project`

The platform contract. It guarantees that every project, regardless of who asked for it:

- has `auto_create_network = false` (no default VPC, ever)
- has the baseline APIs enabled — `cloudresourcemanager`, `iam`, `logging`, `monitoring`
- carries the full label set: `env`, `owner`, `purpose`, `cost_center`, `managed-by`
- is attached to billing and parented to a real folder

```hcl
module "logging_project" {
  source = "../../modules/project"

  project_id         = "hh-logging-nonprod"
  project_name       = "HH Logging Nonprod"
  folder_id          = var.shared_services_folder_id
  billing_account_id = var.billing_account_id
  environment        = "nonprod"
  purpose            = "audit-logging"

  activate_apis = [
    "bigquery.googleapis.com",
    "bigquerystorage.googleapis.com",
  ]
}
```

`environment` is validated against `prod | nonprod | sandbox | shared | platform`, so a typo
fails at plan time rather than producing a mislabeled project that quietly escapes the
budget filters.

### Depending on module-enabled APIs

The module's outputs expose data, not the API-enablement dependency. If a resource outside
the module needs an API that the module turns on, reference the module explicitly:

```hcl
resource "google_bigquery_dataset" "example" {
  project = module.logging_project.project_id
  # ...
  depends_on = [module.logging_project]
}
```

Without it, Terraform parallelizes the resource against `google_project_service` and loses
the race. This has bitten this repo once already.

## Conventions for new modules

Standard file layout: `main.tf`, `variables.tf`, `outputs.tf`, `README.md`. Every variable
gets a `description`. Constraints that can be checked at plan time should be `validation`
blocks rather than documentation.

Modules encode policy, they don't just save typing. If a module makes an unsafe
configuration easy to express, it isn't finished.

# infrastructure/ — Shared Infrastructure Layer

Shared services that support the whole org but aren't workloads themselves: centralized
logging, and later DNS and networking. Projects here are created through
[`modules/project`](../modules/project) and land in the `shared-services` folder.

CI-managed by [`terraform-infrastructure.yml`](../.github/workflows/terraform-infrastructure.yml)
using the `tf-infra` service account, which is scoped to the `shared-services` folder only.

## Layout

```
infrastructure/
└── nonprod/                    # Non-production shared services
    ├── main.tf                 # GCS backend (prefix: infrastructure/nonprod), provider
    ├── logging.tf              # Logging project, BigQuery dataset, org audit log sink
    ├── variables.tf
    ├── ci.auto.tfvars          # Non-sensitive values, auto-loaded in CI
    └── terraform.tfvars.example
```

`prod/` will be added once the nonprod pattern has run long enough to trust. The intent is
that it mirrors `nonprod/` with longer log retention, not that it grows its own shape.

## What's deployed

| Resource | Detail |
|---|---|
| `hh-logging-nonprod` project | In `shared-services`, created via `modules/project` |
| BigQuery dataset `audit_logs` | US multi-region, 7-day partition and table expiry |
| Org log sink `org-audit-to-bq-nonprod` | `include_children = true`, routes to the dataset |
| Sink writer IAM | `roles/bigquery.dataEditor` on the dataset for the sink's writer identity |

### Log sink scope

The sink filter captures Admin Activity and Policy Denied logs only. Data Access logs are
deliberately excluded — the volume is unbounded once it's enabled for any chatty service,
and an allowlist-with-exclusions approach is one new service away from a surprise bill.
See the comments in [`logging.tf`](nonprod/logging.tf) for the full reasoning.

Retention is short by design. This is an audit trail for a personal org, not a compliance
archive; `audit_log_retention_days` controls the window.

## Running locally

CI handles the normal path. If you need a local run:

```bash
cd infrastructure/nonprod
cp terraform.tfvars.example terraform.tfvars   # fill in billing_account_id
gcloud auth application-default login
terraform init
terraform plan
```

`ci.auto.tfvars` is committed and loads automatically, so `terraform.tfvars` only needs the
sensitive values that aren't in the repo.

## Related

- [`modules/project`](../modules/project) — the factory every project here goes through
- [`org/`](../org) — the policies these projects inherit
- [`bootstrap/`](../bootstrap) — where `tf-infra` and its folder-scoped roles are defined

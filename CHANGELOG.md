# Changelog

All notable changes to this GCP organization platform are documented here.
Entries are grouped by phase and ordered newest-first within each section.

Format loosely follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [Unreleased]

### Planned — Phase 4 (continued)
- `infrastructure/prod/` — prod logging sink with longer retention (30 days)
- Shared VPC / networking layer
- `tf-projects` service account and project factory CI pipeline

---

## Phase 4 — Platform Foundation

### 2026-05-18

#### Fixed — BigQuery API race condition (`fix/bigquery-depends-on` → PR #16)
- `google_bigquery_dataset.audit_logs` was racing against `bigquery.googleapis.com`
  API activation. Terraform only saw the `project_id` reference, so it parallelised
  dataset creation with API enablement and lost the race with a 400 error.
- Added `depends_on = [module.logging_project]` to serialize the operation.
- Root cause: module outputs only expose data values; they don't implicitly encode
  the dependency on `google_project_service` resources inside the module.

#### Fixed — Sink filter tightened to Admin Activity + Policy Denied only (PR #17)
- **Removed** `cloudaudit.googleapis.com/data_access` from the org log sink filter.
- The previous filter included Data Access logs with a denylist of noisy methods
  (storage reads, serial port, monitoring polls). Denylist approach is fragile —
  one new chatty service bypasses it and drives unexpected BigQuery storage costs.
- Data Access logging is opt-in per service in the org audit config and is **not**
  enabled in this org; the branch was capturing zero rows while creating a latent
  cost risk for the future.
- New filter captures only what matters for a personal org:
  - **Admin Activity**: IAM changes, resource CRUD, billing/org config. Always-on,
    free to generate, fires only when Terraform runs or someone acts in the console.
  - **Policy Denied**: org policy rejections. Low volume, high signal.
- Fixed stale dataset description: "30-day retention" → "7-day default".

#### Added — GitHub Actions workflow for infrastructure layer (`terraform-infrastructure.yml`)
- Triggers on changes to `infrastructure/**`, `modules/**`, and the workflow file itself.
- Jobs: `fmt` → `validate-nonprod` → `plan-nonprod` (PR only) → `apply-nonprod` (merge to main).
- `plan-nonprod` posts full plan as a collapsible PR comment (truncates at 60 000 chars).
- `apply-nonprod` gated by the `apply` GitHub Environment (required reviewer).
- Sensitive `billing_account_id` injected at runtime from a GitHub Actions variable into
  a temp tfvars file (`/tmp/ci-sensitive.tfvars`). Never written to disk in the repo.
- Timeout guards: plan 15 min, apply 30 min. Added after a 54-minute hang caused by
  an em dash in a GCP project name (API rejected it; provider retried indefinitely).

#### Added — `tf-infra` service account (`bootstrap/wif.tf`)
- Separate SA scoped to the infrastructure layer; `tf-org` remains org-wide.
- IAM grants: folder-level `projectCreator`, `projectDeleter`, `editor`, `bigquery.admin`
  on the `shared-services` folder; org-level `logging.configWriter`; billing `billing.user`.
- WIF binding scoped to `lame-login-name/hamilton-hoover.com`.
- GCS state `objectAdmin` on the org tfstate bucket.
- `tf_infra_sa_email` added to `bootstrap/outputs.tf`.

#### Added — `modules/project` — project factory module
- Single entry point for every GCP project in the org. Enforces:
  - `auto_create_network = false` (no default VPC ever)
  - Baseline APIs always enabled: `cloudresourcemanager`, `iam`, `logging`, `monitoring`
  - Consistent label schema: `env`, `owner`, `purpose`, `cost_center`, `managed-by`
- Variables: `project_id`, `project_name`, `folder_id`, `billing_account_id`,
  `environment` (validated enum), `purpose`, `activate_apis`, `labels`.
- Outputs: `project_id`, `project_number`.

#### Added — Centralized logging project (`infrastructure/nonprod/logging.tf`)
- `hh-logging-nonprod` project in the `shared-services` folder via `modules/project`.
- BigQuery dataset `audit_logs` (US multi-region, 7-day partition + table expiry).
- Org-level log sink (`org-audit-to-bq-nonprod`, `include_children = true`) routing
  to the dataset with partitioned tables enabled.
- Sink IAM: sink's auto-provisioned writer identity granted `roles/bigquery.dataEditor`.
- `delete_contents_on_destroy = false` on the dataset — safety guard against `tf destroy`
  silently wiping audit history.

#### Added — `infrastructure/nonprod` layer scaffolding
- GCS backend (`hh-org-tfstate`, prefix `infrastructure/nonprod`).
- Provider configured with `billing_project` + `user_project_override = true` to avoid
  quota issues on org-scoped API calls.
- `ci.auto.tfvars`: non-sensitive values committed (`organization_id`,
  `bootstrap_project_id`, `shared_services_folder_id`). Auto-loaded by Terraform in CI.
- `infrastructure/.gitignore` — added `!*.auto.tfvars` exception; the existing
  `*.tfvars` rule was silently blocking `ci.auto.tfvars` from being committed.
- `audit_log_retention_days` variable (default: 7 for nonprod cost control).

#### Lessons learned (Phase 4)
- **GCP API activation is eventually consistent.** Always add `depends_on = [module]`
  on resources that use APIs enabled inside that module. The module output alone is not
  a sufficient dependency signal.
- **Denylist filtering is a cost trap.** For log sinks on a personal org, use a tight
  allowlist (specific `log_id()` values) rather than an allowlist-with-exclusions.
- **`*.auto.tfvars` gitignore interaction is non-obvious.** A directory-level `.gitignore`
  overrides the parent; any `*.tfvars` rule must be paired with a `!*.auto.tfvars` exception
  at the same level.
- **Job timeout guards are mandatory.** GCP provider retry loops on API errors can run
  indefinitely. Discovered via 54-minute hang. Set `timeout-minutes` on every plan/apply job.
- **GCP project name character set is strict.** ASCII letters, numbers, spaces, hyphens,
  and apostrophes only. Em dashes (—) are silently rejected by the API.

---

## Phase 3 — Security Hardening

### 2026-05-17

#### Fixed — PII and billing account ID removed from git history
- Scrubbed four sensitive patterns from all commits using `git filter-repo`:
  billing account ID, org admin email, Cloud Identity customer ID, and the
  raw customer ID variant.
- Replaced with `REDACTED` placeholders in historical commits.
- Moved all secrets to GitHub Actions variables injected at CI runtime.
- Force-push to main required; branch protection temporarily removed and restored.

#### Added — Documentation refresh (`docs/update-readmes`)
- `README.md` updated to reflect actual deployed state: org layer live, infrastructure
  layer in Phase 4.
- `instructions.md` updated with current phase roadmap, GitHub Actions variable list,
  and local run instructions.

### 2026-05-16 — 2026-05-17

#### Added — IAM member domain restriction (PR #11, #12)
- `iam.allowedPolicyMemberDomains` org policy restricts all IAM bindings to the
  Cloud Identity tenant.
- Constraint value format: bare `customerID` (e.g. `C013m3fwu`), not `directoryCustomerId:`.
- Iteration required: first attempt used wrong format; fixed after testing against GCP API.
- Effect: no external (gmail, other domain) accounts can be added to any IAM binding
  in the org.

#### Added — Org perimeter hardening (PR #10)
- **Public access prevention**: `storage.publicAccessPrevention` org policy — all GCS
  buckets in the org block public access at the org level regardless of bucket ACLs.
- **Audit logging config** (`org/audit.tf`): `DATA_READ`, `DATA_WRITE`, `ADMIN_READ`
  enabled for `allServices` at org level. Ensures all API activity is captured in
  Cloud Logging.

---

## Phase 2 — CI/CD Pipeline

### 2026-05-16

#### Added — WIF bootstrap and GitHub Actions org pipeline (PR #9)
- Workload Identity Federation pool (`github-wif-pool`) and OIDC provider bound to
  `lame-login-name/hamilton-hoover.com`.
- `tf-org` service account with org-level IAM: `resourcemanager.organizationAdmin`,
  `billing.admin`, `orgpolicy.policyAdmin`, `logging.admin`, `iam.organizationRoleAdmin`.
- GitHub Actions workflow `terraform-org.yml`: `fmt` → `validate` → `plan` (PR) →
  `apply` (merge to main, gated by `apply` environment with required reviewer).
- No long-lived credentials anywhere — all auth via short-lived OIDC tokens.
- Non-sensitive org values (`organization_id`, `bootstrap_project_id`) committed in
  `org/ci.auto.tfvars` and auto-loaded by Terraform. Sensitive values (billing account,
  admin members) injected at runtime from GitHub Actions variables.

### 2026-05-13

#### Fixed — Provider v6 billing.tf compatibility (PR #8)
- `google_billing_budget` resource schema changed in provider v6; updated attribute
  names and structure to match.

---

## Phase 1 — Org Layer Foundation

### 2026-05-12

#### Added — `org/` layer: folders, policies, IAM, budgets, audit config
- **`org/folders.tf`**: five-folder hierarchy under the org root:
  `platform`, `shared-services`, `nonprod`, `prod`, `sandbox`.
- **`org/org-policies.tf`**: nine OrgPolicy v2 constraints enforced at org root:

  | Constraint | Effect |
  |---|---|
  | `compute.skipDefaultNetworkCreation` | No default VPC on new projects |
  | `compute.requireOsLogin` | OS Login required on all VMs |
  | `compute.vmExternalIpAccess` | No external IPs on VMs |
  | `sql.restrictPublicIp` | No public IPs on Cloud SQL |
  | `iam.disableServiceAccountKeyCreation` | No SA key downloads |
  | `storage.uniformBucketLevelAccess` | Uniform ACLs on all GCS buckets |
  | `storage.publicAccessPrevention` | No public GCS buckets |
  | `gcp.resourceLocations` | US regions only |
  | `iam.allowedPolicyMemberDomains` | IAM restricted to Cloud Identity tenant |

- **`org/org-iam.tf`**: org-level IAM bindings (additive) for human admin account.
- **`org/billing.tf`**: three billing budgets with email alerting:
  - Org total: alert at $10, $25, $50
  - Per-project alerts at lower thresholds
- **`org/audit.tf`**: Data Access audit config for `allServices`.
- GCS remote backend: `hh-org-tfstate`, prefix `org`.
- Provider: `billing_project` + `user_project_override = true` to avoid quota errors
  on org-scoped API calls.

### 2026-04-18

#### Added — `instructions.md`
- Build guide covering phase roadmap, local run instructions, and design rationale.

---

## Phase 0 — Initial Scaffolding

### 2025-08-19 — 2025-08-20

#### Added — Repository structure and environment separation (PR #6, #7)
- Separated infrastructure into `infrastructure/nonprod/` and `infrastructure/prod/`
  to enforce blast-radius isolation.
- `projects/` directory restructured by environment with sample project configurations.
- Root `.gitignore` added for Terraform state, tfvars, plan files, and OS artifacts.

### 2025-08-01 — 2025-08-05

#### Added — Initial Terraform scaffolding (PR #1, #2)
- Initial GCP organization management structure: folder hierarchy, networking stubs,
  variable skeletons.
- Prod/nonprod infrastructure separation with blast-radius rationale documented.
- Bootstrap layer placeholder.

### 2025-07-31

#### Added — Repository initialized
- `hamilton-hoover.com` repository created under `lame-login-name`.
- Initial commit: project intent and directory skeleton.

---

## Guiding principles (recorded here for longevity)

- **Everything is code.** If it isn't in Git, it doesn't exist.
- **CI/CD enforces correctness, not speed.** Every merge to main runs a full plan + apply.
- **Cost discipline is a feature.** Budgets and alerts exist before workloads.
- **Least privilege by default.** Scope widens only with justification and a code review.
- **No clickops.** No manual IAM changes, no manual project creation, no unmanaged resources.
- **Personal org ≠ toy.** Built to the same standard as an enterprise platform, just smaller.

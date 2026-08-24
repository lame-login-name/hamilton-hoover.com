# hamilton-hoover.com: GCP Organization Platform

My personal Google Cloud organization, managed as code. Aside from the initial bootstrap, nothing here was clicked together in the console.

I built this because I wanted a place to run the same patterns I use professionally without a change advisory board in the way: org policy inheritance, Workload Identity Federation instead of service account keys, budgets wired up before any workload exists. It's small, but the structure is what I'd actually stand up at work.

This is a work in progress. The foundation is solid and CI-managed, but workloads, shared networking, and the project factory are still being built out. The intent is to mature it progressively — each phase adds real infrastructure, not placeholder code.

## What's deployed

| Layer | Directory | State |
|---|---|---|
| WIF + CI service accounts | `bootstrap/` | Applied manually (once) |
| Org structure, policies, IAM, budgets | `org/` | CI-managed |
| Shared networking, DNS | `infrastructure/` | Planned, Phase 4 |
| Project factory | `projects/` | Planned, Phase 4 |
| Reusable modules | `modules/` | Planned, Phase 4 |

## Repository layout

```
hamilton-hoover.com/
├── bootstrap/                 # Workload Identity Federation + tf-org service account
│   ├── main.tf                # GCS backend (prefix: bootstrap)
│   ├── wif.tf                 # WIF pool, GitHub OIDC provider, SA, IAM bindings
│   ├── variables.tf
│   ├── outputs.tf             # wif_provider, tf_org_sa_email → GitHub Actions vars
│   └── terraform.tfvars.example
├── org/                       # Organization layer, CI applies on every merge to main
│   ├── main.tf                # GCS backend (prefix: org), provider config
│   ├── folders.tf             # Folder hierarchy: platform, shared-services, nonprod, prod, sandbox
│   ├── org-policies.tf        # 9 org policies (OrgPolicy v2)
│   ├── org-iam.tf             # Org-level IAM (additive) for human admin
│   ├── billing.tf             # 3 billing budgets with alerting thresholds
│   ├── audit.tf               # Data Access audit logging (allServices)
│   ├── variables.tf
│   ├── ci.auto.tfvars         # Non-sensitive values auto-loaded in CI
│   └── terraform.tfvars.example
├── .github/
│   └── workflows/
│       └── terraform-org.yml  # fmt → validate → plan (PR) → apply (merge)
└── instructions.md            # Build guide and phase roadmap
```

## CI/CD pipeline

Every PR against `org/**` runs:

1. **fmt**: `terraform fmt -check`
2. **validate**: `terraform validate`, authenticating via WIF
3. **plan**: posts the plan as a PR comment
4. **apply**: runs on merge to `main`, gated by the `apply` GitHub Environment with a required reviewer

Authentication goes through Workload Identity Federation, so there are no long-lived keys stored anywhere. Fork PRs are blocked from triggering CI.

## Folder hierarchy

```
Organization (hamilton-hoover.com)
├── platform          # Platform engineering projects
├── shared-services   # Shared tooling (logging, DNS, CI support)
├── nonprod           # Development and staging workloads
├── prod              # Production workloads
└── sandbox           # Experimental / throwaway projects
```

## Security posture (org-wide)

These are enforced at the org root through OrgPolicy v2 and inherited by every folder and project underneath:

| Policy | Constraint |
|---|---|
| No default VPC on project creation | `compute.skipDefaultNetworkCreation` |
| OS Login required on all VMs | `compute.requireOsLogin` |
| No external IPs on VMs | `compute.vmExternalIpAccess` (deny all) |
| No public IPs on Cloud SQL | `sql.restrictPublicIp` |
| No service account key creation | `iam.disableServiceAccountKeyCreation` |
| Uniform bucket-level access | `storage.uniformBucketLevelAccess` |
| Public access prevention on GCS | `storage.publicAccessPrevention` |
| US regions only | `gcp.resourceLocations` |
| IAM members restricted to Cloud Identity tenant | `iam.allowedPolicyMemberDomains` |

Data Access audit logs (ADMIN_READ, DATA_READ, DATA_WRITE) are on for all services.

## Running it locally

CI handles the normal path, so local runs are rare. If you need one:

```bash
cd org/
cp terraform.tfvars.example terraform.tfvars
# Fill in cloud_identity_customer_id and any overrides
gcloud auth application-default login
terraform init
terraform plan
```

The `bootstrap/` layer gets applied by hand and changes maybe once a year:

```bash
cd bootstrap/
cp terraform.tfvars.example terraform.tfvars
# Fill in all values
terraform init
terraform apply
# Copy wif_provider and tf_org_sa_email outputs to GitHub Actions → Variables
```

## How I work in this repo

A few rules I hold myself to here:

- If it isn't in Git, it doesn't exist. Anything I can't rebuild from this repo doesn't belong in the org.
- Budgets get set before workloads, not after the first surprise bill.
- Permissions start narrow. Widening them requires a reason I'd be willing to defend in a review.
- No manual IAM edits, no manual project creation. Drift gets treated as a bug.

## A note on tooling

I used Claude to help write and review a good portion of the Terraform and workflow code here. The architecture, the policy choices, and the decisions about what belongs in which layer are mine. Claude was useful for getting from a design I had in my head to working HCL faster than I would have on my own, and for catching things in review. Seemed worth saying plainly rather than leaving it implied.

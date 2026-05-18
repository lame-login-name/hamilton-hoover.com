# hamilton-hoover.com — GCP Organization Platform

Personal GCP organization managed entirely as code. No clickops beyond the initial bootstrap.
Built as a real platform — governed, automated, and cost-disciplined — not a demo.

## What's deployed

| Layer | Directory | State |
|---|---|---|
| WIF + CI service accounts | `bootstrap/` | Applied manually (once) |
| Org structure, policies, IAM, budgets | `org/` | CI-managed |
| Shared networking, DNS | `infrastructure/` | Planned — Phase 4 |
| Project factory | `projects/` | Planned — Phase 4 |
| Reusable modules | `modules/` | Planned — Phase 4 |

## Repository layout

```
hamilton-hoover.com/
├── bootstrap/                 # Workload Identity Federation + tf-org service account
│   ├── main.tf                # GCS backend (prefix: bootstrap)
│   ├── wif.tf                 # WIF pool, GitHub OIDC provider, SA, IAM bindings
│   ├── variables.tf
│   ├── outputs.tf             # wif_provider, tf_org_sa_email → GitHub Actions vars
│   └── terraform.tfvars.example
├── org/                       # Organization layer — CI applies on every merge to main
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

Every PR against `org/**` triggers:
1. **fmt** — `terraform fmt -check`
2. **validate** — `terraform validate` (authenticates via WIF, no keys)
3. **plan** — posts the plan as a PR comment
4. **apply** — runs on merge to `main`, gated by the `apply` GitHub Environment (required reviewer)

Authentication uses Workload Identity Federation — no long-lived keys anywhere.

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

All policies enforced at org root via OrgPolicy v2 and inherited by every folder and project:

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

Data Access audit logs (ADMIN_READ, DATA_READ, DATA_WRITE) enabled on all services.

## Getting started locally

Local runs are rarely needed — CI handles everything. If you need to run locally:

```bash
cd org/
cp terraform.tfvars.example terraform.tfvars
# Fill in cloud_identity_customer_id and any overrides
gcloud auth application-default login
terraform init
terraform plan
```

The `bootstrap/` layer is applied manually and almost never changes:

```bash
cd bootstrap/
cp terraform.tfvars.example terraform.tfvars
# Fill in all values
terraform init
terraform apply
# Copy wif_provider and tf_org_sa_email outputs to GitHub Actions → Variables
```

## Guiding principles

- Everything is code. If it isn't in Git, it doesn't exist.
- CI/CD enforces correctness, not speed.
- Cost discipline is a feature — budgets are set before workloads.
- Least privilege by default. Scope widens only with justification.
- No manual IAM changes, no manual project creation, no unmanaged resources.

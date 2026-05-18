# org/ — Organization Layer

Manages the GCP organization root: folder structure, org policies, IAM, billing budgets,
and audit logging. Applied automatically by GitHub Actions on every merge to `main`.

## Files

| File | What it manages |
|---|---|
| `main.tf` | GCS remote backend (`hh-org-tfstate/org`), provider config |
| `folders.tf` | Five top-level folders under the org root |
| `org-policies.tf` | Nine organization policies (OrgPolicy v2) |
| `org-iam.tf` | Org-level IAM bindings for the human admin (additive) |
| `billing.tf` | Three billing budgets with 50/80/100% alert thresholds |
| `audit.tf` | Data Access audit logging for all GCP services |
| `variables.tf` | All input variables |
| `ci.auto.tfvars` | Non-sensitive values committed for CI auto-load |
| `terraform.tfvars.example` | Template for local `terraform.tfvars` (gitignored) |

## Folder hierarchy

| Folder | ID | Purpose |
|---|---|---|
| platform | `35099315380` | Platform engineering tooling |
| shared-services | `959737491214` | Shared logging, DNS, CI support |
| nonprod | `794298776125` | Dev and staging workloads |
| prod | `210123964977` | Production workloads |
| sandbox | `868784437733` | Experimental / throwaway projects |

The `gcp-internal-cloud-setup` folder (`225030657532`) is intentionally unmanaged.

## Org policies enforced

All set at org root using `google_org_policy_policy` (OrgPolicy v2) and inherited everywhere:

| Resource name | Constraint | Effect |
|---|---|---|
| `skip_default_network` | `compute.skipDefaultNetworkCreation` | No auto-VPC on new projects |
| `require_os_login` | `compute.requireOsLogin` | SSH tied to IAM, not project keys |
| `vm_no_external_ip` | `compute.vmExternalIpAccess` | Deny all external IPs on VMs |
| `sql_no_public_ip` | `sql.restrictPublicIp` | No public IPs on Cloud SQL |
| `no_sa_key_creation` | `iam.disableServiceAccountKeyCreation` | Use WIF instead of key files |
| `gcs_uniform_access` | `storage.uniformBucketLevelAccess` | IAM only, no per-object ACLs |
| `gcs_public_access_prevention` | `storage.publicAccessPrevention` | No public GCS objects |
| `resource_locations` | `gcp.resourceLocations` | US regions only (`in:us-locations`) |
| `allowed_policy_member_domains` | `iam.allowedPolicyMemberDomains` | Only Cloud Identity tenant members in IAM |

## Audit logging

`audit.tf` configures `google_organization_iam_audit_config` on `allServices`:
- `ADMIN_READ` — who is reading IAM policies and configs
- `DATA_READ` — who is reading data (GCS objects, BigQuery rows, etc.)
- `DATA_WRITE` — who is writing data

Admin Activity logs are always on by default and are not configured here.

## Billing budgets

| Budget | Amount | Scope |
|---|---|---|
| `org_total` | $50/mo | All billing account spend |
| `prod` | $30/mo | `prod` folder |
| `nonprod` | $20/mo | `nonprod` + `sandbox` folders |

Alerts fire at 50%, 80%, and 100% of each cap. GCP emails billing admins automatically.

## IAM

`org-iam.tf` grants five roles to `org_admin_members` using additive
`google_organization_iam_member` (not authoritative binding, won't clobber other grants):

- `roles/resourcemanager.organizationAdmin`
- `roles/resourcemanager.folderCreator`
- `roles/resourcemanager.projectCreator`
- `roles/orgpolicy.policyAdmin`
- `roles/billing.admin`

The `tf-org` CI service account's org-level roles are managed in `bootstrap/wif.tf`
to avoid two Terraform states owning the same IAM binding.

## Deploying locally

CI handles all applies. Local runs are for development only:

```bash
cp terraform.tfvars.example terraform.tfvars
# Fill in billing_account_id, org_admin_members, cloud_identity_customer_id
gcloud auth application-default login
terraform init
terraform plan -var-file=terraform.tfvars
```

`ci.auto.tfvars` is committed and auto-loaded with non-sensitive values.
Sensitive values (`billing_account_id`, `org_admin_members`, `cloud_identity_customer_id`)
are injected at runtime from GitHub Actions variables (`BILLING_ACCOUNT_ID`,
`ORG_ADMIN_EMAIL`, `CLOUD_IDENTITY_CUSTOMER_ID`) — never committed to git.

## Adding a new org policy

1. Add a `google_org_policy_policy` block to `org-policies.tf`
2. If the constraint already exists in GCP, import it first:
   ```bash
   terraform import google_org_policy_policy.<name> \
     organizations/<ORG_ID>/policies/<constraint>
   ```
3. Open a PR — plan will show the change, apply runs on merge

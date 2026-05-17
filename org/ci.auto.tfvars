# CI-facing variable values. Committed intentionally — contains no secrets.
# Terraform auto-loads *.auto.tfvars files, so this applies in both local
# and CI runs without any -var-file flag.
#
# Local development: create terraform.tfvars (gitignored) to override
# any of these values if needed.

organization_id      = "459863125464"
organization_domain  = "hamilton-hoover.com"
billing_account_id   = "BILLING_ACCOUNT_REDACTED"
bootstrap_project_id = "massive-runway-432502-n1"

# Human admins only. The tf-org CI service account's org-level roles are
# managed in bootstrap/wif.tf — keeping ownership in one place avoids two
# Terraform states fighting over the same IAM bindings.
org_admin_members = [
  "user:PERSONAL_EMAIL_REDACTED",
]

allowed_regions       = ["in:us-locations"]
org_budget_amount     = 50
prod_budget_amount    = 30
nonprod_budget_amount = 20

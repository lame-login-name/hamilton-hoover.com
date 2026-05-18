# CI-facing variable values. Committed intentionally — contains no secrets or PII.
# Terraform auto-loads *.auto.tfvars files, so this applies in both local
# and CI runs without any -var-file flag.
#
# Sensitive values (billing_account_id, org_admin_members, cloud_identity_customer_id)
# are injected at runtime from GitHub Actions variables — see terraform-org.yml.
#
# Local development: create terraform.tfvars (gitignored) to supply those values.

organization_id      = "459863125464"
organization_domain  = "hamilton-hoover.com"
bootstrap_project_id = "massive-runway-432502-n1"

allowed_regions       = ["in:us-locations"]
org_budget_amount     = 50
prod_budget_amount    = 30
nonprod_budget_amount = 20

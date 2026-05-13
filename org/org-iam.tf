# Organization-level IAM.
#
# Uses google_organization_iam_member (additive) rather than
# google_organization_iam_binding (authoritative) at the org root.
# Authoritative bindings at this level would wipe any Google-managed
# service account roles that exist outside of Terraform state.
#
# Phase 2 will add a dedicated Terraform service account per repo and
# grant it the narrowest roles it needs. The human admin bindings here
# are intentionally broad — this is the break-glass identity.

locals {
  org_admins = toset(var.org_admin_members)
}

# Full org admin — needed to manage folders, policies, and IAM itself.
resource "google_organization_iam_member" "org_admin" {
  for_each = local.org_admins
  org_id   = var.organization_id
  role     = "roles/resourcemanager.organizationAdmin"
  member   = each.value
}

# Folder creator — required for this config to create the folder hierarchy.
resource "google_organization_iam_member" "folder_creator" {
  for_each = local.org_admins
  org_id   = var.organization_id
  role     = "roles/resourcemanager.folderCreator"
  member   = each.value
}

# Project creator — needed when provisioning projects in later phases.
resource "google_organization_iam_member" "project_creator" {
  for_each = local.org_admins
  org_id   = var.organization_id
  role     = "roles/resourcemanager.projectCreator"
  member   = each.value
}

# Org policy admin — required to set and update org policies.
resource "google_organization_iam_member" "org_policy_admin" {
  for_each = local.org_admins
  org_id   = var.organization_id
  role     = "roles/orgpolicy.policyAdmin"
  member   = each.value
}

# Billing admin at the org level — allows attaching billing accounts to projects.
resource "google_organization_iam_member" "billing_admin" {
  for_each = local.org_admins
  org_id   = var.organization_id
  role     = "roles/billing.admin"
  member   = each.value
}

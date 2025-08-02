# Organization-level IAM bindings
# This file manages IAM roles and permissions at the organization level

# Organization administrators
resource "google_organization_iam_binding" "org_admins" {
  org_id = var.organization_id
  role   = "roles/resourcemanager.organizationAdmin"

  members = var.org_admin_members
}

# Billing administrators
resource "google_organization_iam_binding" "billing_admins" {
  org_id = var.organization_id
  role   = "roles/billing.admin"

  members = var.billing_admin_members
}

# Security administrators
resource "google_organization_iam_binding" "security_admins" {
  org_id = var.organization_id
  role   = "roles/iam.securityAdmin"

  members = var.security_admin_members
}

# Network administrators
resource "google_organization_iam_binding" "network_admins" {
  org_id = var.organization_id
  role   = "roles/compute.networkAdmin"

  members = var.network_admin_members
}

# Folder creators (for department leads)
resource "google_organization_iam_binding" "folder_creators" {
  org_id = var.organization_id
  role   = "roles/resourcemanager.folderCreator"

  members = var.folder_creator_members
}

# Project creators (for team leads)
resource "google_organization_iam_binding" "project_creators" {
  org_id = var.organization_id
  role   = "roles/resourcemanager.projectCreator"

  members = var.project_creator_members
}

# Organization viewers (for auditing)
resource "google_organization_iam_binding" "org_viewers" {
  org_id = var.organization_id
  role   = "roles/browser"

  members = var.org_viewer_members
}

# Cloud Asset Inventory viewers (for compliance)
resource "google_organization_iam_binding" "asset_viewers" {
  org_id = var.organization_id
  role   = "roles/cloudasset.viewer"

  members = var.asset_viewer_members
}

# Custom role for limited project management
resource "google_organization_iam_custom_role" "limited_project_manager" {
  role_id     = "limitedProjectManager"
  org_id      = var.organization_id
  title       = "Limited Project Manager"
  description = "Can manage projects with restrictions"

  permissions = [
    "resourcemanager.projects.get",
    "resourcemanager.projects.list",
    "resourcemanager.projects.update",
    "compute.instances.list",
    "compute.instances.get",
    "storage.buckets.list",
    "storage.buckets.get",
  ]
}

# Bind the custom role
resource "google_organization_iam_binding" "limited_project_managers" {
  org_id = var.organization_id
  role   = google_organization_iam_custom_role.limited_project_manager.name

  members = var.limited_project_manager_members
}
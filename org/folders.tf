# Folder structure for organizing projects within the GCP Organization
# This file creates a hierarchical folder structure for better resource organization

# Production environment folder
resource "google_folder" "production" {
  display_name = "Production"
  parent       = "organizations/${var.organization_id}"
}

# Staging environment folder
resource "google_folder" "staging" {
  display_name = "Staging"
  parent       = "organizations/${var.organization_id}"
}

# Development environment folder
resource "google_folder" "development" {
  display_name = "Development"
  parent       = "organizations/${var.organization_id}"
}

# Shared services folder
resource "google_folder" "shared_services" {
  display_name = "Shared Services"
  parent       = "organizations/${var.organization_id}"
}

# Security folder for security-related projects
resource "google_folder" "security" {
  display_name = "Security"
  parent       = "organizations/${var.organization_id}"
}

# Sandbox folder for experimentation
resource "google_folder" "sandbox" {
  display_name = "Sandbox"
  parent       = "organizations/${var.organization_id}"
}

# Department-specific folders
resource "google_folder" "engineering" {
  display_name = "Engineering"
  parent       = google_folder.production.name
}

resource "google_folder" "data" {
  display_name = "Data & Analytics"
  parent       = google_folder.production.name
}

resource "google_folder" "marketing" {
  display_name = "Marketing"
  parent       = google_folder.production.name
}

# IAM bindings for folders
resource "google_folder_iam_binding" "production_admins" {
  folder = google_folder.production.name
  role   = "roles/resourcemanager.folderAdmin"

  members = var.production_admin_members
}

resource "google_folder_iam_binding" "staging_admins" {
  folder = google_folder.staging.name
  role   = "roles/resourcemanager.folderAdmin"

  members = var.staging_admin_members
}

resource "google_folder_iam_binding" "development_admins" {
  folder = google_folder.development.name
  role   = "roles/resourcemanager.folderAdmin"

  members = var.development_admin_members
}

resource "google_folder_iam_binding" "shared_services_admins" {
  folder = google_folder.shared_services.name
  role   = "roles/resourcemanager.folderAdmin"

  members = var.shared_services_admin_members
}

# Security folder with stricter access
resource "google_folder_iam_binding" "security_admins" {
  folder = google_folder.security.name
  role   = "roles/resourcemanager.folderAdmin"

  members = var.security_folder_admin_members
}

# Sandbox with more permissive access for experimentation
resource "google_folder_iam_binding" "sandbox_users" {
  folder = google_folder.sandbox.name
  role   = "roles/resourcemanager.projectCreator"

  members = var.sandbox_user_members
}

# Outputs for use in other configurations
output "folder_ids" {
  description = "Map of folder names to their IDs"
  value = {
    production      = google_folder.production.folder_id
    staging         = google_folder.staging.folder_id
    development     = google_folder.development.folder_id
    shared_services = google_folder.shared_services.folder_id
    security        = google_folder.security.folder_id
    sandbox         = google_folder.sandbox.folder_id
    engineering     = google_folder.engineering.folder_id
    data            = google_folder.data.folder_id
    marketing       = google_folder.marketing.folder_id
  }
}

output "folder_names" {
  description = "Map of folder names to their resource names"
  value = {
    production      = google_folder.production.name
    staging         = google_folder.staging.name
    development     = google_folder.development.name
    shared_services = google_folder.shared_services.name
    security        = google_folder.security.name
    sandbox         = google_folder.sandbox.name
    engineering     = google_folder.engineering.name
    data            = google_folder.data.name
    marketing       = google_folder.marketing.name
  }
}
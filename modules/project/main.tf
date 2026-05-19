# Project factory module — the platform contract.
# Every GCP project in this org is created through this module.
# No projects are created directly or manually.

resource "google_project" "this" {
  name            = var.project_name
  project_id      = var.project_id
  folder_id       = var.folder_id
  billing_account = var.billing_account_id

  # Org policy also enforces this — explicit here for defence in depth
  # and so plans show intent clearly.
  auto_create_network = false

  labels = merge(
    {
      env         = var.environment
      owner       = "platform"
      purpose     = var.purpose
      cost_center = "personal"
      managed-by  = "terraform"
    },
    var.labels
  )
}

# Baseline APIs enabled in every project.
# Additional APIs are passed in via var.activate_apis.
resource "google_project_service" "apis" {
  for_each = toset(concat(local.baseline_apis, var.activate_apis))

  project = google_project.this.project_id
  service = each.value

  # Leaving APIs enabled if the resource is destroyed prevents accidental
  # disruption to dependent services during refactors.
  disable_on_destroy         = false
  disable_dependent_services = false
}

locals {
  baseline_apis = [
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  ]
}

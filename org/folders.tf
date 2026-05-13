# Folder hierarchy — matches instructions.md Phase 1 design.
# Five top-level folders, all direct children of the org root.
# Department sub-folders are not created here; add them under the relevant
# environment folder when a real use case requires them.
#
# NOTE: the existing gcp-internal-cloud-setup folder (225030657532) was
# created by Google during org onboarding and is intentionally NOT managed
# here. Leave it alone unless you decide to import or delete it.

resource "google_folder" "platform" {
  display_name = "platform"
  parent       = "organizations/${var.organization_id}"
}

resource "google_folder" "shared_services" {
  display_name = "shared-services"
  parent       = "organizations/${var.organization_id}"
}

resource "google_folder" "nonprod" {
  display_name = "nonprod"
  parent       = "organizations/${var.organization_id}"
}

resource "google_folder" "prod" {
  display_name = "prod"
  parent       = "organizations/${var.organization_id}"
}

resource "google_folder" "sandbox" {
  display_name = "sandbox"
  parent       = "organizations/${var.organization_id}"
}

output "folder_ids" {
  description = "Numeric folder IDs for use in downstream configs (projects, budgets, etc.)"
  value = {
    platform        = google_folder.platform.folder_id
    shared_services = google_folder.shared_services.folder_id
    nonprod         = google_folder.nonprod.folder_id
    prod            = google_folder.prod.folder_id
    sandbox         = google_folder.sandbox.folder_id
  }
}

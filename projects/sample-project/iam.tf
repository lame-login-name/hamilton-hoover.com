# IAM configuration for the sample project
# This file manages Identity and Access Management for the project

# Project-level IAM bindings
resource "google_project_iam_binding" "project_admins" {
  count   = length(var.project_admin_members) > 0 ? 1 : 0
  project = google_project.main.project_id
  role    = "roles/editor"

  members = var.project_admin_members
}

resource "google_project_iam_binding" "project_viewers" {
  count   = length(var.project_viewer_members) > 0 ? 1 : 0
  project = google_project.main.project_id
  role    = "roles/viewer"

  members = var.project_viewer_members
}

resource "google_project_iam_binding" "project_developers" {
  count   = length(var.project_developer_members) > 0 ? 1 : 0
  project = google_project.main.project_id
  role    = "roles/editor"

  members = var.project_developer_members

  condition {
    title       = "Development Environment Only"
    description = "Restricts access to development resources"
    expression  = "resource.name.startsWith('projects/${google_project.main.project_id}/zones/us-central1-a/instances/dev-') || resource.name.startsWith('projects/${google_project.main.project_id}/regions/us-central1/subnetworks/dev-')"
  }
}

# Service account IAM
resource "google_service_account_iam_binding" "workload_identity" {
  count              = var.enable_gke ? 1 : 0
  service_account_id = google_service_account.workload_identity[0].name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${google_project.main.project_id}.svc.id.goog[${var.kubernetes_namespace}/${var.kubernetes_service_account}]"
  ]
}

# Storage bucket IAM
resource "google_storage_bucket_iam_binding" "artifacts_admins" {
  bucket = google_storage_bucket.artifacts.name
  role   = "roles/storage.admin"

  members = var.artifacts_admin_members
}

resource "google_storage_bucket_iam_binding" "artifacts_viewers" {
  bucket = google_storage_bucket.artifacts.name
  role   = "roles/storage.objectViewer"

  members = concat(
    var.artifacts_viewer_members,
    ["serviceAccount:${google_service_account.default.email}"]
  )
}

resource "google_storage_bucket_iam_binding" "data_admins" {
  count  = var.create_data_bucket ? 1 : 0
  bucket = google_storage_bucket.data[0].name
  role   = "roles/storage.admin"

  members = var.data_admin_members
}

resource "google_storage_bucket_iam_binding" "data_viewers" {
  count  = var.create_data_bucket ? 1 : 0
  bucket = google_storage_bucket.data[0].name
  role   = "roles/storage.objectViewer"

  members = var.data_viewer_members
}

# Database IAM
resource "google_project_iam_binding" "sql_admins" {
  count   = var.create_database && length(var.database_admin_members) > 0 ? 1 : 0
  project = google_project.main.project_id
  role    = "roles/cloudsql.admin"

  members = var.database_admin_members
}

resource "google_project_iam_binding" "sql_clients" {
  count   = var.create_database && length(var.database_client_members) > 0 ? 1 : 0
  project = google_project.main.project_id
  role    = "roles/cloudsql.client"

  members = concat(
    var.database_client_members,
    ["serviceAccount:${google_service_account.default.email}"]
  )
}

# Secret Manager IAM
resource "google_secret_manager_secret_iam_binding" "db_password_accessor" {
  count     = var.create_database ? 1 : 0
  project   = google_project.main.project_id
  secret_id = google_secret_manager_secret.db_password[0].secret_id
  role      = "roles/secretmanager.secretAccessor"

  members = concat(
    var.secret_admin_members,
    ["serviceAccount:${google_service_account.default.email}"]
  )
}

# KMS IAM
resource "google_kms_crypto_key_iam_binding" "encrypter_decrypter" {
  count         = var.create_kms_keyring ? 1 : 0
  crypto_key_id = google_kms_crypto_key.main[0].id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = concat(
    var.kms_admin_members,
    ["serviceAccount:${google_service_account.default.email}"]
  )
}

# Cloud Build service account permissions
resource "google_project_iam_binding" "cloud_build_sa" {
  count   = var.enable_cloud_build ? 1 : 0
  project = google_project.main.project_id
  role    = "roles/cloudbuild.builds.editor"

  members = [
    "serviceAccount:${google_project.main.number}@cloudbuild.gserviceaccount.com"
  ]

  depends_on = [google_project_service.apis]
}

resource "google_project_iam_binding" "cloud_build_storage" {
  count   = var.enable_cloud_build ? 1 : 0
  project = google_project.main.project_id
  role    = "roles/storage.admin"

  members = [
    "serviceAccount:${google_project.main.number}@cloudbuild.gserviceaccount.com"
  ]

  depends_on = [google_project_service.apis]
}

# Monitoring service account permissions
resource "google_project_iam_binding" "monitoring_metric_writer" {
  project = google_project.main.project_id
  role    = "roles/monitoring.metricWriter"

  members = [
    "serviceAccount:${google_service_account.default.email}"
  ]
}

resource "google_project_iam_binding" "logging_log_writer" {
  project = google_project.main.project_id
  role    = "roles/logging.logWriter"

  members = [
    "serviceAccount:${google_service_account.default.email}"
  ]
}

# Custom IAM role for limited project access
resource "google_project_iam_custom_role" "limited_developer" {
  project     = google_project.main.project_id
  role_id     = "limitedDeveloper"
  title       = "Limited Developer"
  description = "Developer role with restricted permissions"

  permissions = [
    "compute.instances.get",
    "compute.instances.list",
    "compute.instances.start",
    "compute.instances.stop",
    "storage.objects.get",
    "storage.objects.list",
    "storage.objects.create",
    "storage.objects.update",
    "logging.logEntries.list",
    "monitoring.timeSeries.list",
  ]
}

resource "google_project_iam_binding" "limited_developers" {
  count   = length(var.limited_developer_members) > 0 ? 1 : 0
  project = google_project.main.project_id
  role    = google_project_iam_custom_role.limited_developer.name

  members = var.limited_developer_members
}

# Security Command Center notification service account
resource "google_service_account" "security_notifications" {
  count = var.enable_security_notifications ? 1 : 0
  
  project      = google_project.main.project_id
  account_id   = "${var.project_id_prefix}-security-sa"
  display_name = "Security notifications service account"
  description  = "Service account for Security Command Center notifications"

  depends_on = [google_project_service.apis]
}

resource "google_project_iam_binding" "security_center_admin" {
  count   = var.enable_security_notifications ? 1 : 0
  project = google_project.main.project_id
  role    = "roles/securitycenter.adminViewer"

  members = [
    "serviceAccount:${google_service_account.security_notifications[0].email}"
  ]
}

# Audit log configuration
resource "google_project_iam_audit_config" "main" {
  project = google_project.main.project_id
  service = "allServices"

  audit_log_config {
    log_type = "ADMIN_READ"
  }

  audit_log_config {
    log_type = "DATA_READ"
  }

  audit_log_config {
    log_type = "DATA_WRITE"
  }
}

# Outputs
output "default_service_account_id" {
  description = "ID of the default service account"
  value       = google_service_account.default.id
}

output "workload_identity_service_account_id" {
  description = "ID of the Workload Identity service account"
  value       = var.enable_gke ? google_service_account.workload_identity[0].id : null
}

output "security_notifications_service_account_email" {
  description = "Email of the security notifications service account"
  value       = var.enable_security_notifications ? google_service_account.security_notifications[0].email : null
}

output "custom_role_id" {
  description = "ID of the custom limited developer role"
  value       = google_project_iam_custom_role.limited_developer.name
}
# Sample GCP Project Configuration
# This file defines the main project resources and configuration

# Random suffix for unique project ID
resource "random_id" "project_suffix" {
  byte_length = 4
}

# Create the GCP project
resource "google_project" "main" {
  name            = var.project_name
  project_id      = "${var.project_id_prefix}-${random_id.project_suffix.hex}"
  org_id          = var.organization_id
  folder_id       = var.folder_id
  billing_account = var.billing_account_id

  labels = merge(var.common_labels, {
    environment = var.environment
    team        = var.team_name
    project     = var.project_name
  })

  auto_create_network = false
}

# Enable required APIs
resource "google_project_service" "apis" {
  for_each = toset(var.required_apis)
  
  project = google_project.main.project_id
  service = each.value

  disable_dependent_services = false
  disable_on_destroy        = false
}

# Create default service account
resource "google_service_account" "default" {
  project      = google_project.main.project_id
  account_id   = "${var.project_id_prefix}-sa"
  display_name = "Default service account for ${var.project_name}"
  description  = "Service account for general project operations"

  depends_on = [google_project_service.apis]
}

# Grant necessary permissions to default service account
resource "google_project_iam_member" "default_sa_permissions" {
  for_each = toset(var.default_sa_roles)
  
  project = google_project.main.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.default.email}"

  depends_on = [google_service_account.default]
}

# Workload Identity service account for GKE
resource "google_service_account" "workload_identity" {
  count = var.enable_gke ? 1 : 0
  
  project      = google_project.main.project_id
  account_id   = "${var.project_id_prefix}-wi-sa"
  display_name = "Workload Identity service account"
  description  = "Service account for Kubernetes workloads using Workload Identity"

  depends_on = [google_project_service.apis]
}

# Cloud Storage bucket for project artifacts
resource "google_storage_bucket" "artifacts" {
  project  = google_project.main.project_id
  name     = "${google_project.main.project_id}-artifacts"
  location = var.default_region

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = var.artifact_retention_days
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      age                   = 30
      with_state           = "ARCHIVED"
    }
    action {
      type = "Delete"
    }
  }

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  labels = merge(var.common_labels, {
    purpose = "artifacts"
  })

  depends_on = [google_project_service.apis]
}

# Cloud Storage bucket for application data
resource "google_storage_bucket" "data" {
  count = var.create_data_bucket ? 1 : 0
  
  project  = google_project.main.project_id
  name     = "${google_project.main.project_id}-data"
  location = var.default_region

  versioning {
    enabled = true
  }

  encryption {
    default_kms_key_name = var.kms_key_name
  }

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  labels = merge(var.common_labels, {
    purpose = "data"
  })

  depends_on = [google_project_service.apis]
}

# Cloud SQL instance (optional)
resource "google_sql_database_instance" "main" {
  count = var.create_database ? 1 : 0
  
  project         = google_project.main.project_id
  name            = "${var.project_id_prefix}-db"
  database_version = var.database_version
  region          = var.default_region

  settings {
    tier                        = var.database_tier
    availability_type          = var.database_availability_type
    disk_size                  = var.database_disk_size
    disk_type                  = "PD_SSD"
    disk_autoresize           = true
    disk_autoresize_limit     = var.database_max_disk_size

    backup_configuration {
      enabled                        = true
      start_time                    = "03:00"
      location                      = var.default_region
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
      backup_retention_settings {
        retained_backups = 30
        retention_unit   = "COUNT"
      }
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = var.vpc_network_id
      require_ssl     = true
    }

    database_flags {
      name  = "cloudsql.iam_authentication"
      value = "on"
    }

    user_labels = merge(var.common_labels, {
      purpose = "database"
    })
  }

  deletion_protection = var.database_deletion_protection

  depends_on = [google_project_service.apis]
}

# Secret Manager secret for database credentials
resource "google_secret_manager_secret" "db_password" {
  count = var.create_database ? 1 : 0
  
  project   = google_project.main.project_id
  secret_id = "db-password"

  labels = merge(var.common_labels, {
    purpose = "database"
  })

  replication {
    automatic = true
  }

  depends_on = [google_project_service.apis]
}

# Generate database password
resource "random_password" "db_password" {
  count   = var.create_database ? 1 : 0
  length  = 16
  special = true
}

# Store database password in Secret Manager
resource "google_secret_manager_secret_version" "db_password" {
  count = var.create_database ? 1 : 0
  
  secret      = google_secret_manager_secret.db_password[0].id
  secret_data = random_password.db_password[0].result
}

# Cloud KMS key ring
resource "google_kms_key_ring" "main" {
  count = var.create_kms_keyring ? 1 : 0
  
  project  = google_project.main.project_id
  name     = "${var.project_id_prefix}-keyring"
  location = var.kms_location

  depends_on = [google_project_service.apis]
}

# Cloud KMS encryption key
resource "google_kms_crypto_key" "main" {
  count = var.create_kms_keyring ? 1 : 0
  
  name     = "${var.project_id_prefix}-key"
  key_ring = google_kms_key_ring.main[0].id
  purpose  = "ENCRYPT_DECRYPT"

  version_template {
    algorithm = "GOOGLE_SYMMETRIC_ENCRYPTION"
  }

  rotation_period = var.kms_rotation_period

  labels = merge(var.common_labels, {
    purpose = "encryption"
  })
}

# Outputs
output "project_id" {
  description = "The project ID"
  value       = google_project.main.project_id
}

output "project_number" {
  description = "The project number"
  value       = google_project.main.number
}

output "default_service_account_email" {
  description = "Email of the default service account"
  value       = google_service_account.default.email
}

output "workload_identity_service_account_email" {
  description = "Email of the Workload Identity service account"
  value       = var.enable_gke ? google_service_account.workload_identity[0].email : null
}

output "artifacts_bucket_name" {
  description = "Name of the artifacts storage bucket"
  value       = google_storage_bucket.artifacts.name
}

output "data_bucket_name" {
  description = "Name of the data storage bucket"
  value       = var.create_data_bucket ? google_storage_bucket.data[0].name : null
}

output "database_instance_name" {
  description = "Name of the Cloud SQL instance"
  value       = var.create_database ? google_sql_database_instance.main[0].name : null
}

output "database_connection_name" {
  description = "Connection name of the Cloud SQL instance"
  value       = var.create_database ? google_sql_database_instance.main[0].connection_name : null
}

output "kms_key_id" {
  description = "ID of the KMS encryption key"
  value       = var.create_kms_keyring ? google_kms_crypto_key.main[0].id : null
}
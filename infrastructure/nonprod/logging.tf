# Centralized logging project for nonprod.
# Receives org-level audit logs via a log sink. BigQuery is the destination —
# partitioned tables with short-cycle expiry (default: 7 days) keep storage costs near zero.
#
# Scope: this sink captures ALL org audit logs (including prod) during the
# nonprod build phase. A dedicated prod sink is added in infrastructure/prod/
# once this pattern is proven.

module "logging_project" {
  source = "../../modules/project"

  project_id         = "hh-logging-nonprod"
  project_name       = "HH Logging Nonprod"
  folder_id          = var.shared_services_folder_id
  billing_account_id = var.billing_account_id
  environment        = "nonprod"
  purpose            = "audit-logging"

  activate_apis = [
    "bigquery.googleapis.com",
    "bigquerystorage.googleapis.com",
  ]
}

# Audit log dataset — US multi-region keeps costs low and avoids egress.
# Tables are auto-created by the sink with GCP's audit log schema.
resource "google_bigquery_dataset" "audit_logs" {
  project    = module.logging_project.project_id
  dataset_id = "audit_logs"
  location   = "US"

  friendly_name = "Audit Logs — Nonprod"
  description   = "Org-level audit logs from Cloud Logging. Partitioned tables, configurable short-cycle retention (default: 7 days)."

  # Partition expiry — each day's partition is dropped after this window.
  # Belt-and-suspenders: table expiry catches any non-partitioned tables the sink creates.
  default_partition_expiration_ms = var.audit_log_retention_days * 24 * 60 * 60 * 1000
  default_table_expiration_ms     = var.audit_log_retention_days * 24 * 60 * 60 * 1000

  # Safety guard: a tf destroy should not silently drop audit history
  delete_contents_on_destroy = false

  # Wait for the full module (including bigquery.googleapis.com API enablement)
  # before creating the dataset. Without this, Terraform parallelises dataset
  # creation with API activation and races to a 400 "BigQuery not enabled".
  depends_on = [module.logging_project]

  labels = {
    env        = "nonprod"
    purpose    = "audit-logging"
    managed-by = "terraform"
  }
}

# Org-level sink — include_children = true exports from every project and folder.
resource "google_logging_organization_sink" "audit" {
  name             = "org-audit-to-bq-nonprod"
  org_id           = var.organization_id
  include_children = true

  destination = "bigquery.googleapis.com/projects/${module.logging_project.project_id}/datasets/${google_bigquery_dataset.audit_logs.dataset_id}"

  # Inclusion filter — Admin Activity and Policy Denied only.
  #
  # Admin Activity: IAM grants/revokes, resource creates/updates/deletes,
  #   org/billing config changes. Always-on in every GCP project, free to
  #   generate, and very low volume — only fires when Terraform runs or
  #   someone acts in the console.
  #
  # Policy Denied: org policy rejections. Low volume, high signal.
  #
  # Data Access intentionally excluded:
  #   - Must be explicitly enabled per-service in the org audit config;
  #     it is NOT enabled here, so this log_id produces zero rows today.
  #   - When enabled for any service the volume can be enormous — every
  #     API read/list/get call generates an entry (e.g. BQ enables it for
  #     itself by default, GCS reads, monitoring polls, etc.).
  #   - Including it with a denylist of noisy methods is fragile: one new
  #     chatty service blows through any storage budget. Excluding entirely
  #     is the only safe default for a personal org.
  #
  # Anything else (VPC flow logs, LB access logs, Cloud Run request logs,
  # system events) is excluded by omission — it never matches this filter.
  filter = <<-EOT
    log_id("cloudaudit.googleapis.com/activity")
    OR log_id("cloudaudit.googleapis.com/policy_denied")
  EOT

  bigquery_options {
    # Partitioned tables reduce query cost and enable partition-level expiry
    use_partitioned_tables = true
  }
}

# The sink's auto-provisioned service account needs write access to the dataset.
# writer_identity is only known after the sink is created.
resource "google_bigquery_dataset_iam_member" "audit_sink_writer" {
  project    = module.logging_project.project_id
  dataset_id = google_bigquery_dataset.audit_logs.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_organization_sink.audit.writer_identity
}

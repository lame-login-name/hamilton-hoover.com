# Data Access audit logging for the organization.
# Enables ADMIN_READ, DATA_READ, and DATA_WRITE audit logs on all GCP services.
# Logs are written to Cloud Audit Logs and visible in Cloud Logging.
#
# Note: Admin Activity logs are always on and cannot be disabled.
# These rules layer on top, capturing data-plane access patterns org-wide.
resource "google_organization_iam_audit_config" "org" {
  org_id  = var.organization_id
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

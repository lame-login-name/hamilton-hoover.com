# Billing account management and configurations
# This file manages billing accounts and budget alerts

# Primary billing account data source
data "google_billing_account" "primary" {
  billing_account = var.billing_account_id
  open            = true
}

# Budget for the entire organization
resource "google_billing_budget" "organization_budget" {
  billing_account = data.google_billing_account.primary.id
  display_name    = "Organization Total Budget"

  budget_filter {
    projects = ["projects/${var.organization_id}"]
  }

  amount {
    specified_amount {
      currency_code = var.budget_currency
      units         = var.organization_budget_amount
    }
  }

  threshold_rules {
    threshold_percent = 0.5
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 0.75
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 0.9
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "CURRENT_SPEND"
  }

  all_updates_rule {
    monitoring_notification_channels = var.budget_notification_channels
    disable_default_iam_recipients    = false
  }
}

# Production environment budget
resource "google_billing_budget" "production_budget" {
  billing_account = data.google_billing_account.primary.id
  display_name    = "Production Environment Budget"

  budget_filter {
    projects = var.production_project_ids
  }

  amount {
    specified_amount {
      currency_code = var.budget_currency
      units         = var.production_budget_amount
    }
  }

  threshold_rules {
    threshold_percent = 0.8
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 0.95
    spend_basis       = "CURRENT_SPEND"
  }

  all_updates_rule {
    monitoring_notification_channels = var.budget_notification_channels
    disable_default_iam_recipients    = false
  }
}

# Development/Sandbox budget
resource "google_billing_budget" "development_budget" {
  billing_account = data.google_billing_account.primary.id
  display_name    = "Development & Sandbox Budget"

  budget_filter {
    projects = var.development_project_ids
  }

  amount {
    specified_amount {
      currency_code = var.budget_currency
      units         = var.development_budget_amount
    }
  }

  threshold_rules {
    threshold_percent = 0.7
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 0.9
    spend_basis       = "CURRENT_SPEND"
  }

  all_updates_rule {
    monitoring_notification_channels = var.budget_notification_channels
    disable_default_iam_recipients    = false
  }
}

# Billing IAM
resource "google_billing_account_iam_binding" "billing_users" {
  billing_account_id = data.google_billing_account.primary.id
  role               = "roles/billing.user"

  members = var.billing_user_members
}

resource "google_billing_account_iam_binding" "billing_viewers" {
  billing_account_id = data.google_billing_account.primary.id
  role               = "roles/billing.viewer"

  members = var.billing_viewer_members
}

# Export billing data to BigQuery
resource "google_bigquery_dataset" "billing_export" {
  dataset_id  = "billing_export"
  project     = var.billing_export_project_id
  description = "Dataset for billing export data"
  location    = var.billing_export_location

  access {
    role          = "OWNER"
    user_by_email = var.billing_export_owner_email
  }

  access {
    role   = "READER"
    domain = var.organization_domain
  }
}

# Outputs
output "billing_account_id" {
  description = "The billing account ID"
  value       = data.google_billing_account.primary.id
}

output "billing_dataset_id" {
  description = "The BigQuery dataset ID for billing exports"
  value       = google_bigquery_dataset.billing_export.dataset_id
}
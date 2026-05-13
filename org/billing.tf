# Billing budgets.
#
# Three budgets:
#   1. org-total   — all spend on this billing account (catch-all)
#   2. prod        — scoped to the prod folder
#   3. nonprod     — scoped to the nonprod + sandbox folders combined
#
# Alert emails are sent to billing account admins automatically by GCP
# without any notification channel config. Monitoring channels or Pub/Sub
# topics can be wired in Phase 4 when a monitoring project exists.
#
# Budget amounts are intentionally small for a personal platform.
# Adjust via var.org_budget_amount / var.prod_budget_amount /
# var.nonprod_budget_amount in terraform.tfvars.

data "google_billing_account" "primary" {
  billing_account = var.billing_account_id
  open            = true
}

# --- Org-level catch-all budget ---

resource "google_billing_budget" "org_total" {
  billing_account = var.billing_account_id
  display_name    = "hh-org-total"

  budget_filter {
    credit_types_treatment = "INCLUDE_ALL_CREDITS"
    # No resource_ancestors filter = all spend on this billing account.
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = tostring(var.org_budget_amount)
    }
  }

  threshold_rules {
    threshold_percent = 0.5
    spend_basis       = "CURRENT_SPEND"
  }
  threshold_rules {
    threshold_percent = 0.8
    spend_basis       = "CURRENT_SPEND"
  }
  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "CURRENT_SPEND"
  }
}

# --- Production folder budget ---

resource "google_billing_budget" "prod" {
  billing_account = var.billing_account_id
  display_name    = "hh-prod-folder"

  budget_filter {
    credit_types_treatment = "INCLUDE_ALL_CREDITS"
    resource_ancestors     = ["folders/${google_folder.prod.folder_id}"]
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = tostring(var.prod_budget_amount)
    }
  }

  threshold_rules {
    threshold_percent = 0.8
    spend_basis       = "CURRENT_SPEND"
  }
  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "CURRENT_SPEND"
  }
}

# --- Nonprod + sandbox budget ---

resource "google_billing_budget" "nonprod" {
  billing_account = var.billing_account_id
  display_name    = "hh-nonprod-sandbox"

  budget_filter {
    credit_types_treatment = "INCLUDE_ALL_CREDITS"
    resource_ancestors = [
      "folders/${google_folder.nonprod.folder_id}",
      "folders/${google_folder.sandbox.folder_id}",
    ]
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = tostring(var.nonprod_budget_amount)
    }
  }

  threshold_rules {
    threshold_percent = 0.8
    spend_basis       = "CURRENT_SPEND"
  }
  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "CURRENT_SPEND"
  }
}

output "billing_account_id" {
  description = "Billing account ID (for reference in downstream configs)"
  value       = data.google_billing_account.primary.id
}

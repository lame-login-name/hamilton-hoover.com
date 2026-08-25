# Every variable here rejects the literal "TODO" placeholder that
# terraform.tfvars.example ships with.
#
# This is not cosmetic. bootstrap/ is the one layer applied by hand, so no CI
# plan guards it. An unfilled terraform.tfvars produces a plan that silently
# *replaces* the WIF pool and both Terraform service accounts rather than
# erroring — applying it would destroy the identities all CI depends on and
# require a full re-bootstrap plus new GitHub Actions variables. Failing at
# plan time turns that into a one-line error message instead.

variable "bootstrap_project_id" {
  description = "Project ID of the bootstrap project where WIF and service accounts live."
  type        = string
  validation {
    condition     = var.bootstrap_project_id != "TODO"
    error_message = "bootstrap_project_id is still the TODO placeholder. Fill in terraform.tfvars before planning — see the comment at the top of variables.tf."
  }
}

variable "organization_id" {
  description = "GCP Organization ID (numeric)."
  type        = string
  validation {
    condition     = can(regex("^[0-9]+$", var.organization_id))
    error_message = "organization_id must be the numeric org ID (still the TODO placeholder?). Find it with: gcloud organizations list"
  }
}

variable "github_org" {
  description = "GitHub organization or user name that owns the repos (e.g. lame-login-name)."
  type        = string
  validation {
    condition     = var.github_org != "TODO"
    error_message = "github_org is still the TODO placeholder. Fill in terraform.tfvars before planning."
  }
}

variable "github_repo_org" {
  description = "GitHub repo name for the org/ root (used to scope the WIF principal binding)."
  type        = string
  validation {
    condition     = var.github_repo_org != "TODO"
    error_message = "github_repo_org is still the TODO placeholder. Fill in terraform.tfvars before planning."
  }
}

variable "tf_state_bucket" {
  description = "GCS bucket name that holds all Terraform state. The tf-org SA gets objectAdmin on it."
  type        = string
  validation {
    condition     = var.tf_state_bucket != "TODO"
    error_message = "tf_state_bucket is still the TODO placeholder. Fill in terraform.tfvars before planning."
  }
}

variable "shared_services_folder_id" {
  description = "Numeric ID of the shared-services folder (without 'folders/' prefix). tf-infra is scoped to this folder."
  type        = string
  validation {
    condition     = can(regex("^[0-9]+$", var.shared_services_folder_id))
    error_message = "shared_services_folder_id must be numeric and without the 'folders/' prefix. Find it with: gcloud resource-manager folders list --organization=<ORG_ID>"
  }
}

variable "billing_account_id" {
  description = "Billing account ID. Used to grant tf-infra billing.user so it can attach billing to new projects."
  type        = string
  validation {
    condition     = can(regex("^[A-Z0-9]{6}-[A-Z0-9]{6}-[A-Z0-9]{6}$", var.billing_account_id))
    error_message = "billing_account_id must be in the form XXXXXX-XXXXXX-XXXXXX (still the TODO placeholder?). Find it with: gcloud billing accounts list"
  }
}

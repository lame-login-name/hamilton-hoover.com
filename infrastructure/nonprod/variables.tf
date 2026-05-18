variable "organization_id" {
  description = "GCP Organization ID (numeric)."
  type        = string
}

variable "billing_account_id" {
  description = "Billing account to attach to all projects created in this layer."
  type        = string
}

variable "bootstrap_project_id" {
  description = "Bootstrap project used as the quota/billing project for org-scoped API calls."
  type        = string
}

variable "shared_services_folder_id" {
  description = "Numeric ID of the shared-services folder. Projects created here land in that folder."
  type        = string
}

variable "organization_id" {
  description = "The GCP Organization ID (numeric, e.g. 459863125464)"
  type        = string
}

variable "organization_domain" {
  description = "The organization domain (e.g. hamilton-hoover.com)"
  type        = string
}

variable "billing_account_id" {
  description = "Billing account ID (format: XXXXXX-XXXXXX-XXXXXX)"
  type        = string
}

variable "bootstrap_project_id" {
  description = "Project ID of the bootstrap project. Used as the quota/billing project for org-scoped provider API calls."
  type        = string
}

variable "org_admin_members" {
  description = "IAM members granted org-level admin roles. Format: 'user:email', 'serviceAccount:email', or 'group:email'."
  type        = list(string)
}

variable "allowed_regions" {
  description = "Location values permitted by the gcp.resourceLocations org policy. Accepts region names or GCP location groups (e.g. 'in:us-locations')."
  type        = list(string)
  default     = ["in:us-locations"]
}

variable "org_budget_amount" {
  description = "Monthly spend cap in USD covering all billing account spend."
  type        = number
  default     = 50
}

variable "prod_budget_amount" {
  description = "Monthly spend cap in USD for the prod folder."
  type        = number
  default     = 30
}

variable "nonprod_budget_amount" {
  description = "Monthly spend cap in USD for the nonprod and sandbox folders combined."
  type        = number
  default     = 20
}

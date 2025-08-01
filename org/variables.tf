# Variables for organization-level configurations

variable "organization_id" {
  description = "The GCP Organization ID"
  type        = string
}

variable "organization_domain" {
  description = "The organization domain name"
  type        = string
}

variable "billing_account_id" {
  description = "The billing account ID to associate with projects"
  type        = string
}

# Region and location variables
variable "allowed_regions" {
  description = "List of allowed GCP regions for resource creation"
  type        = list(string)
  default = [
    "us-central1",
    "us-east1",
    "us-west1",
    "europe-west1",
    "asia-southeast1"
  ]
}

variable "default_region" {
  description = "Default region for resources"
  type        = string
  default     = "us-central1"
}

variable "default_zone" {
  description = "Default zone for resources"
  type        = string
  default     = "us-central1-a"
}

# IAM member variables
variable "org_admin_members" {
  description = "List of members to grant organization admin role"
  type        = list(string)
  default     = []
}

variable "billing_admin_members" {
  description = "List of members to grant billing admin role"
  type        = list(string)
  default     = []
}

variable "security_admin_members" {
  description = "List of members to grant security admin role"
  type        = list(string)
  default     = []
}

variable "network_admin_members" {
  description = "List of members to grant network admin role"
  type        = list(string)
  default     = []
}

variable "folder_creator_members" {
  description = "List of members to grant folder creator role"
  type        = list(string)
  default     = []
}

variable "project_creator_members" {
  description = "List of members to grant project creator role"
  type        = list(string)
  default     = []
}

variable "org_viewer_members" {
  description = "List of members to grant organization viewer role"
  type        = list(string)
  default     = []
}

variable "asset_viewer_members" {
  description = "List of members to grant cloud asset viewer role"
  type        = list(string)
  default     = []
}

variable "limited_project_manager_members" {
  description = "List of members to grant limited project manager role"
  type        = list(string)
  default     = []
}

# Folder admin variables
variable "production_admin_members" {
  description = "List of members to grant production folder admin role"
  type        = list(string)
  default     = []
}

variable "staging_admin_members" {
  description = "List of members to grant staging folder admin role"
  type        = list(string)
  default     = []
}

variable "development_admin_members" {
  description = "List of members to grant development folder admin role"
  type        = list(string)
  default     = []
}

variable "shared_services_admin_members" {
  description = "List of members to grant shared services folder admin role"
  type        = list(string)
  default     = []
}

variable "security_folder_admin_members" {
  description = "List of members to grant security folder admin role"
  type        = list(string)
  default     = []
}

variable "sandbox_user_members" {
  description = "List of members to grant sandbox access"
  type        = list(string)
  default     = []
}

# Billing variables
variable "budget_currency" {
  description = "Currency for budgets"
  type        = string
  default     = "USD"
}

variable "organization_budget_amount" {
  description = "Total organization budget amount"
  type        = string
  default     = "10000"
}

variable "production_budget_amount" {
  description = "Production environment budget amount"
  type        = string
  default     = "5000"
}

variable "development_budget_amount" {
  description = "Development environment budget amount"
  type        = string
  default     = "1000"
}

variable "budget_notification_channels" {
  description = "List of notification channels for budget alerts"
  type        = list(string)
  default     = []
}

variable "production_project_ids" {
  description = "List of production project IDs for budget tracking"
  type        = list(string)
  default     = []
}

variable "development_project_ids" {
  description = "List of development project IDs for budget tracking"
  type        = list(string)
  default     = []
}

variable "billing_user_members" {
  description = "List of members to grant billing user role"
  type        = list(string)
  default     = []
}

variable "billing_viewer_members" {
  description = "List of members to grant billing viewer role"
  type        = list(string)
  default     = []
}

variable "billing_export_project_id" {
  description = "Project ID for billing export BigQuery dataset"
  type        = string
}

variable "billing_export_location" {
  description = "Location for billing export BigQuery dataset"
  type        = string
  default     = "US"
}

variable "billing_export_owner_email" {
  description = "Email of the billing export dataset owner"
  type        = string
}

# Common tags
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    "managed-by" = "terraform"
    "environment" = "organization"
  }
}

variable "enable_apis" {
  description = "List of APIs to enable at the organization level"
  type        = list(string)
  default = [
    "cloudresourcemanager.googleapis.com",
    "cloudbilling.googleapis.com",
    "iam.googleapis.com",
    "cloudidentity.googleapis.com",
    "orgpolicy.googleapis.com",
    "securitycenter.googleapis.com",
    "cloudasset.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com"
  ]
}
variable "project_id" {
  description = "The globally unique project ID. Convention: hh-{purpose}-{env}."
  type        = string
}

variable "project_name" {
  description = "Human-readable display name shown in the GCP console."
  type        = string
}

variable "folder_id" {
  description = "Numeric folder ID to create the project in (without 'folders/' prefix)."
  type        = string
}

variable "billing_account_id" {
  description = "Billing account to attach to the project (format: XXXXXX-XXXXXX-XXXXXX)."
  type        = string
}

variable "environment" {
  description = "Lifecycle environment. Controls labeling and policy inheritance."
  type        = string
  validation {
    condition     = contains(["prod", "nonprod", "sandbox", "shared", "platform"], var.environment)
    error_message = "environment must be one of: prod, nonprod, sandbox, shared, platform."
  }
}

variable "purpose" {
  description = "Short description of what this project does. Used as a label value."
  type        = string
}

variable "activate_apis" {
  description = "APIs to enable in addition to the baseline set (cloudresourcemanager, iam, logging, monitoring)."
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Additional labels merged with the baseline set. Baseline keys take precedence."
  type        = map(string)
  default     = {}
}

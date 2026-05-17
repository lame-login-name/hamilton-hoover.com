variable "bootstrap_project_id" {
  description = "Project ID of the bootstrap project where WIF and service accounts live."
  type        = string
}

variable "organization_id" {
  description = "GCP Organization ID (numeric)."
  type        = string
}

variable "github_org" {
  description = "GitHub organization or user name that owns the repos (e.g. lame-login-name)."
  type        = string
}

variable "github_repo_org" {
  description = "GitHub repo name for the org/ root (used to scope the WIF principal binding)."
  type        = string
}

variable "tf_state_bucket" {
  description = "GCS bucket name that holds all Terraform state. The tf-org SA gets objectAdmin on it."
  type        = string
}

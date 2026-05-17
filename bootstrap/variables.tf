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

variable "github_repo" {
  description = "GitHub repository name (e.g. hamilton-hoover.com). Used to scope the WIF principal binding to this repo only."
  type        = string
}

variable "tf_state_bucket" {
  description = "GCS bucket name that holds all Terraform state. The tf-org SA gets objectAdmin on it."
  type        = string
}

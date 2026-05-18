terraform {
  required_version = ">= 1.5"
  required_providers {
    google = { source = "hashicorp/google", version = "~> 6.0" }
  }
  # State prefix mirrors directory structure.
  # Bucket name must match var.tf_state_bucket — Terraform does not
  # allow variable references in backend blocks.
  backend "gcs" {
    bucket = "hh-org-tfstate"
    prefix = "infrastructure/nonprod"
  }
}

provider "google" {
  billing_project       = var.bootstrap_project_id
  user_project_override = true
}

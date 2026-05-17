terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  backend "gcs" {
    bucket = "hh-org-tfstate"
    prefix = "bootstrap"
  }
}

# Resources in this root live in the bootstrap project, not at org level,
# so no user_project_override is needed.
provider "google" {
  project = var.bootstrap_project_id
}

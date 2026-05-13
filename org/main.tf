terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  # Backend config cannot use variables — update bucket name here if yours differs.
  # State prefix keeps org state isolated from future root configs.
  backend "gcs" {
    bucket = "hh-org-tfstate"
    prefix = "org"
  }
}

# Credentials come from ADC (gcloud auth application-default login).
# billing_project is required for quota when making org-scoped API calls
# that don't have a natural project context.
provider "google" {
  billing_project       = var.bootstrap_project_id
  user_project_override = true
}

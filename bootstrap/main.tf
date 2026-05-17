terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  # NOTE: Terraform backend config cannot reference variables (language limitation).
  # This bucket name MUST match var.tf_state_bucket — both refer to the same bucket
  # but serve different purposes (state storage here vs IAM grant in wif.tf).
  # If you ever rename the bucket, update both this block and terraform.tfvars.
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

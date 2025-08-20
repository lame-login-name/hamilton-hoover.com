# Non-Production Infrastructure Main Configuration
# This file contains the core Terraform configuration for non-production environments

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 4.0"
    }
  }
}

# Local values for non-production environment
locals {
  environment = "non-production"
  common_labels = merge(var.nonprod_common_labels, {
    environment = "non-production"
    managed_by  = "terraform"
    directory   = "infrastructure/non-prod"
  })
}

# Data sources
data "google_project" "host_project" {
  project_id = var.nonprod_shared_vpc_host_project_id
}

data "google_project" "dns_project" {
  project_id = var.nonprod_dns_project_id
}
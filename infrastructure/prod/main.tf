# Production Infrastructure Main Configuration
# This file contains the core Terraform configuration for production environment

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

# Local values for production environment
locals {
  environment = "production"
  common_labels = merge(var.prod_common_labels, {
    environment = "production"
    managed_by  = "terraform"
    directory   = "infrastructure/prod"
  })
}

# Data sources
data "google_project" "host_project" {
  project_id = var.prod_shared_vpc_host_project_id
}

data "google_project" "dns_project" {
  project_id = var.prod_dns_project_id
}
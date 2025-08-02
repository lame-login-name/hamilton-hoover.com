# Organization Policies for GCP Organization
# This file defines organization-level constraints and policies

# Require OS Login for all compute instances
resource "google_organization_policy" "os_login" {
  org_id     = var.organization_id
  constraint = "compute.requireOsLogin"

  boolean_policy {
    enforced = true
  }
}

# Restrict VM external IP access
resource "google_organization_policy" "vm_external_ip_access" {
  org_id     = var.organization_id
  constraint = "compute.vmExternalIpAccess"

  list_policy {
    deny {
      all = true
    }
  }
}

# Restrict public IP access on Cloud SQL instances
resource "google_organization_policy" "sql_restrict_public_ip" {
  org_id     = var.organization_id
  constraint = "sql.restrictPublicIp"

  boolean_policy {
    enforced = true
  }
}

# Require HTTPS load balancers
resource "google_organization_policy" "load_balancer_https_only" {
  org_id     = var.organization_id
  constraint = "compute.requireSslLoadBalancerTargetHttpsProxy"

  boolean_policy {
    enforced = true
  }
}

# Restrict service account key creation
resource "google_organization_policy" "restrict_service_account_keys" {
  org_id     = var.organization_id
  constraint = "iam.disableServiceAccountKeyCreation"

  boolean_policy {
    enforced = true
  }
}

# Require encryption in transit
resource "google_organization_policy" "encryption_in_transit" {
  org_id     = var.organization_id
  constraint = "compute.requireTlsssPolicy"

  boolean_policy {
    enforced = true
  }
}

# Restrict resource locations to specific regions
resource "google_organization_policy" "resource_locations" {
  org_id     = var.organization_id
  constraint = "gcp.resourceLocations"

  list_policy {
    allow {
      values = var.allowed_regions
    }
  }
}
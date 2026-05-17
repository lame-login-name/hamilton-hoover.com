# Organization policies using OrgPolicy v2 API (google_org_policy_policy).
# All policies are set at the org root and inherited by every folder and project.
# To override a policy for a specific folder (e.g. relax external IP in sandbox),
# create a separate google_org_policy_policy targeting that folder's parent path.

# Prevent the default VPC from being auto-created in every new project.
# This forces intentional network design — no accidental open networks.
resource "google_org_policy_policy" "skip_default_network" {
  name   = "organizations/${var.organization_id}/policies/compute.skipDefaultNetworkCreation"
  parent = "organizations/${var.organization_id}"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

# Require OS Login on all Compute Engine VMs.
# Ties SSH access to IAM identities instead of project-level SSH keys.
resource "google_org_policy_policy" "require_os_login" {
  name   = "organizations/${var.organization_id}/policies/compute.requireOsLogin"
  parent = "organizations/${var.organization_id}"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

# Block external (public) IPs on all VM instances.
# Traffic must flow through Cloud NAT or load balancers instead.
resource "google_org_policy_policy" "vm_no_external_ip" {
  name   = "organizations/${var.organization_id}/policies/compute.vmExternalIpAccess"
  parent = "organizations/${var.organization_id}"

  spec {
    rules {
      deny_all = "TRUE"
    }
  }
}

# Block public IPs on Cloud SQL instances.
resource "google_org_policy_policy" "sql_no_public_ip" {
  name   = "organizations/${var.organization_id}/policies/sql.restrictPublicIp"
  parent = "organizations/${var.organization_id}"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

# Disable service account key file creation across the org.
# Long-lived key files are a credential leak risk. Use WIF instead.
resource "google_org_policy_policy" "no_sa_key_creation" {
  name   = "organizations/${var.organization_id}/policies/iam.disableServiceAccountKeyCreation"
  parent = "organizations/${var.organization_id}"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

# Enforce uniform bucket-level access on all GCS buckets.
# Disables per-object ACLs and ensures IAM is the single access control plane.
resource "google_org_policy_policy" "gcs_uniform_access" {
  name   = "organizations/${var.organization_id}/policies/storage.uniformBucketLevelAccess"
  parent = "organizations/${var.organization_id}"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

# Restrict IAM policy members to identities within this Cloud Identity directory.
# Prevents granting roles to external users (e.g. random Gmail accounts) on any
# resource in the org. Scoped to the customer ID rather than a domain string so
# it covers all domains in the Cloud Identity tenant automatically.
resource "google_org_policy_policy" "allowed_policy_member_domains" {
  name   = "organizations/${var.organization_id}/policies/iam.allowedPolicyMemberDomains"
  parent = "organizations/${var.organization_id}"

  spec {
    rules {
      values {
        allowed_values = ["principalSet://goog/cloudIdentityCustomerId/${var.cloud_identity_customer_id}"]
      }
    }
  }
}

# Enforce public access prevention on all GCS buckets.
# Blocks any IAM grant that would make bucket objects publicly accessible,
# even if uniform bucket-level access is somehow bypassed.
resource "google_org_policy_policy" "gcs_public_access_prevention" {
  name   = "organizations/${var.organization_id}/policies/storage.publicAccessPrevention"
  parent = "organizations/${var.organization_id}"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

# Restrict resource creation to allowed regions.
# Default: US locations only. Override var.allowed_regions to expand.
resource "google_org_policy_policy" "resource_locations" {
  name   = "organizations/${var.organization_id}/policies/gcp.resourceLocations"
  parent = "organizations/${var.organization_id}"

  spec {
    rules {
      values {
        allowed_values = var.allowed_regions
      }
    }
  }
}

# Workload Identity Federation + CI service accounts.
#
# Applied manually (not via CI) since it bootstraps the very identity
# that CI uses. Changes here are rare — only when adding a new repo/SA.
#
# Apply sequence:
#   1. terraform apply  (this root)
#   2. Copy wif_provider + tf_org_sa_email outputs to GitHub Actions variables
#   3. terraform apply in org/  (grants org-level roles to the SA)
#   4. Push a PR — CI should plan and post a comment

# --- APIs ---

resource "google_project_service" "iamcredentials" {
  project            = var.bootstrap_project_id
  service            = "iamcredentials.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "sts" {
  project            = var.bootstrap_project_id
  service            = "sts.googleapis.com"
  disable_on_destroy = false
}

# --- Workload Identity Pool ---

resource "google_iam_workload_identity_pool" "github" {
  project                   = var.bootstrap_project_id
  workload_identity_pool_id = "github-actions"
  display_name              = "GitHub Actions"
  description               = "WIF pool for GitHub Actions OIDC authentication."

  depends_on = [google_project_service.iamcredentials]
}

# --- GitHub OIDC provider ---

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.bootstrap_project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-oidc"
  display_name                       = "GitHub OIDC"

  # Map GitHub token claims to Google attributes used in principal bindings.
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  # Restrict pool to this GitHub org — prevents other orgs from obtaining tokens.
  attribute_condition = "assertion.repository_owner == '${var.github_org}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# --- Terraform service account: org root ---

resource "google_service_account" "tf_org" {
  project      = var.bootstrap_project_id
  account_id   = "tf-org"
  display_name = "Terraform SA — org root"
  description  = "Used by GitHub Actions to manage org-level GCP resources (folders, policies, IAM, budgets)."
}

# Allow GitHub Actions workflows in the org repo to impersonate this SA.
# Scoped to the specific repo — not the whole GitHub org.
resource "google_service_account_iam_member" "tf_org_wif" {
  service_account_id = google_service_account.tf_org.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_org}/${var.github_repo_org}"
}

# Grant the SA objectAdmin on the state bucket so it can read/write state.
resource "google_storage_bucket_iam_member" "tf_org_state" {
  bucket = var.tf_state_bucket
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.tf_org.email}"
}

# --- Org-level roles for tf-org ---
# These allow the SA to manage the resources defined in org/.

resource "google_organization_iam_member" "tf_org_org_admin" {
  org_id = var.organization_id
  role   = "roles/resourcemanager.organizationAdmin"
  member = "serviceAccount:${google_service_account.tf_org.email}"
}

resource "google_organization_iam_member" "tf_org_folder_admin" {
  org_id = var.organization_id
  role   = "roles/resourcemanager.folderAdmin"
  member = "serviceAccount:${google_service_account.tf_org.email}"
}

resource "google_organization_iam_member" "tf_org_policy_admin" {
  org_id = var.organization_id
  role   = "roles/orgpolicy.policyAdmin"
  member = "serviceAccount:${google_service_account.tf_org.email}"
}

resource "google_organization_iam_member" "tf_org_billing_admin" {
  org_id = var.organization_id
  role   = "roles/billing.admin"
  member = "serviceAccount:${google_service_account.tf_org.email}"
}

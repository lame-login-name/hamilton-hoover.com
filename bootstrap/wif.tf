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

# --- Terraform service account: infrastructure ---

resource "google_service_account" "tf_infra" {
  project      = var.bootstrap_project_id
  account_id   = "tf-infra"
  display_name = "Terraform SA — infrastructure"
  description  = "Used by GitHub Actions to manage shared infrastructure projects (logging, networking)."
}

# Allow GitHub Actions workflows in the same repo to impersonate this SA.
resource "google_service_account_iam_member" "tf_infra_wif" {
  service_account_id = google_service_account.tf_infra.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_org}/${var.github_repo_org}"
}

# GCS state access
resource "google_storage_bucket_iam_member" "tf_infra_state" {
  bucket = var.tf_state_bucket
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.tf_infra.email}"
}

# --- Folder-level roles for tf-infra (shared-services folder) ---
# Scoped to shared-services only — tf-infra cannot touch prod or nonprod workload folders.
#
# Every role below exists because a specific resource in infrastructure/ needs it:
#
#   google_project.this               → projectCreator, projectDeleter
#   google_project_service.apis       → serviceUsageAdmin
#   google_bigquery_dataset           → bigquery.dataOwner
#   google_bigquery_dataset_iam_member→ bigquery.dataOwner (datasets.setIamPolicy)
#
# Org-level and billing-level grants live further down; they cover the org log
# sink and billing attachment respectively.
#
# Deliberately NOT granted here: roles/editor.
#
# GCP grants roles/owner on a project to whichever identity creates it, so
# tf-infra already holds owner on every project it provisions — verified on
# hh-logging-nonprod. A folder-wide editor binding adds nothing for those
# projects and additionally covers any project tf-infra did NOT create, which
# is precisely the blast radius worth avoiding. The narrow roles below are
# still declared explicitly rather than leaning on that implicit owner grant,
# so this keeps working if the owner binding is ever cleaned up.

resource "google_folder_iam_member" "tf_infra_project_creator" {
  folder = "folders/${var.shared_services_folder_id}"
  role   = "roles/resourcemanager.projectCreator"
  member = "serviceAccount:${google_service_account.tf_infra.email}"
}

resource "google_folder_iam_member" "tf_infra_project_deleter" {
  folder = "folders/${var.shared_services_folder_id}"
  role   = "roles/resourcemanager.projectDeleter"
  member = "serviceAccount:${google_service_account.tf_infra.email}"
}

# Enables APIs during project creation, before the implicit owner binding on the
# new project is usable.
resource "google_folder_iam_member" "tf_infra_service_usage" {
  folder = "folders/${var.shared_services_folder_id}"
  role   = "roles/serviceusage.serviceUsageAdmin"
  member = "serviceAccount:${google_service_account.tf_infra.email}"
}

# dataOwner covers datasets.create / update / delete / setIamPolicy — everything
# the audit log dataset and its sink-writer binding need. bigquery.admin would
# additionally grant job, reservation, and transfer permissions that nothing in
# this repo uses.
resource "google_folder_iam_member" "tf_infra_bigquery_data_owner" {
  folder = "folders/${var.shared_services_folder_id}"
  role   = "roles/bigquery.dataOwner"
  member = "serviceAccount:${google_service_account.tf_infra.email}"
}

# --- Org-level roles for tf-infra ---
# Required to create org-level log sinks (include_children = true).

resource "google_organization_iam_member" "tf_infra_logging_config" {
  org_id = var.organization_id
  role   = "roles/logging.configWriter"
  member = "serviceAccount:${google_service_account.tf_infra.email}"
}

# --- Billing account role for tf-infra ---
# Required to attach billing to new projects.

resource "google_billing_account_iam_member" "tf_infra_billing_user" {
  billing_account_id = var.billing_account_id
  role               = "roles/billing.user"
  member             = "serviceAccount:${google_service_account.tf_infra.email}"
}

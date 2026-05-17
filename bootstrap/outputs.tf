output "wif_provider" {
  description = "Full WIF provider resource name. Set this as the WIF_PROVIDER GitHub Actions repository variable."
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "tf_org_sa_email" {
  description = "tf-org service account email. Set this as the TF_ORG_SA GitHub Actions repository variable."
  value       = google_service_account.tf_org.email
}

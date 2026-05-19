# CI-facing variable values. Committed intentionally — contains no secrets or PII.
# Sensitive values (billing_account_id) are injected at runtime from GitHub Actions
# variables — see terraform-infrastructure.yml.

organization_id      = "459863125464"
bootstrap_project_id = "massive-runway-432502-n1"

# shared-services folder — target for logging and shared infrastructure projects
shared_services_folder_id = "959737491214"

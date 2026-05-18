output "project_id" {
  description = "The project ID."
  value       = google_project.this.project_id
}

output "project_number" {
  description = "The numeric project number. Used for service account email construction and some API calls."
  value       = google_project.this.number
}

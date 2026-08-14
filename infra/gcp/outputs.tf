output "api_url" {
  description = "Public HTTPS endpoint. This is the base URL the Flutter apps point at."
  value       = google_cloud_run_v2_service.api.uri
}

output "uploads_bucket" {
  description = "Cloud Storage bucket backing document and proof-of-payment uploads."
  value       = google_storage_bucket.uploads.name
}

output "artifact_registry_repo" {
  description = "Docker repo path to push API images to."
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.api.repository_id}"
}

output "api_service_account" {
  description = "Runtime identity of the API."
  value       = google_service_account.api.email
}

output "github_workload_identity_provider" {
  description = "Value for the WIF_PROVIDER GitHub repository variable."
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "github_deployer_service_account" {
  description = "Value for the WIF_SERVICE_ACCOUNT GitHub repository variable."
  value       = google_service_account.deployer.email
}

output "secrets_pending_values" {
  description = "Secrets created empty by Terraform. Cloud Run will not start until each has a version."
  value       = [for s in google_secret_manager_secret.app : s.secret_id]
}

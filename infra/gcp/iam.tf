# The API runs as its own service account rather than the default Compute one,
# which is over-privileged (project Editor).
resource "google_service_account" "api" {
  project      = var.project_id
  account_id   = "lizmo-api"
  display_name = "Lizmo API (Cloud Run)"

  depends_on = [google_project_service.required]
}

# Read/write objects in the uploads bucket only — scoped to the bucket, not the
# project, so this cannot touch any other storage.
resource "google_storage_bucket_iam_member" "api_uploads" {
  bucket = google_storage_bucket.uploads.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.api.email}"
}

# Signing presigned upload URLs requires the SA to sign as itself.
resource "google_service_account_iam_member" "api_token_creator" {
  service_account_id = google_service_account.api.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.api.email}"
}

# Read the two secrets, individually — not project-wide secret access.
resource "google_secret_manager_secret_iam_member" "api_secrets" {
  for_each = google_secret_manager_secret.app

  project   = var.project_id
  secret_id = each.value.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.api.email}"
}

# Separate identity for Cloud Scheduler, so a compromised scheduler token cannot
# read secrets or touch storage — it can only invoke the service.
resource "google_service_account" "scheduler" {
  project      = var.project_id
  account_id   = "lizmo-scheduler"
  display_name = "Lizmo scheduled jobs"

  depends_on = [google_project_service.required]
}

resource "google_cloud_run_v2_service_iam_member" "scheduler_invoker" {
  project  = var.project_id
  location = google_cloud_run_v2_service.api.location
  name     = google_cloud_run_v2_service.api.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.scheduler.email}"
}

# Service account for GitHub Actions Workload Identity Federation
resource "google_service_account" "github_deployer" {
  account_id   = "github-deployer"
  display_name = "GitHub Actions Deployer"
}

# Grant Artifact Registry write access
resource "google_project_iam_member" "github_artifactregistry_writer" {
  project = var.gcp_project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.github_deployer.email}"
}

# Grant service account impersonation (if needed)
resource "google_project_iam_member" "github_serviceaccount_user" {
  project = var.gcp_project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.github_deployer.email}"
}

# Output the service account email for GitHub Actions configuration
output "github_deployer_email" {
  value = google_service_account.github_deployer.email
}

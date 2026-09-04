# The API runs as its own service account rather than the default Compute one,
# which is over-privileged (project Editor).
resource "google_service_account" "api" {
  project      = var.project_id
  account_id   = "lizmo-api"
  display_name = "Lizmo API (Cloud Run)"

  depends_on = [google_project_service.required]
}

# No storage bindings: uploads are in Supabase, reached with an S3 key rather
# than with this identity. The service account's only privilege is reading its
# own secrets, below.

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

# The API runs as its own service account rather than the default Compute one,
# which is over-privileged (project Editor).
resource "google_service_account" "api" {
  project      = var.project_id
  account_id   = "lizmo-api"
  display_name = "Lizmo API (Cloud Run)"

  depends_on = [google_project_service.required]
}

# No storage bindings: uploads are in Supabase, reached with an S3 key rather
# than with this identity. The service account's privileges are reading its own
# secrets, and sending push notifications, below.

# Read the two secrets, individually — not project-wide secret access.
resource "google_secret_manager_secret_iam_member" "api_secrets" {
  for_each = google_secret_manager_secret.app

  project   = var.project_id
  secret_id = each.value.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.api.email}"
}

# Push notifications through Firebase Cloud Messaging, sent as this identity.
#
# Firebase is this project's own (added to lizmo-test rather than made apart),
# so the API needs no key file: Cloud Run's credentials are enough, and there
# is no secret to leak. Project-level because that is where FCM's permission
# lives; this is the narrowest predefined role that can send.
resource "google_project_iam_member" "api_sends_push" {
  project = var.project_id
  role    = "roles/firebasecloudmessaging.admin"
  member  = "serviceAccount:${google_service_account.api.email}"
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

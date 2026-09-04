# The two background jobs from tech spec §7. Running them as Cloud Scheduler
# hits rather than Spring @Scheduled means they fire exactly once regardless of
# how many Cloud Run instances are up — with min_instances = 0, an in-process
# scheduler would not run at all while the service is asleep.
#
# Both authenticate with an OIDC token. The API must reject these paths for any
# other caller; being on /internal/ is not itself protection.
#
# CREATED PAUSED, and they stay that way until those endpoints exist. Neither
# /internal/jobs/* path is implemented: unpaused, these would POST into a 404
# every night, retry three times, and file the failures somewhere nobody reads
# -- so the first thing anybody learns from this alerting is to ignore it.
#
# To start them, once the endpoints are built and verify the OIDC token:
#
#   gcloud scheduler jobs resume lizmo-platform-billing-snapshot --location=asia-southeast1
#   gcloud scheduler jobs resume lizmo-platform-billing-enforcement --location=asia-southeast1
#
# Terraform ignores the paused flag afterwards, so resuming by hand is not
# undone by the next apply.

resource "google_cloud_scheduler_job" "billing_snapshot" {
  project     = var.project_id
  region      = var.region
  name        = "lizmo-platform-billing-snapshot"
  description = "Monthly: count each landlord's occupied slots and raise one invoice."
  schedule    = var.billing_snapshot_cron
  time_zone   = var.scheduler_timezone

  attempt_deadline = "320s"
  paused           = true

  retry_config {
    retry_count = 3
  }

  http_target {
    http_method = "POST"
    uri         = "${google_cloud_run_v2_service.api.uri}/internal/jobs/platform-billing-snapshot"

    oidc_token {
      service_account_email = google_service_account.scheduler.email
      audience              = google_cloud_run_v2_service.api.uri
    }
  }

  lifecycle {
    ignore_changes = [paused]
  }

  depends_on = [google_project_service.required]
}

resource "google_cloud_scheduler_job" "billing_enforcement" {
  project     = var.project_id
  region      = var.region
  name        = "lizmo-platform-billing-enforcement"
  description = "Daily: flip passed-due cycles to OVERDUE, then LOCK accounts 7 days on."
  schedule    = var.billing_enforcement_cron
  time_zone   = var.scheduler_timezone

  attempt_deadline = "320s"
  paused           = true

  retry_config {
    retry_count = 3
  }

  http_target {
    http_method = "POST"
    uri         = "${google_cloud_run_v2_service.api.uri}/internal/jobs/platform-billing-enforcement"

    oidc_token {
      service_account_email = google_service_account.scheduler.email
      audience              = google_cloud_run_v2_service.api.uri
    }
  }

  lifecycle {
    ignore_changes = [paused]
  }

  depends_on = [google_project_service.required]
}

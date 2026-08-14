# Replaces the tech spec's S3 uploads bucket: payment proofs, documents, notice
# attachments, maintenance photos.
#
# Cost note: the 5 GB always-free allowance applies to US regions only. Keeping
# the bucket in asia-southeast1 costs roughly a few cents per month at this
# scale, which is worth paying to avoid cross-region latency on every upload.
resource "google_storage_bucket" "uploads" {
  name     = "${var.project_id}-lizmo-uploads"
  location = var.region
  project  = var.project_id

  # Objects are served through signed URLs, never public reads.
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  # Payment proofs are evidence in a dispute — keep superseded versions for a
  # year rather than letting a re-upload destroy the original.
  lifecycle_rule {
    condition {
      num_newer_versions         = 3
      days_since_noncurrent_time = 365
    }
    action {
      type = "Delete"
    }
  }

  cors {
    origin          = ["*"]
    method          = ["GET", "PUT", "POST", "HEAD"]
    response_header = ["Content-Type", "Content-MD5", "x-goog-resumable"]
    max_age_seconds = 3600
  }

  depends_on = [google_project_service.required]
}

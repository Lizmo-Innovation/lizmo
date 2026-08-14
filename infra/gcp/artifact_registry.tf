# Holds the API image. The always-free allowance is 0.5 GB, and a Spring Boot
# JRE image runs 200-300 MB, so the cleanup policy below matters — a handful of
# untended tags will exceed the free tier on their own.
resource "google_artifact_registry_repository" "api" {
  project       = var.project_id
  location      = var.region
  repository_id = "lizmo"
  format        = "DOCKER"
  description   = "Lizmo API container images"

  cleanup_policies {
    id     = "keep-recent-releases"
    action = "KEEP"
    most_recent_versions {
      keep_count = 5
    }
  }

  cleanup_policies {
    id     = "drop-untagged"
    action = "DELETE"
    condition {
      tag_state  = "UNTAGGED"
      older_than = "7d"
    }
  }

  depends_on = [google_project_service.required]
}

resource "google_cloud_run_v2_service" "api" {
  project  = var.project_id
  name     = var.service_name
  location = var.region

  # Public: the mobile apps call this directly, and there is no load balancer in
  # front (an external HTTPS LB is billable; Cloud Run's own *.run.app endpoint
  # already terminates TLS). Endpoint authorisation is the API's job — see the
  # JWT filter and the authz layers in tech spec §4.
  ingress = "INGRESS_TRAFFIC_ALL"

  deletion_protection = false

  template {
    service_account = google_service_account.api.email

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    containers {
      image = var.image

      resources {
        limits = {
          cpu    = var.cpu
          memory = var.memory
        }
        # CPU only while handling a request — required to stay in the free tier.
        cpu_idle = true
      }

      ports {
        container_port = 8080
      }

      env {
        name  = "SPRING_PROFILES_ACTIVE"
        value = "prod"
      }

      env {
        name  = "GCS_BUCKET"
        value = google_storage_bucket.uploads.name
      }

      env {
        name = "DB_URL"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.app["lizmo-db-url"].secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "JWT_SECRET"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.app["lizmo-jwt-secret"].secret_id
            version = "latest"
          }
        }
      }

      startup_probe {
        # Spring Boot plus Flyway needs time on a cold start; too tight a probe
        # makes Cloud Run kill the container mid-migration.
        initial_delay_seconds = 10
        period_seconds        = 5
        failure_threshold     = 30
        timeout_seconds       = 3
        tcp_socket {
          port = 8080
        }
      }

      liveness_probe {
        http_get {
          path = "/actuator/health"
        }
        initial_delay_seconds = 30
        period_seconds        = 30
      }
    }
  }

  lifecycle {
    # CI pushes new images; Terraform should not revert them on the next apply.
    ignore_changes = [template[0].containers[0].image]
  }

  depends_on = [
    google_project_service.required,
    google_secret_manager_secret_iam_member.api_secrets,
  ]
}

# The mobile apps are unauthenticated at the transport layer — the API validates
# JWTs itself.
resource "google_cloud_run_v2_service_iam_member" "public" {
  project  = var.project_id
  location = google_cloud_run_v2_service.api.location
  name     = google_cloud_run_v2_service.api.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

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

      # Uploads: Supabase Storage over its S3-compatible endpoint. The API's
      # S3 client and presigner both address it path-style, which is what this
      # endpoint requires -- see S3Config.
      env {
        name  = "AWS_S3_ENDPOINT"
        value = local.storage_endpoint
      }

      env {
        name  = "AWS_S3_BUCKET"
        value = var.storage_bucket
      }

      env {
        name  = "AWS_REGION"
        value = var.storage_region
      }

      env {
        name = "AWS_ACCESS_KEY_ID"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.app["lizmo-storage-access-key"].secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "AWS_SECRET_ACCESS_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.app["lizmo-storage-secret-key"].secret_id
            version = "latest"
          }
        }
      }

      # Mail. Without it nobody can sign up: the code that proves an address is
      # the first step of registration, and an invitation is the only way a
      # landlord exists at all.
      env {
        name  = "MAIL_HOST"
        value = var.mail_host
      }

      env {
        name  = "MAIL_PORT"
        value = var.mail_port
      }

      env {
        name  = "MAIL_USERNAME"
        value = var.mail_username
      }

      env {
        name  = "MAIL_FROM"
        value = var.mail_from
      }

      env {
        name = "MAIL_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.app["lizmo-mail-password"].secret_id
            version = "latest"
          }
        }
      }

      # Which browser origins may call the API. The console is a browser
      # client, so without its exact origin here every request it makes is
      # blocked by CORS -- and blocked in a way that reads, in the console's
      # own error output, like the API being down.
      env {
        name  = "LIZMO_CORS_ORIGINS"
        value = google_cloud_run_v2_service.admin.uri
      }

      # Where a landlord invitation link points.
      #
      # Nothing serves this path yet: there is no domain, no deep link, and no
      # accept screen. The link is a placeholder that has to be *somewhere*,
      # and the email carries the invitation token as text beside it, which is
      # the path that actually works today.
      env {
        name  = "LIZMO_INVITE_BASE_URL"
        value = "${google_cloud_run_v2_service.admin.uri}/invite"
      }

      # Who may run /internal/jobs/*. The service account is the scheduler's
      # own; the audience is this service's URL, without which a token minted
      # for any other Google-fronted service would verify here.
      #
      # Not a secret: both are public facts about the deployment, and the
      # defence is Google's signature rather than these being unguessable.
      env {
        name  = "LIZMO_JOBS_SERVICE_ACCOUNT"
        value = google_service_account.scheduler.email
      }

      # Self-referential: a service cannot read its own URI while it is being
      # created. Set from the same deterministic value Cloud Run assigns, so
      # the audience matches what Scheduler puts in the token.
      env {
        name  = "LIZMO_JOBS_AUDIENCE"
        value = var.api_base_url
      }

      # Push notifications through Firebase, which was added to this same
      # project: the API sends as its own service account, with no key file
      # (see api_sends_push in iam.tf).
      env {
        name  = "LIZMO_PUSH_ENABLED"
        value = "true"
      }

      env {
        name  = "LIZMO_FIREBASE_PROJECT"
        value = var.project_id
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
        name = "DB_USER"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.app["lizmo-db-user"].secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "DB_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.app["lizmo-db-password"].secret_id
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

      # Liveness asks "is this process wedged", nothing more.
      #
      # It pointed at /actuator/health, which opens a database connection and
      # takes over a second -- against a probe timeout that defaults to ONE
      # second when unset. Every probe timed out, three in a row killed the
      # instance, and the restart cold-started for 10-20s. The service spent
      # its first hour in a kill-restart loop and answered 503.
      #
      # So: the liveness group, which excludes the database, and a timeout that
      # is not the default. A database outage must not be answered by killing
      # containers that are working.
      liveness_probe {
        http_get {
          path = "/actuator/health/liveness"
        }
        initial_delay_seconds = 30
        period_seconds        = 30
        timeout_seconds       = 5
        failure_threshold     = 3
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

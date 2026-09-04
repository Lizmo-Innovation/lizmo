# Lizmo's internal console, as a second Cloud Run service.
#
# A container of static files behind nginx rather than a bucket website: Cloud
# Run terminates TLS on its own *.run.app hostname, and serving a bucket over
# HTTPS needs a load balancer, which is billable. The whole image is a few MB
# and it scales to zero like the API.
#
# Nothing here is a security boundary. The console is a public web page that
# happens to be useful only to an administrator — every /admin route is checked
# server-side against the platform_admins table, and a signed-out visitor sees
# a login screen.

resource "google_cloud_run_v2_service" "admin" {
  project  = var.project_id
  name     = var.admin_service_name
  location = var.region

  ingress             = "INGRESS_TRAFFIC_ALL"
  deletion_protection = false

  template {
    scaling {
      # Static files with no cold-start cost worth paying for.
      min_instance_count = 0
      max_instance_count = 2
    }

    containers {
      image = var.admin_image

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
        cpu_idle = true
      }

      # nginx's own port, from infra/nginx/flutter-web.conf. Cloud Run routes to
      # whatever port is declared here, so the image does not need rewriting to
      # listen on 8080.
      ports {
        container_port = 80
      }

      startup_probe {
        initial_delay_seconds = 2
        period_seconds        = 3
        failure_threshold     = 10
        tcp_socket {
          port = 80
        }
      }
    }
  }

  lifecycle {
    # CI pushes new images; Terraform should not revert them on the next apply.
    ignore_changes = [template[0].containers[0].image]
  }

  depends_on = [google_project_service.required]
}

resource "google_cloud_run_v2_service_iam_member" "admin_public" {
  project  = var.project_id
  location = google_cloud_run_v2_service.admin.location
  name     = google_cloud_run_v2_service.admin.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Secret *containers* are managed here; their values are not.
#
# Deliberate: any value Terraform writes ends up in plaintext in the state file.
# These are created empty, and the values are added out-of-band:
#
#   printf 'jdbc:postgresql://...' | gcloud secrets versions add lizmo-db-url --data-file=-
#   openssl rand -base64 48 | gcloud secrets versions add lizmo-jwt-secret --data-file=-
#
# Cloud Run will fail to start until both have at least one version.
locals {
  secrets = {
    "lizmo-db-url"     = "Full JDBC URL for the external Postgres, including credentials and sslmode=require."
    "lizmo-jwt-secret" = "HMAC signing key for access tokens. Rotating it invalidates every issued token."
  }
}

resource "google_secret_manager_secret" "app" {
  for_each = local.secrets

  project   = var.project_id
  secret_id = each.key

  labels = {
    app = "lizmo"
  }

  replication {
    auto {}
  }

  depends_on = [google_project_service.required]
}

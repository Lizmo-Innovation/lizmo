# Secret *containers* are managed here; their values are not.
#
# Deliberate: any value Terraform writes ends up in plaintext in the state file.
# These are created empty, and the values are added out-of-band:
#
#   printf 'jdbc:postgresql://...' | gcloud secrets versions add lizmo-db-url --data-file=-
#   openssl rand -base64 48 | gcloud secrets versions add lizmo-jwt-secret --data-file=-
#
# Cloud Run will fail to start until every one of them has at least one version.
#
# The database credentials are their own secrets rather than embedded in the
# URL. Both work -- pgjdbc lets query parameters override the properties Spring
# supplies, which was measured rather than assumed -- but a password in a URL
# has to be percent-encoded, and Supabase hands out generated passwords full of
# symbols. One unescaped & or # is a truncated password and an authentication
# error that reads like the wrong password entirely.
locals {
  secrets = {
    "lizmo-db-url"      = "JDBC URL for the external Postgres, WITHOUT credentials. Supabase: the session pooler on port 5432, with sslmode=require."
    "lizmo-db-user"     = "Database user. Supabase's pooler expects postgres.<project-ref>, not plain postgres."
    "lizmo-db-password" = "Database password, verbatim -- no URL encoding, because it is not going into a URL."
    "lizmo-jwt-secret"  = "HMAC signing key for access tokens. Rotating it invalidates every issued token."

    "lizmo-storage-access-key" = "Supabase Storage S3 access key ID."
    "lizmo-storage-secret-key" = "Supabase Storage S3 secret access key. Shown once, when the key is created."

    "lizmo-mail-password" = "Brevo SMTP key. Not the account password -- the SMTP key from Brevo's SMTP & API page."
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

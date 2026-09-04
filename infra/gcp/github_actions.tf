# Lets GitHub Actions deploy to GCP without a service account key.
#
# Workload Identity Federation exchanges GitHub's short-lived OIDC token for
# GCP credentials. The alternative — a service account JSON key in repository
# secrets — is a permanent credential that leaks through forks, logs and
# screenshots, and is among the commonest ways GCP projects are compromised.
# There is nothing to leak here.

resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project_id
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions"

  depends_on = [google_project_service.required]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub OIDC"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  # Without this, *any* GitHub repository anywhere could mint tokens for this
  # provider. Scoped to the one repo.
  attribute_condition = "assertion.repository == '${var.github_repository}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Identity the workflow acts as.
resource "google_service_account" "deployer" {
  project      = var.project_id
  account_id   = "lizmo-deployer"
  display_name = "GitHub Actions deployer"

  depends_on = [google_project_service.required]
}

# Scoped to the repository, not to a branch: any workflow in the repository can
# impersonate this account. A fork cannot, because its assertion.repository is
# the fork's own name and fails the provider condition.
#
# To restrict deploys to main as well, map attribute.ref (already mapped above)
# into this member string — worth doing once anyone else can push branches.
resource "google_service_account_iam_member" "github_impersonation" {
  service_account_id = google_service_account.deployer.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repository}"
}

# Push images.
resource "google_artifact_registry_repository_iam_member" "deployer_writer" {
  project    = var.project_id
  location   = google_artifact_registry_repository.api.location
  repository = google_artifact_registry_repository.api.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.deployer.email}"
}

# Deploy new revisions.
resource "google_project_iam_member" "deployer_run" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.deployer.email}"
}

# Deploying a revision means setting its identity, which requires permission to
# act as the runtime service account. Scoped to that one account rather than
# granted project-wide.
resource "google_service_account_iam_member" "deployer_acts_as_api" {
  service_account_id = google_service_account.api.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.deployer.email}"
}

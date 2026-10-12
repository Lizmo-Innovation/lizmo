# Services must be enabled before anything using them can be created.
#
# disable_on_destroy is false deliberately: tearing down this stack should not
# disable APIs that other resources in the project might rely on.
locals {
  required_apis = [
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com",
    "storage.googleapis.com",
    "cloudscheduler.googleapis.com",
    "iam.googleapis.com",
    # Push notifications. Switched on when Firebase was added to the project;
    # listed so this stack keeps it on.
    "fcm.googleapis.com",
  ]
}

resource "google_project_service" "required" {
  for_each = toset(local.required_apis)

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

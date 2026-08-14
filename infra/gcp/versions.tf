terraform {
  required_version = ">= 1.9"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  # State is local by default, which is fine for a single operator. Before a
  # second person (or CI) runs apply, move it to GCS — two operators with
  # separate local state will fight over the same resources.
  #
  # backend "gcs" {
  #   bucket = "lizmo-tfstate"
  #   prefix = "prod"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

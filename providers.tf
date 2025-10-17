terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  # Use gcloud application-default credentials or set GOOGLE_CREDENTIALS env var
  project = var.project
  region  = var.region
}

terraform {
  backend "gcs" {}
}

variable "project" {
}

variable "region" {
}

variable "zone" {
}

provider "google" {
  project = var.project
  region = var.region
}

# PD for Testground daemon datadir
resource "google_compute_disk" "default" {
  name = "testground-daemon-datadir"
  size = 10
  type  = "pd-ssd"
  zone  = var.zone
}

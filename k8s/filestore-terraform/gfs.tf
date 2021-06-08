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

# GFS for Testground outputs
resource "google_filestore_instance" "default" {
  name = "testground"
  tier = "STANDARD"
  file_shares {
    name = "testground"
    capacity_gb = "1024" # 1TiB is the minimum allowed. TODO: fix the cost - only 1GiB is required
  }
  networks {
    network = "default"
    modes = ["MODE_IPV4"]
  }
  zone = var.zone
}

resource "helm_release" "nfs-subdir-external-provisioner" {
  depends_on = [
    google_filestore_instance.default
  ]
  name       = "nfs-subdir-external-provisioner"
  chart      = "nfs-subdir-external-provisioner"
  repository = "https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/"
  version    = "4.0.3"

  set {
    name  = "nfs.server"
    value = google_filestore_instance.default.networks[0].ip_addresses[0]
  }

  set {
    name  = "nfs.path"
    value = "/${google_filestore_instance.default.file_shares[0].name}"
  }

  set {
    name  = "storageClass.name"
    value = "filestore-client"
  }

  set {
    name  = "storageClass.reclaimPolicy"
    value = "Retain"
  }
}

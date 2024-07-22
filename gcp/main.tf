# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

resource "google_compute_network" "hashistack" {
  name = "hashistack-${var.name_prefix}"
}

resource "google_compute_firewall" "consul_nomad_ui_ingress" {
  name          = "${var.name_prefix}-ui-ingress"
  network       = google_compute_network.hashistack.name
  source_ranges = [var.allowlist_ip]

  # Nomad
  allow {
    protocol = "tcp"
    ports    = [4646]
  }

  # Consul
  allow {
    protocol = "tcp"
    ports    = [8500]
  }
}

resource "google_compute_firewall" "ssh_ingress" {
  name          = "${var.name_prefix}-ssh-ingress"
  network       = google_compute_network.hashistack.name
  source_ranges = [var.allowlist_ip]

  # SSH
  allow {
    protocol = "tcp"
    ports    = [22]
  }
}

resource "google_compute_firewall" "allow_all_internal" {
  name        = "${var.name_prefix}-allow-all-internal"
  network     = google_compute_network.hashistack.name
  source_tags = ["auto-join"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
}

resource "google_compute_firewall" "clients_ingress" {
  name          = "${var.name_prefix}-clients-ingress"
  network       = google_compute_network.hashistack.name
  source_ranges = [var.allowlist_ip]
  target_tags   = ["nomad-clients"]

  # Add application ingress rules here
  # These rules are applied only to the client nodes

  # nginx example; replace with your application port
  allow {
    protocol = "tcp"
    ports    = [80]
  }
}

resource "random_uuid" "nomad_id" {
}

resource "random_uuid" "nomad_token" {
}

resource "google_compute_instance" "server" {
  count        = var.server_count
  name         = "${var.name_prefix}-server-${count.index}"
  machine_type = var.server_instance_type
  zone         = var.zone
  tags         = ["auto-join"]

  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = var.machine_image
      size  = var.root_block_device_size
    }
  }

  network_interface {
    network = google_compute_network.hashistack.name
    access_config {
      // Leave empty to get an ephemeral public IP
    }
  }

  service_account {
    # https://developers.google.com/identity/protocols/googlescopes
    scopes = [
      "https://www.googleapis.com/auth/compute.readonly",
      "https://www.googleapis.com/auth/logging.write",
    ]
  }

  metadata_startup_script = templatefile("${path.module}/../shared/data-scripts/user-data-server.sh", {
    server_count              = var.server_count
    region                    = var.region
    cloud_env                 = "gce"
    retry_join                = local.consul_retry_join
    nomad_binary              = var.nomad_binary
    nomad_consul_token_id     = random_uuid.nomad_id.result
    nomad_consul_token_secret = random_uuid.nomad_token.result
  })
}

resource "google_compute_instance" "client" {
  count        = var.client_count
  name         = "${var.name_prefix}-client-${count.index}"
  machine_type = var.client_instance_type
  zone         = var.zone
  tags         = ["auto-join", "nomad-clients"]

  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = var.machine_image
      size  = var.root_block_device_size
    }
  }

  network_interface {
    network = google_compute_network.hashistack.name
    access_config {
      // Leave empty to get an ephemeral public IP
    }
  }

  service_account {
    # https://developers.google.com/identity/protocols/googlescopes
    scopes = [
      "https://www.googleapis.com/auth/compute.readonly",
      "https://www.googleapis.com/auth/logging.write",
    ]
  }

  metadata_startup_script = templatefile("${path.module}/../shared/data-scripts/user-data-client.sh", {
    region                    = var.region
    cloud_env                 = "gce"
    retry_join                = local.consul_retry_join
    nomad_binary              = var.nomad_binary
    nomad_consul_token_secret = random_uuid.nomad_token.result
  })
}

locals {
  consul_retry_join = "project_name=${var.project} zone_pattern=${var.zone} provider=gce tag_value=auto-join"
}
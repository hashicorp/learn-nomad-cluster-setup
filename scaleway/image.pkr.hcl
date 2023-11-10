locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

variable "zone" {
  type    = string
  default = "fr-par-1"
}

variable "project_id" {
  type    = string
  default = null
}

source "scaleway" "hashistack" {
  commercial_type              = "PLAY2-NANO"
  image                        = "ubuntu_focal"
  image_name                   = "hashistack-${local.timestamp}"
  ssh_username                 = "root"
  zone                         = var.zone
  cleanup_machine_related_data = true
}

build {
  sources = ["source.scaleway.hashistack"]

  provisioner "shell" {
    inline = ["sudo mkdir -p /ops/shared", "sudo chmod 777 -R /ops"]
  }

  provisioner "file" {
    destination = "/ops"
    source      = "../shared"
  }

  provisioner "shell" {
    environment_vars = ["INSTALL_NVIDIA_DOCKER=false", "CLOUD_ENV=scaleway"]
    script           = "../shared/scripts/setup.sh"
  }

}

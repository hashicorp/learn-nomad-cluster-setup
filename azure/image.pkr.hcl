packer {
  required_plugins {
    azure = {
      source  = "github.com/hashicorp/azure"
      version = "~> 2.0.5"
    }
  }
}

locals { 
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
  default = "hashistack"
}

source "azure-arm" "hashistack" {
  use_azure_cli_auth = true
  managed_image_resource_group_name = var.resource_group_name
  managed_image_name = "hashistack.${local.timestamp}"
  os_type = "Linux"
  image_publisher = "Canonical"
  image_offer = "0001-com-ubuntu-server-jammy"
  image_sku = "22_04-lts-gen2"

  azure_tags = {
    dept = "education"
  }

  location = var.location
  vm_size = "Standard_B2s"
}

build {
  sources = ["source.azure-arm.hashistack"]

  provisioner "shell" {
    inline = ["sudo mkdir -p /ops/shared", "sudo chmod 777 -R /ops"]
  }

  provisioner "file" {
    destination = "/ops"
    source      = "../shared"
  }

  provisioner "shell" {
    # workaround to cloud-init deleting apt lists while apt-update runs from setup.sh
    inline = ["cloud-init status --wait"]
  }

  provisioner "shell" {
    environment_vars = ["INSTALL_NVIDIA_DOCKER=false", "CLOUD_ENV=aws"]
    script           = "../shared/scripts/setup.sh"
  }
}
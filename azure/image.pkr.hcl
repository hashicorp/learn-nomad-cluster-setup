# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

locals { 
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

variable "location" {
  type = string
}

variable "client_id" {
  type = string
}

variable "client_secret" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "storage_account" {
  type = string
}

variable "subscription_id" {
  type = string
}

variable "tenant_id" {
  type = string
}

source "azure-arm" "hashistack" {
  client_id = var.client_id
  client_secret = var.client_secret
  managed_image_resource_group_name = var.resource_group_name
  managed_image_name = "hashistack.${local.timestamp}"
  subscription_id = var.subscription_id
  tenant_id = var.tenant_id
  os_type = "Linux"
  image_publisher = "Canonical"
  image_offer = "UbuntuServer"
  image_sku = "16.04-LTS"

  azure_tags = {
    dept = "education"
  }

  location = var.location
  vm_size = "Standard_A2"
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
    environment_vars = ["INSTALL_NVIDIA_DOCKER=false", "CLOUD_ENV=aws"]
    script           = "../shared/scripts/setup.sh"
  }
}
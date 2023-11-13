# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  client_id = var.client_id
  client_secret = var.client_secret
  tenant_id = var.tenant_id
}

resource "azurerm_resource_group" "hashistack" {
  name     = "hashistack"
  location = var.location
}

resource "azurerm_virtual_network" "hashistack-vn" {
  name                = "hashistack-vn"
  address_space       = ["10.0.0.0/16"]
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.hashistack.name}"
}

resource "azurerm_subnet" "hashistack-sn" {
  name                 = "hashistack-sn"
  resource_group_name  = "${azurerm_resource_group.hashistack.name}"
  virtual_network_name = "${azurerm_virtual_network.hashistack-vn.name}"
  address_prefixes       = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "hashistack-sg" {
  name                = "hashistack-sg"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.hashistack.name}"
}

resource "azurerm_subnet_network_security_group_association" "hashistack-sg-association" {
  subnet_id                 = azurerm_subnet.hashistack-sn.id
  network_security_group_id = azurerm_network_security_group.hashistack-sg.id
}

resource "azurerm_network_security_rule" "nomad_ui_ingress" {
  name                        = "${var.name}-nomad-ui-ingress"
  resource_group_name         = "${azurerm_resource_group.hashistack.name}"
  network_security_group_name = "${azurerm_network_security_group.hashistack-sg.name}"

  priority  = 101
  direction = "Inbound"
  access    = "Allow"
  protocol  = "Tcp"

  source_address_prefix      = var.allowlist_ip
  source_port_range          = "*"
  destination_port_range     = "4646"
  destination_address_prefix = "*"
}

resource "azurerm_network_security_rule" "consul_ui_ingress" {
  name                        = "${var.name}-consul-ui-ingress"
  resource_group_name         = "${azurerm_resource_group.hashistack.name}"
  network_security_group_name = "${azurerm_network_security_group.hashistack-sg.name}"

  priority  = 102
  direction = "Inbound"
  access    = "Allow"
  protocol  = "Tcp"

  source_address_prefix      = var.allowlist_ip
  source_port_range          = "*"
  destination_port_range     = "8500"
  destination_address_prefix = "*"
}

resource "azurerm_network_security_rule" "ssh_ingress" {
  name                        = "${var.name}-ssh-ingress"
  resource_group_name         = "${azurerm_resource_group.hashistack.name}"
  network_security_group_name = "${azurerm_network_security_group.hashistack-sg.name}"

  priority  = 100
  direction = "Inbound"
  access    = "Allow"
  protocol  = "Tcp"

  source_address_prefix      = var.allowlist_ip
  source_port_range          = "*"
  destination_port_range     = "22"
  destination_address_prefix = "*"
}

resource "azurerm_network_security_rule" "allow_all_internal" {
  name                        = "${var.name}-allow-all-internal"
  resource_group_name         = "${azurerm_resource_group.hashistack.name}"
  network_security_group_name = "${azurerm_network_security_group.hashistack-sg.name}"

  priority  = 103
  direction = "Inbound"
  access    = "Allow"
  protocol  = "Tcp"

  source_address_prefix      = azurerm_subnet.hashistack-sn.address_prefixes[0]
  source_port_range          = "*"
  destination_port_range     = "*"
  destination_address_prefix = azurerm_subnet.hashistack-sn.address_prefixes[0]
}

resource "azurerm_network_security_rule" "clients_ingress" {
  name                        = "${var.name}-clients-ingress"
  resource_group_name         = "${azurerm_resource_group.hashistack.name}"
  network_security_group_name = "${azurerm_network_security_group.hashistack-sg.name}"

  priority  = 110
  direction = "Inbound"
  access    = "Allow"
  protocol  = "Tcp"

  # Add application ingress rules here
  # These rules are applied only to the client nodes

  # nginx example; replace with your application port
  source_address_prefix      = var.allowlist_ip
  source_port_range          = "*"
  destination_port_range     = "80"
  destination_address_prefixes = azurerm_linux_virtual_machine.client[*].public_ip_address
}

resource "azurerm_public_ip" "hashistack-server-public-ip" {
  count                        = "${var.server_count}"
  name                         = "hashistack-server-ip-${count.index}"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.hashistack.name}"
  allocation_method            = "Static"
}

resource "azurerm_network_interface" "hashistack-server-ni" {
  count                     = "${var.server_count}"
  name                      = "hashistack-server-ni-${count.index}"
  location                  = "${var.location}"
  resource_group_name       = "${azurerm_resource_group.hashistack.name}"

  ip_configuration {
    name                          = "hashistack-ipc"
    subnet_id                     = "${azurerm_subnet.hashistack-sn.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${element(azurerm_public_ip.hashistack-server-public-ip.*.id, count.index)}"
  }

  tags                            = {"ConsulAutoJoin" = "auto-join"}
}

resource "azurerm_linux_virtual_machine" "server" {
  name                  = "hashistack-server-${count.index}"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.hashistack.name}"
  network_interface_ids = ["${element(azurerm_network_interface.hashistack-server-ni.*.id, count.index)}"]
  size                  = "${var.server_instance_type}"
  count                 = "${var.server_count}"

  boot_diagnostics {
    storage_account_uri = "https://${var.storage_account}.blob.core.windows.net/"
  }

  source_image_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Compute/images/${var.image_name}"

  os_disk {
    name              = "hashistack-server-osdisk-${count.index}"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  computer_name  = "hashistack-server-${count.index}"
  admin_username = "ubuntu"
  admin_password = var.admin_password
  custom_data    = "${base64encode(templatefile("${path.module}/../shared/data-scripts/user-data-server.sh", {
      region                    = var.location
      cloud_env                 = "azure"
      server_count              = "${var.server_count}"
      retry_join                = var.retry_join
      nomad_binary              = var.nomad_binary
      nomad_consul_token_id     = var.nomad_consul_token_id
      nomad_consul_token_secret = var.nomad_consul_token_secret
  }))}"

  disable_password_authentication = false
}

resource "azurerm_public_ip" "hashistack-client-public-ip" {
  count                        = "${var.client_count}"
  name                         = "hashistack-client-ip-${count.index}"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.hashistack.name}"
  allocation_method             = "Static"
}

resource "azurerm_network_interface" "hashistack-client-ni" {
  count                     = "${var.client_count}"
  name                      = "hashistack-client-ni-${count.index}"
  location                  = "${var.location}"
  resource_group_name       = "${azurerm_resource_group.hashistack.name}"

  ip_configuration {
    name                          = "hashistack-ipc"
    subnet_id                     = "${azurerm_subnet.hashistack-sn.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${element(azurerm_public_ip.hashistack-client-public-ip.*.id, count.index)}"
  }

  tags                            = {"ConsulAutoJoin" = "auto-join"}
}

resource "azurerm_linux_virtual_machine" "client" {
  name                  = "hashistack-client-${count.index}"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.hashistack.name}"
  network_interface_ids = ["${element(azurerm_network_interface.hashistack-client-ni.*.id, count.index)}"]
  size                  = "${var.client_instance_type}"
  count                 = "${var.client_count}"
  depends_on            = [azurerm_linux_virtual_machine.server]

  boot_diagnostics {
    storage_account_uri = "https://${var.storage_account}.blob.core.windows.net/"
  }

  source_image_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Compute/images/${var.image_name}"

  os_disk {
    name              = "hashistack-client-osdisk-${count.index}"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  computer_name  = "hashistack-client-${count.index}"
  admin_username = "ubuntu"
  admin_password = var.admin_password
  custom_data    = "${base64encode(templatefile("${path.module}/../shared/data-scripts/user-data-client.sh", {
      region                    = var.location
      cloud_env                 = "azure"
      retry_join                = var.retry_join
      nomad_binary              = var.nomad_binary
      nomad_consul_token_secret = var.nomad_consul_token_secret
  }))}"
  
  disable_password_authentication = false
}
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output "lb_address_consul_nomad" {
  value = "http://${azurerm_linux_virtual_machine.server[0].public_ip_address}"
}

output "consul_bootstrap_token_secret" {
  value = var.nomad_consul_token_secret
}

output "IP_Addresses" {
  value = <<CONFIGURATION

Client public IPs: ${join(", ", azurerm_linux_virtual_machine.client[*].public_ip_address)}

Server public IPs: ${join(", ", azurerm_linux_virtual_machine.server[*].public_ip_address)}

The Consul UI can be accessed at http://${azurerm_linux_virtual_machine.server[0].public_ip_address}:8500/ui
with the bootstrap token: ${var.nomad_consul_token_secret}
CONFIGURATION
}

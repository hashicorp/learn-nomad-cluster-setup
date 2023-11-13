# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output "lb_address_consul_nomad" {
  value = "http://${aws_instance.server[0].public_ip}"
}

output "consul_bootstrap_token_secret" {
  value = var.nomad_consul_token_secret
}

output "IP_Addresses" {
  value = <<CONFIGURATION

Client public IPs: ${join(", ", aws_instance.client[*].public_ip)}

Server public IPs: ${join(", ", aws_instance.server[*].public_ip)}

The Consul UI can be accessed at http://${aws_instance.server[0].public_ip}:8500/ui
with the bootstrap token: ${var.nomad_consul_token_secret}
CONFIGURATION
}

output "nomad_vpc_id" {
  value = data.aws_vpc.default.id
}
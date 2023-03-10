output "lb_address_consul_nomad" {
  value = "http://${scaleway_instance_ip.server[0].address}"
}

output "consul_bootstrap_token_secret" {
  value = var.nomad_consul_token_secret
}

output "IP_Addresses" {
  value = <<CONFIGURATION

Client public IPs: ${join(", ", scaleway_instance_ip.client[*].address)}

Server public IPs: ${join(", ", scaleway_instance_ip.server[*].address)}

The Consul UI can be accessed at http://${scaleway_instance_ip.server[0].address}:8500/ui
with the bootstrap token: ${var.nomad_consul_token_secret}
CONFIGURATION
}

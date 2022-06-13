data_dir  = "/opt/nomad/data"
bind_addr = "0.0.0.0"
datacenter = "DATACENTER"

# Enable the client
client {
  enabled = true
  options {
    "driver.raw_exec.enable"    = "1"
    "docker.privileged.enabled" = "true"
  }
  meta {
    node-name = "SERVER_NAME"
    service-client = "SERVICE_CLIENT"
  }
}

acl {
  enabled = true
}

consul {
  address = "127.0.0.1:8500"
  token = "CONSUL_TOKEN"
}

vault {
  enabled = true
  address = "http://active.vault.service.consul:8200"
}
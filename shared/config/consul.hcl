data_dir = "/opt/consul/data"
bind_addr = "0.0.0.0"
client_addr = "0.0.0.0"
advertise_addr = "IP_ADDRESS"

bootstrap_expect = SERVER_COUNT

acl {
    enabled = true
    default_policy = "deny"
    down_policy = "extend-cache"
}

log_level = "INFO"

server = true
ui = true
retry_join = ["RETRY_JOIN"]

service {
    name = "consul"
}

connect {
  enabled = true
}

ports {
  grpc = 8502
}
agent {
    policy = "write"
}

quota {
  policy = "write"
}

host_volume "*" {
  policy = "write"
}

node_pool "*" {
  policy       = "write"
  #capabilities = ["write"]
}

plugin {
  policy = "write"
}

node {
    policy = "write"
}

operator {
  policy = "write"
}


namespace "*" {
    policy = "write"
    #capabilities = ["submit-job", "read-logs", "read-fs"]
}

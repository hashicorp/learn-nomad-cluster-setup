terraform {
  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = ">= 2.13.0"
    }
  }
  required_version = ">= 0.13"
}

provider "scaleway" {
  zone       = var.zone
  project_id = var.project_id
}

resource "scaleway_iam_application" "auto_discovery" {
  name        = "${var.name}-application-auto-discovery"
  description = "Nomad application"
}

data "scaleway_account_project" "selected" {
  project_id = var.project_id
  name       = var.project_id != null ? null : "default"
}

resource "scaleway_iam_policy" "auto_discovery" {
  name           = "${var.name}-policy-auto-discovery"
  description    = "Auto discovery policy for Nomad"
  application_id = scaleway_iam_application.auto_discovery.id

  rule {
    project_ids          = [data.scaleway_account_project.selected.id]
    permission_set_names = ["InstancesReadOnly"]
  }
}

resource "scaleway_iam_api_key" "auto_discovery" {
  application_id = scaleway_iam_application.auto_discovery.id
  description    = "Auto discovery key for Nomad"
}

locals {
  retry_join_full = "${var.retry_join} token=${scaleway_iam_api_key.auto_discovery.secret_key}"
}

/**
 * Nomad Servers
 */
data "scaleway_instance_image" "server" {
  name = var.instance_image
}


data "cloudinit_config" "server" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "user-data-server.sh"
    content_type = "text/x-shellscript"

    content = templatefile("../shared/data-scripts/user-data-server.sh", {
      server_count              = var.server_count
      zone                      = var.zone
      cloud_env                 = "scaleway"
      retry_join                = local.retry_join_full
      nomad_binary              = var.nomad_binary
      nomad_consul_token_id     = var.nomad_consul_token_id
      nomad_consul_token_secret = var.nomad_consul_token_secret
    })
  }
}

resource "scaleway_instance_ip" "server" {
  count = var.server_count
  tags  = ["nomad", "consul-auto-join", "nomad-server"]
}

resource "scaleway_instance_server" "server" {
  count = var.server_count

  name = "${var.name}-server-${count.index}"
  tags = ["nomad", "consul-auto-join", "nomad-server"]

  type  = var.server_instance_type
  image = data.scaleway_instance_image.server.id

  ip_id = scaleway_instance_ip.server[count.index].id

  security_group_id = scaleway_instance_security_group.servers_ingress.id

  root_volume {
    volume_type           = "b_ssd"
    size_in_gb            = var.server_root_block_device_size
    delete_on_termination = true
  }

  user_data = {
    "cloud-init" = data.cloudinit_config.server.rendered
  }
}

resource "scaleway_instance_security_group" "servers_ingress" {
  name = "${var.name}-servers-ingress"
  tags = ["nomad"]

  inbound_default_policy = "drop"
  external_rules         = true
}


data "cloudinit_config" "client" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "user-data-server.sh"
    content_type = "text/x-shellscript"

    content = templatefile("../shared/data-scripts/user-data-client.sh", {
      zone                      = var.zone
      cloud_env                 = "scaleway"
      retry_join                = local.retry_join_full
      nomad_binary              = var.nomad_binary
      nomad_consul_token_secret = var.nomad_consul_token_secret
    })
  }
}

resource "scaleway_instance_ip" "client" {
  count = var.client_count
  tags  = ["nomad", "consul-auto-join", "nomad-client"]
}

/**
 * Nomad Clients
 */
resource "scaleway_instance_server" "client" {
  depends_on = [
    scaleway_instance_server.server
  ]

  count = var.client_count

  name = "${var.name}-client-${count.index}"
  tags = ["nomad", "consul-auto-join", "nomad-client"]

  type  = var.client_instance_type
  image = data.scaleway_instance_image.server.id

  ip_id = scaleway_instance_ip.client[count.index].id

  security_group_id = scaleway_instance_security_group.clients_ingress.id

  root_volume {
    volume_type           = "b_ssd"
    size_in_gb            = 50
    delete_on_termination = true
  }

  user_data = {
    "cloud-init" = data.cloudinit_config.client.rendered
  }
}

resource "scaleway_instance_security_group" "clients_ingress" {
  name = "${var.name}-clients-ingress"
  tags = ["nomad"]

  inbound_default_policy = "drop"
  external_rules         = true
}

resource "scaleway_instance_security_group_rules" "servers_ingress" {
  security_group_id = scaleway_instance_security_group.servers_ingress.id

  inbound_rule {
    action   = "accept"
    port     = 4646
    protocol = "TCP"
    ip_range = var.allowlist_ip
  }

  inbound_rule {
    action   = "accept"
    port     = 8500
    protocol = "TCP"
    ip_range = var.allowlist_ip
  }

  inbound_rule {
    action   = "accept"
    port     = 22
    protocol = "TCP"
    ip_range = var.allowlist_ip
  }

  inbound_rule {
    action   = "accept"
    protocol = "ICMP"
    ip_range = var.allowlist_ip
  }

  dynamic "inbound_rule" {
    for_each = toset(scaleway_instance_server.server)

    content {
      action   = "accept"
      protocol = "TCP"
      ip_range = "${inbound_rule.value.public_ip}/32"
    }
  }

  dynamic "inbound_rule" {
    for_each = toset(scaleway_instance_server.server)

    content {
      action   = "accept"
      protocol = "TCP"
      ip_range = "${inbound_rule.value.private_ip}/32"
    }
  }

  dynamic "inbound_rule" {
    for_each = toset(scaleway_instance_server.client)

    content {
      action   = "accept"
      protocol = "TCP"
      ip_range = "${inbound_rule.value.public_ip}/32"
    }
  }

  dynamic "inbound_rule" {
    for_each = toset(scaleway_instance_server.client)

    content {
      action   = "accept"
      protocol = "TCP"
      ip_range = "${inbound_rule.value.private_ip}/32"
    }
  }
}

resource "scaleway_instance_security_group_rules" "clients_ingress" {
  security_group_id = scaleway_instance_security_group.clients_ingress.id

  // copy the inbound rules from the servers_ingress security group
  dynamic "inbound_rule" {
    for_each = scaleway_instance_security_group_rules.servers_ingress.inbound_rule
    content {
      action   = inbound_rule.value.action
      port     = inbound_rule.value.port == null ? 0 : inbound_rule.value.port
      protocol = inbound_rule.value.protocol
      ip_range = inbound_rule.value.ip_range
    }
  }

  # Add application ingress rules here
  # These rules are applied only to the client nodes

  inbound_rule {
    action   = "accept"
    port     = 80
    protocol = "TCP"
    ip_range = var.allowlist_ip
  }
}

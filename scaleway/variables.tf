variable "name" {
  description = "Prefix used to name various infrastructure components. Alphanumeric characters only."
  default     = "nomad"
}

variable "zone" {
  description = "The Scaleway zone to deploy to."
  default     = "fr-par-1"
}

variable "project_id" {
  description = "The Scaleway project ID to deploy to."
  default     = null
}

variable "allowlist_ip" {
  description = "IP to allow access for the security groups (set 0.0.0.0/0 for world)"
  default     = "0.0.0.0/0"
}

variable "instance_image" {
  description = "The compute image to use for the server and client machines. Output from the Packer build process."
}

variable "server_instance_type" {
  description = "The Scaleway instance type to use for servers."
  default     = "PLAY2-NANO"
}

variable "server_count" {
  description = "The number of servers to provision."
  default     = "3"
}

variable "server_root_block_device_size" {
  description = "The volume size of the server root block device."
  default     = 20
}

variable "client_instance_type" {
  description = "The Scaleway instance type to use for clients."
  default     = "PLAY2-NANO"
}

variable "client_count" {
  description = "The number of clients to provision."
  default     = "3"
}

variable "retry_join" {
  description = "Used by Consul to automatically form a cluster."
  default     = "provider=scaleway tag_name=consul-auto-join"
}

variable "nomad_binary" {
  description = "URL of a zip file containing a nomad executable to replace the Nomad binaries with. Example: https://releases.hashicorp.com/nomad/0.10.0/nomad_0.10.0_linux_amd64.zip"
  default     = ""
}

variable "nomad_consul_token_id" {
  description = "Accessor ID for the Consul ACL token used by Nomad servers and clients. Must be a UUID."
}

variable "nomad_consul_token_secret" {
  description = "Secret ID for the Consul ACL token used by Nomad servers and clients. Must be a UUID."
}

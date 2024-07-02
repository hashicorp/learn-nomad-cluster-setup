variable "name_prefix" {
  description = "Prefix used to name various infrastructure components. Alphanumeric characters only."
  default     = "nomad"
}

variable "location" {
  description = "The Azure region to deploy to."
}

variable "image_name" {
  description = "The Azure image to use for the server and client machines. Output from the Packer build process. This is the image NAME not the ID."
}

variable "resource_group_name" {
  description = "The Azure resource group name to use."
  default     = "hashistack"
}

variable "allowlist_ip" {
  description = "IP to allow access for the security groups (set 0.0.0.0/0 for world)"
  default     = "0.0.0.0/0"
}

variable "server_instance_type" {
  description = "The Azure VM instance type to use for servers."
  default     = "Standard_B1s"
}

variable "client_instance_type" {
  description = "The Azure VM type to use for clients."
  default     = "Standard_B1s"
}

variable "server_count" {
  description = "The number of servers to provision."
  default     = "3"
}

variable "client_count" {
  description = "The number of clients to provision."
  default     = "3"
}

variable "nomad_binary" {
  description = "URL of a zip file containing a nomad executable to replace the Nomad binaries in the AMI with. Example: https://releases.hashicorp.com/nomad/0.10.0/nomad_0.10.0_linux_amd64.zip"
  default     = ""
}
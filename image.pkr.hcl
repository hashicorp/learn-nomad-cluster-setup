
data "amazon-ami" "hashistack" {
  filters = {
    architecture                       = "x86_64"
    "block-device-mapping.volume-type" = "gp2"
    name                               = "ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"
    root-device-type                   = "ebs"
    virtualization-type                = "hvm"
  }
  most_recent = true
  owners      = ["099720109477"]
  region      = "us-east-1"
}

locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

source "amazon-ebs" "hashistack" {
  ami_name      = "hashistack ${local.timestamp}"
  instance_type = "t2.medium"
  region        = "us-east-1"
  source_ami    = "${data.amazon-ami.hashistack.id}"
  ssh_username  = "ubuntu"
  force_deregister = true
  force_delete_snapshot = true
  
  tags = {
    Name        = "nomad-alb"
    source = "hashicorp/learn"
    purpose = "demo"
    OS_Version = "Ubuntu"
    Release = "Latest"
    Base_AMI_ID = "{{ .SourceAMI }}"
    Base_AMI_Name = "{{ .SourceAMIName }}"
  }
  
  snapshot_tags = {
    Name        = "nomad-alb"
    source = "hashicorp/learn"
    purpose = "demo"
  }
}

build {
  sources = ["source.amazon-ebs.hashistack"]

  provisioner "shell" {
    inline = ["sudo mkdir /ops", "sudo chmod 777 /ops"]
  }

  provisioner "file" {
    destination = "/ops"
    source      = "shared"
  }

  provisioner "shell" {
    environment_vars = ["INSTALL_NVIDIA_DOCKER=false"]
    script           = "shared/scripts/setup.sh"
  }

}

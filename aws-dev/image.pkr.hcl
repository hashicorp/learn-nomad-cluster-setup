packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1.3.1"
    }
  }
}

locals { 
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

variable "region" {
  type = string
}

data "amazon-ami" "hashistack" {
  filters = {
    architecture                       = "x86_64"
    "block-device-mapping.volume-type" = "gp2"
    name                               = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
    root-device-type                   = "ebs"
    virtualization-type                = "hvm"
  }
  most_recent = true
  owners      = ["099720109477"]
  region      = var.region
}


source "amazon-ebs" "hashistack" {
  ami_name      = "hashistack-${local.timestamp}"
  instance_type = "t2.medium"
  region        = var.region
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
    inline = ["sudo mkdir -p /ops/shared", "sudo chmod 777 -R /ops"]
  }

  provisioner "file" {
    destination = "/ops"
    source      = "../shared"
  }

  provisioner "shell" {
    environment_vars = ["INSTALL_NVIDIA_DOCKER=false", "CLOUD_ENV=aws"]
    script           = "../shared/scripts/setup.sh"
  }

}

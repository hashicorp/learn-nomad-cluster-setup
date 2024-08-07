# Packer variables (all are required)
region                    = "us-west-1"
name                    = "dev_nomad"
server_instance_type    = "t2.micro"

# Terraform variables (all are required)
ami                       = "ami-08464e87961890830"

# These variables will default to the values shown
# and do not need to be updated unless you want to
# change them
# allowlist_ip            = "0.0.0.0/0"
# name                    = "nomad"
# server_instance_type    = "t2.micro"
server_count            = "1"
client_instance_type    = "t3.2xlarge"
client_count            = "1"

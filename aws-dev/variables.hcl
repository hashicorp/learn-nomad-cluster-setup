# Packer variables (all are required)
region                    = "us-west-2"

# Terraform variables (all are required)
ami                       = "ami-05402c53e41ad8944"

# These variables will default to the values shown
# and do not need to be updated unless you want to
# change them
# allowlist_ip            = "0.0.0.0/0"
name                    = "dev-nomad"
server_instance_type    = "t2.micro"
server_count            = "1"
client_instance_type    = "t3.2xlarge"
client_count            = "1"

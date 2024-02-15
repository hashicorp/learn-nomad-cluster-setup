#!/bin/bash

set -e

# Disable interactive apt prompts
export DEBIAN_FRONTEND=noninteractive

cd /ops

CONFIGDIR=/ops/shared/config

CONSULVERSION=1.17.1
VAULTVERSION=1.15.4
NOMADVERSION=1.7.2
CONSULTEMPLATEVERSION=0.36.0

CONSULTEMPLATECONFIGDIR=/etc/consul-template.d
CONSULTEMPLATEDIR=/opt/consul-template

# Dependencies
case $CLOUD_ENV in
  aws)
    sudo apt-get install -y software-properties-common
    ;;

  gce)
    sudo apt-get update && sudo apt-get install -y software-properties-common
    ;;

  azure)
    sudo apt-get install -y software-properties-common
    ;;

  *)
    exit "CLOUD_ENV not set to one of aws, gce, or azure - exiting."
    ;;
esac

sudo add-apt-repository universe && sudo apt-get update
sudo apt-get install -y unzip tree redis-tools jq curl tmux
sudo apt-get clean


# Disable the firewall

sudo ufw disable || echo "ufw not installed"

# Consul Template 

## Configure
sudo mkdir -p $CONSULTEMPLATECONFIGDIR
sudo chmod 755 $CONSULTEMPLATECONFIGDIR
sudo mkdir -p $CONSULTEMPLATEDIR
sudo chmod 755 $CONSULTEMPLATEDIR


# Docker
distro=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
sudo apt-get install -y apt-transport-https ca-certificates gnupg2 
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/${distro} $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker-ce

# Java
sudo add-apt-repository -y ppa:openjdk-r/ppa
sudo apt-get update 
sudo apt-get install -y openjdk-8-jdk
JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::")


# Install HashiCorp Apt Repository
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Install HashiStack Packages
sudo apt-get update && sudo apt-get -y install \
	consul=$CONSULVERSION* \
	nomad=$NOMADVERSION* \
	vault=$VAULTVERSION* \
	consul-template=$CONSULTEMPLATEVERSION*

#!/usr/bin/env bash

set -e
apt-get -y update
apt-get -y upgrade

snap install --stable lxd 

# initializing lxd system
cat configs/lxd_preseed | sudo lxd init --preseed

# Create the containers
source create_containers.sh

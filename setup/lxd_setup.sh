#!/usr/bin/env bash

set -e
apt-get -y update
apt-get -y upgrade

snap install --stable lxd 

# initializing lxd system
cat configs/lxd_preseed | sudo lxd init --preseed

# kernel tweaks
cat configs/sysctl >> /etc/sysctl.conf

sudo ufw allow in on lxdbr0
sudo ufw allow out on lxdbr0

# Create the containers
source create_containers.sh

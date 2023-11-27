#!/usr/bin/env bash

set -e
apt-get -y update
apt-get -y upgrade

# remove lxd intalled with apt, usually lxd 3.0.3
sudo apt -y remove --purge lxd
sudo apt -y autoremove 

# install lxd with snap
# snap install lxd --channel=4.0/stable
snap install lxd 

# initializing lxd system
cat configs/lxd_preseed | sudo lxd init --preseed

# kernel tweaks
cat configs/sysctl >> /etc/sysctl.conf

sudo ufw route allow in on lxdbr0
sudo ufw route allow out on lxdbr0

source install_scripts.sh

# Create the containers
source create_containers.sh

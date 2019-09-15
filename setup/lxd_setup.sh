#!/usr/bin/env bash

set -e
apt-get -y update
apt-get -y upgrade

apt-get -y purge lxd
apt-get -y install lxd unzip

apt-get -y install auditd jq 

# initializing lxd system
cat configs/lxd_preseed | sudo lxd init --preseed

source create_containers.sh

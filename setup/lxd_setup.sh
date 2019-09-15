#!/usr/bin/env bash

set -e
apt-get -y update
apt-get -y upgrade

apt-get -y purge lxd
apt-get -y install lxd unzip

apt-get -y install auditd jq 

ufw allow 80/tcp
ufw allow 443/tcp

# initializing lxd system
cat configs/lxd_preseed | sudo lxd init --preseed

# Parse json config file
source parse_config.sh

# Setup encrypted disk if specified
if [[ ! -z $ENCDEV ]] ; then
  source ./disk_setup
fi

echo $CONTAINERS

# Create and configure conatiners
for CONTAINER in $CONTAINERS; do
  NAME=$(echo $CONTAINER | jq -r .name)
  IP=$(echo $CONTAINER | jq -r .ip)
  TYPE=$(echo $CONTAINER | jq -r .type)
  echo "Creating $NAME of type $TYPE"
  lxc init ubuntu: $NAME
  lxc network attach lxdbr0 $NAME eth0 eth0
  lxc config device set $NAME eth0 ipv4.address $IP
  if [[  $TYPE =~ .*_proxy ]]; then 
    lxc config device add $NAME myport443 proxy listen=tcp:0.0.0.0:443 connect=tcp:$IP:443
    lxc config device add $NAME myport80 proxy listen=tcp:0.0.0.0:80 connect=tcp:$IP:80
  fi
  for VAR in $ENVVARS; do
    KEY=$(echo $VAR | jq -r .key)
    VALUE=$(echo $VAR | jq -r .value)
    lxc config set $name environment.$KEY $VALUE
  done
  lxc start $NAME
  # wait for network to come up
  ping -c 4 $IP
  # run setup scripts
  
  echo "Running setup from containers/$TYPE"
  cat containers/$TYPE | lxc exec $NAME -- bash
  
  # source any post setup scripts
  if [[ -f containers/${TYPE}_postsetup ]]; 
  then
    source containers/${TYPE}_postsetup
  fi

done

sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
# sudo ufw limit 22/tcp
yes | sudo ufw enable

# TODO - encrypted volume stuff


#!/usr/bin/env bash

# Parse json config file
source parse_config.sh

# Setup encrypted disk if specified
if [[ ! -z $ENCDEV ]] ; then
  source ./disk_setup
fi

echo $CONTAINERS

# Create and configure containers
for CONTAINER in $CONTAINERS; do
  NAME=$(echo $CONTAINER | jq -r .name)
  IP=$(echo $CONTAINER | jq -r .ip)
  TYPE=$(echo $CONTAINER | jq -r .type)

  echo "Creating $NAME of type $TYPE"
  lxc init ubuntu: $NAME
  lxc network attach lxdbr0 $NAME eth0 eth0
  lxc config device set $NAME eth0 ipv4.address $IP

  # create nat rules for proxy
  if [[  $TYPE =~ .*_proxy ]] && sudo grep -v -q "^\*nat" /etc/ufw/before.rules; then 
    tmp=$(mktemp)
    INTERFACE=$(ifconfig |grep  -o '^[a-z].*:' |head -1 |sed 's/.$//')
    sudo cat configs/ufw_proxy /etc/ufw/before.rules > $tmp
    sed -i "s/PROXY_IP/${IP}/g" $tmp
    # FIX THIS
    #sed -i "s/LXD_NETWORK/${NETWORK}/g" $tmp
    sed -i "s/LXD_NETWORK/192.168.0.0\/24/g" $tmp
    sed -i "s/INTERFACE/$INTERFACE/" $tmp

    sudo mv $tmp /etc/ufw/before.rules
    sudo chown root.root /etc/ufw/before.rules
    sudo ufw reload
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

# TODO - encrypted volume stuff


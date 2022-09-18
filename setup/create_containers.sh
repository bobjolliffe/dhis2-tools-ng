#!/usr/bin/env bash

LXDBR=lxdbr0

# ubuntu version for containers
GUESTOS="20.04"

# some introspection
DEFAULT_INTERFACE=$(ip route |grep default | awk '{print $5}')
LXDBRADDR=$(lxc network get lxdbr0 ipv4.address)

UFW_STATUS=$(sudo ufw status |grep Status|cut -d ' ' -f 2)
if [[ $UFW_STATUS == "inactive" ]]; then
	echo
	echo "======= ERROR =========================================="
	echo "ufw firewall needs to be enabled in order to perform the installation."
	echo "It is required to NAT connections to the proxy container."
	echo "You just need to have a rule to allow ssh access. eg:"
	echo "   sudo ufw limit 22/tcp"
	echo "then, 'sudo ufw enable'"
	echo "Then you can try to run ./create_containers again"
	exit 1
fi

# Make sure ufw is not blocking the lxd traffic
sudo ufw allow in on lxdbr0
sudo ufw allow out on lxdbr0

sudo apt-get -y install unzip auditd jq apache2-utils

# Parse json config file
source parse_config.sh

# set any environment variables for default profile in all containers
# example TZ (timezone)
for VAR in $ENVVARS; do
  KEY=$(echo $VAR | jq -r .key)
  VALUE=$(echo $VAR | jq -r .value)
  lxc profile set default environment.$KEY $VALUE
done

# Create and configure containers
for CONTAINER in $CONTAINERS; do
  NAME=$(echo $CONTAINER | jq -r .name)
  IP=$(echo $CONTAINER | jq -r .ip)
  TYPE=$(echo $CONTAINER | jq -r .type)

  container_exist=$(lxc list -c n | grep -w $NAME)
  if ! [ -z "$container_exist" ]; then
    echo "Container $NAME already exist, skipping"
    continue
  fi

  echo "Creating $NAME of type $TYPE"
  lxc init ubuntu:$GUESTOS $NAME
  lxc network attach $LXDBR $NAME eth0 eth0
  lxc config device set $NAME eth0 ipv4.address $IP

  # create nat rules for proxy
  if [[  $TYPE =~ .*_proxy ]] && [[ $(sudo grep '^\*nat' /etc/ufw/before.rules) != "*nat" ]]; then 
    tmp=$(mktemp)
    sudo cat configs/ufw_proxy /etc/ufw/before.rules > $tmp
    sed -i "s/PROXY_IP/${IP}/g" $tmp
    # FIX THIS
    #sed -i "s/LXD_NETWORK/${NETWORK}/g" $tmp
    sed -i "s/LXD_NETWORK/192.168.0.0\/24/g" $tmp
    sed -i "s/INTERFACE/$DEFAULT_INTERFACE/" $tmp

    sudo mv $tmp /etc/ufw/before.rules
    sudo chown root.root /etc/ufw/before.rules
    sudo ufw reload
  fi
  lxc start $NAME
  # wait for network to come up
  while true ; do
    lxc exec $NAME -- nslookup archive.ubuntu.com >/dev/null && break || echo waiting for network; sleep 1 ;
  done

  # run setup scripts
  echo "Running setup from containers/$TYPE"
  cat containers/$TYPE | lxc exec $NAME -- bash

  if [[ $MONITORING == munin ]] && [[ $TYPE != munin_monitor ]]; then
	lxc exec $NAME -- apt-get install -y munin-node
        lxc exec $NAME -- sed -i -e "\$acidr_allow $MUNIN_IP/32\n" /etc/munin/munin-node.conf
	lxc exec $NAME -- ufw allow proto tcp from $MUNIN_IP to any port 4949
	lxc exec $NAME -- service munin-node restart
  fi

  if [[ $TYPE == journal_logger ]]; then
    LOGS_DIR=$(echo $CONTAINER | jq -r .directory)
    LOGS_BACKEND=$(echo $CONTAINER | jq -r .storage)
  fi

  # source any post setup scripts
  if [[ -f containers/${TYPE}_postsetup ]]; 
  then
    source containers/${TYPE}_postsetup
  fi

done

# If munin then tell the monitor about all the agents
if [[ $MONITORING == munin ]]; then
  for CONTAINER in $CONTAINERS; do
    NAME=$(echo $CONTAINER | jq -r .name)
    IP=$(echo $CONTAINER | jq -r .ip)
    TYPE=$(echo $CONTAINER | jq -r .type)

    if [[ $TYPE != munin_monitor ]]; then
      monitored=$(lxc exec monitor -- grep "$NAME" /etc/munin/munin.conf)
      if  [ -z "$monitored" ]; then
        echo "adding $NAME to monitor"
        lxc exec monitor -- sed -i -e "\$a[$NAME.lxd]\n  address $IP\n  use_node_name yes\n" /etc/munin/munin.conf
      fi
    fi
  done
  # Also monitor the host
  sudo apt-get install munin-node -y
  if ! [ "$(grep "$MUNIN_IP" /etc/munin/munin-node.conf)" ]; then
    sudo echo "cidr_allow $MUNIN_IP/32" >> /etc/munin/munin-node.conf
    sudo ufw allow proto tcp from $MUNIN_IP to any port 4949
  fi
  sudo service munin-node restart

  lxc exec monitor -- /etc/init.d/munin restart
  lxc exec monitor -- service apache2 reload
fi



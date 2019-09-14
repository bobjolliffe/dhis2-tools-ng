#!/bin/bash

# This will make whatever server it is run on a complete listening munin host
MUNINCONF='/etc/munin/munin-node.conf'
MONITOR=$(cat containers.json |jq -r '.containers[] | select(.name | contains("monitor"))' )

if [ -z "$MONITOR" ]
then
  echo "No monitor configured in containers.json"
  exit 1
fi

MONITOR_IP=$(echo $MONITOR | jq -r .ip)

if [[ ! -f "$MUNINCONF.orig" ]]; then
   # likely a 1st time run
   sudo DEBIAN_FRONTEND=noninteractive apt-get -y update
   sudo DEBIAN_FRONTEND=noninteractive apt-get -y install munin-plugins-core munin-plugins-extra munin-node
   sudo DEBIAN_FRONTEND=noninteractive apt-get -y autoremove
   # save a copy of the original distro conf file
   cp -f $MUNINCONF "$MUNINCONF.orig"
else
	# reset and try again
   cp -f "$MUNINCONF.orig" $MUNINCONF
fi

cat >> $MUNINCONF <<EOF
# Open Access to monitor
cidr_allow $MONITOR/32
EOF

#/usr/sbin/munin-node-configure --suggest
/usr/sbin/munin-node-configure --shell | sh
/etc/init.d/munin-node restart

sudo ufw allow proto tcp from $MONITOR to any port 4949
sudo systemctl enable munin-node
sudo systemctl restart munin-node
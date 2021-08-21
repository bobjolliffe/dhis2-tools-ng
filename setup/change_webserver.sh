#!/usr/bin/env bash

LXDBR=lxdbr0

# ubuntu version for containers
GUESTOS="20.04"

# some introspection
DEFAULT_INTERFACE=$(ip route |grep default | awk '{print $5}')

PROXY_CONFIG=$(cat /usr/local/etc/dhis/containers.json| jq -r .proxy)

PROXY_CHECK=$(lxc exec proxy -- service $PROXY_CONFIG status | grep enabled | wc -l)

if [[ $PROXY_CHECK != "1" ]];
then
	echo "Proxy and container.json config file don't match. Review your configuration"
	exit 1
fi

if [[ $PROXY_CONFIG == "nginx" ]];
then
  echo "Changing Proxy nginx to apache2"
  sed -i "s/nginx_proxy/apache_proxy/" /usr/local/etc/dhis/containers.json
  sed -i "s/nginx/apache2/" /usr/local/etc/dhis/containers.json
  sed -i "s/nginx_proxy/apache_proxy/" configs/containers.json
  sed -i "s/nginx/apache2/" configs/containers.json
else
  echo "Changing Proxy apache2 to nginx"
  sed -i "s/apache_proxy/nginx_proxy/" /usr/local/etc/dhis/containers.json
  sed -i "s/apache2/nginx/" /usr/local/etc/dhis/containers.json
  sed -i "s/apache_proxy/nginx_proxy/" configs/containers.json
  sed -i "s/apache2/nginx/" configs/containers.json
fi

# Parse json config file
source parse_config.sh

lxc stop proxy
lxc config device set proxy eth0 ipv4.address 192.168.0.3
lxc rename proxy proxyold
lxc start proxyold

# Create new proxy container
NAME="proxy"
TYPE=$(cat /usr/local/etc/dhis/containers.json | jq -r '.containers[] | select(.name=="proxy") | .type')

echo "Creating $NAME of type $TYPE"
lxc init ubuntu:$GUESTOS $NAME
lxc network attach $LXDBR $NAME eth0 eth0
lxc config device set $NAME eth0 ipv4.address $PROXY_IP

# create nat rules for proxy
if [[  $TYPE =~ .*_proxy ]] && [[ $(sudo grep '^\*nat' /etc/ufw/before.rules) != "*nat" ]]; then
tmp=$(mktemp)
sudo cat configs/ufw_proxy /etc/ufw/before.rules > $tmp
sed -i "s/PROXY_IP/${PROXY_IP}/g" $tmp
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

# source proxy post setup scripts
if [[ -f containers/${TYPE}_postsetup ]];
then
source containers/${TYPE}_postsetup
fi

# configure munin
source containers/munin_monitor_postsetup

TYPE=$(cat /usr/local/etc/dhis/containers.json | jq -r '.containers[] | select(.name=="proxy") | .type')
# Change webserver nginx to apache2
if [[ $TYPE == "apache_proxy" ]];
then
  for INSTANCE_FILENAME in $(lxc exec proxyold -- ls /etc/nginx/upstream);
  do
        INSTANCE_NAME=$(echo $INSTANCE_FILENAME | awk -F '.' '{print $1}');
        INSTANCE_SHORT_NAME=$(echo $INSTANCE_NAME | awk -F '-' '{print $1}');
        if [[ $INSTANCE_NAME =~ "glowroot" ]];
        then
			IP=$(lxc config device get $INSTANCE_SHORT_NAME eth0 ipv4.address);
            cat <<EOF > /tmp/${INSTANCE_SHORT_NAME}-glowroot
  <Location /${INSTANCE_SHORT_NAME}-glowroot>
    Require all granted
    ProxyPass "http://${IP}:4000/${INSTANCE_SHORT_NAME}-glowroot"
    ProxyPassReverse "http://${IP}:4000/${INSTANCE_SHORT_NAME}-glowroot"
  </Location>
EOF

            lxc file push /tmp/${INSTANCE_SHORT_NAME}-glowroot proxy/etc/apache2/upstream/${INSTANCE_SHORT_NAME}-glowroot
            rm /tmp/${INSTANCE_SHORT_NAME}-glowroot
        elif [[ $INSTANCE_SHORT_NAME != "munin" ]];
        then
			IP=$(lxc config device get $INSTANCE_SHORT_NAME eth0 ipv4.address);
            cat <<EOF > /tmp/${INSTANCE_SHORT_NAME}
  <Location /${INSTANCE_SHORT_NAME}>
    Require all granted
    ProxyPass "http://${IP}:8080/${INSTANCE_SHORT_NAME}"
    ProxyPassReverse "http://${IP}:8080/${INSTANCE_SHORT_NAME}"
  </Location>
EOF

            lxc file push /tmp/${INSTANCE_SHORT_NAME} proxy/etc/apache2/upstream/${INSTANCE_SHORT_NAME}
            rm /tmp/${INSTANCE_SHORT_NAME}
        fi
  done
  lxc exec proxy -- service apache2 restart
  
# Change webserver apache2 to nginx
elif [[ $TYPE == "nginx_proxy" ]];
then
  for INSTANCE_FILENAME in $(lxc exec proxyold -- ls /etc/apache2/upstream);
  do
        INSTANCE_NAME=$(echo $INSTANCE_FILENAME | awk -F '.' '{print $1}');
        INSTANCE_SHORT_NAME=$(echo $INSTANCE_NAME | awk -F '-' '{print $1}');
        if [[ $INSTANCE_NAME =~ "glowroot" ]];
        then
			IP=$(lxc config device get $INSTANCE_SHORT_NAME eth0 ipv4.address);
            cat <<EOF > /tmp/${INSTANCE_SHORT_NAME}-glowroot.conf
    # Proxy pass to servlet container

    location /${INSTANCE_SHORT_NAME}-glowroot {
      proxy_pass                http://${IP}:4000/${INSTANCE_SHORT_NAME}-glowroot;
      proxy_redirect            off;
      proxy_set_header Host \$host;
      proxy_set_header X-Real-IP \$remote_addr;
      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto  \$scheme;
          proxy_hide_header X-Frame-Options;
      proxy_hide_header Strict-Transport-Security;
      proxy_hide_header X-Content-Type-Options;
      proxy_hide_header X-XSS-protection;
          proxy_hide_header X-Powered-By;
          proxy_hide_header Server;

      proxy_connect_timeout  480s;
      proxy_read_timeout     480s;
      proxy_send_timeout     480s;

      proxy_buffer_size        128k;
      proxy_buffers            8 128k;
      proxy_busy_buffers_size  256k;
   }
EOF

            lxc file push /tmp/${INSTANCE_SHORT_NAME}-glowroot.conf proxy/etc/nginx/upstream/${INSTANCE_SHORT_NAME}-glowroot.conf
            rm /tmp/${INSTANCE_SHORT_NAME}-glowroot.conf
        elif [[ $INSTANCE_SHORT_NAME != "munin" ]];
        then
			IP=$(lxc config device get $INSTANCE_SHORT_NAME eth0 ipv4.address);
            cat <<EOF > /tmp/${INSTANCE_SHORT_NAME}.conf
    # Proxy pass to servlet container

    location /${INSTANCE_SHORT_NAME} {
      proxy_pass                http://${IP}:8080/${INSTANCE_SHORT_NAME};
      proxy_redirect            off;
      proxy_set_header Host \$host;
      proxy_set_header X-Real-IP \$remote_addr;
      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto  \$scheme;
          proxy_hide_header X-Frame-Options;
      proxy_hide_header Strict-Transport-Security;
      proxy_hide_header X-Content-Type-Options;
      proxy_hide_header X-XSS-protection;
          proxy_hide_header X-Powered-By;
          proxy_hide_header Server;

      proxy_connect_timeout  480s;
      proxy_read_timeout     480s;
      proxy_send_timeout     480s;

      proxy_buffer_size        128k;
      proxy_buffers            8 128k;
      proxy_busy_buffers_size  256k;
   }
EOF

            lxc file push /tmp/${INSTANCE_SHORT_NAME}.conf proxy/etc/nginx/upstream/${INSTANCE_SHORT_NAME}.conf
            rm /tmp/${INSTANCE_SHORT_NAME}.conf
        fi
  done
  lxc exec proxy -- service nginx restart
fi

lxc stop proxyold
lxc delete proxyold


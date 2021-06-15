#!/bin/env bash

# Parse json config file
source parse_config.sh

echo "IMPORTANT WARNING"
echo "================="
echo "You are about to attempt to setup a TLS certificate from"
echo "letsencrypt.org for $FQDN.  Please first check that you"
echo "can reach http://$FQDN from your browser.  If you cannot"
echo "reach it then there is some problem with your setup.  It could"
echo "be:"
echo "1. failure to resolve DNS"
echo "2. external or host based firewall issue"
echo "3. proxy service is not running"
echo "If you cannot access, then do not proceed.  Exit now and resolve"
echo "the issue before trying again.  If you make too many failed"
echo "requests to run this script you will be banned by letsencrypt."
echo
echo "Are you really sure you want to install ssl certificate now?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) exit;;
    esac
done

if [[ $PROXY == nginx ]]; then
	lxc exec proxy -- service nginx stop
	lxc exec proxy -- certbot certonly -d $FQDN --standalone -m $EMAIL --agree-tos -n --no-eff-email

	####
	# ssl-files.conf
	####
cat <<EOF > /tmp/ssl-files.conf
ssl_certificate /etc/letsencrypt/live/${FQDN}/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/${FQDN}/privkey.pem;
EOF

	lxc file push /tmp/ssl-files.conf proxy/etc/nginx/conf.d/ssl-files.conf
	rm /tmp/ssl-files.conf
	
	cat configs/nginx-dhis2.conf > /tmp/nginx.conf
	sed -i "s/listen 80;/listen 443 ssl http2;/g" /tmp/nginx.conf
	sed -i "/^  # Main server block.*/i  # Redirect http to https\n  server {\n    listen 80 ;\n    server_name FQDN;\n    return 301 https://\$host\$request_uri;\n  }\n" /tmp/nginx.conf
	sed -i "s/FQDN/${FQDN}/" /tmp/nginx.conf

	lxc file push /tmp/nginx.conf proxy/etc/nginx/nginx.conf
	rm /tmp/nginx.conf
	# setup auto renewal
	lxc exec proxy --  echo '0 3 * * * root certbot renew --standalone --pre-hook="service nginx stop" --post-hook="service nginx start"/' > /etc/cron.d/certbot

	lxc exec proxy -- service nginx start
elif [[ $PROXY == apache ]]; then
	lxc exec proxy -- service apache2 stop 
	lxc exec proxy -- certbot certonly --non-interactive --standalone --agree-tos -m $EMAIL -d $FQDN
	lxc exec proxy -- a2dissite 000-default
	lxc exec proxy -- a2ensite apache-dhis2
	lxc exec proxy -- service apache2 reload
	lxc exec proxy -- service apache2 start
	# setup auto renewal
	lxc exec proxy --  echo '0 3 * * * root certbot renew --standalone --pre-hook="service apache2 stop" --post-hook="service apache2 start"/' > /etc/cron.d/certbot

fi

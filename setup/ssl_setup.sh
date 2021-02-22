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

lxc exec proxy -- service apache2 stop 
lxc exec proxy -- certbot certonly --non-interactive --standalone --agree-tos -m $EMAIL -d $FQDN
lxc exec proxy -- a2dissite 000-default
lxc exec proxy -- a2ensite apache-dhis2
lxc exec proxy -- service apache2 reload
lxc exec proxy -- service apache2 start

#!/usr/bin/env bash

CREDENTIALS_FILE=/usr/local/etc/dhis/.credentials.json

echo "Are you really sure you want to delete all containers"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) exit;;
    esac
done

#Remove all credentials
jq 'del(.credentials[])' ${CREDENTIALS_FILE} > ${CREDENTIALS_FILE}.tmp && mv ${CREDENTIALS_FILE}.tmp ${CREDENTIALS_FILE}

for c in $( sudo lxc list --format csv -c n); do 
	echo "Deleting $c"
	lxc delete --force $c
done

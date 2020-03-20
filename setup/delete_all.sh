#!/usr/bin/env bash

echo "Are you really sure you want to delete all containers"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) exit;;
    esac
done

for c in $( sudo lxc list --format csv -c n); do 
	echo "Deleting $c"
	lxc delete --force $c
done

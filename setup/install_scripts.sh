#!/usr/bin/env bash

echo "Installing service scripts"
sudo cp service/* /usr/local/bin
sudo mkdir /usr/local/etc/dhis
sudo cp tomcat_setup /usr/local/etc/dhis
echo "Done"

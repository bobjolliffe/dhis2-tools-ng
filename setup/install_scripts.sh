#!/usr/bin/env bash

echo "Installing service scripts"
sudo cp service/* /usr/local/bin
sudo mkdir -p /usr/local/etc/dhis
sudo cp etc/* /usr/local/etc/dhis
echo "Done"

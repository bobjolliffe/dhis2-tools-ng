#!/usr/bin/env bash

# Echo starting up
sudo cryptsetup open /dev/sda3 cryptdata
sudo mount /dev/mapper/cryptdata /mnt/cryptdata
swapon /mnt/crypdata/swapfile

lxc start postgres
lxc start tracker

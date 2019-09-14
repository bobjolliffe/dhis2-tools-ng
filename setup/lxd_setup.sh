#!/usr/bin/env bashq

ENCDEVICE="/dev/sdc"
CONTAINERS="$(find containers/ -type f)"

if false; then

apt-get -y update
apt-get -y upgrade

apt-get -y purge lxd
apt-get -y install lxd unzip

apt-get -y install auditd jq 

# initializing lxd system
cat configs/lxd_preseed | sudo lxd init --preseed

fi

# setup encrypted disk
echo "Formatting encrypted disk"
cryptsetup luksFormat $ENCDEVICE 
echo "Opening disk"
cryptsetup open $ENCDEVICE cryptdata
sleep 2
mkfs.ext4 /dev/mapper/cryptdata
mkdir  /mnt/cryptdata

for c in $CONTAINERS; do
  name=$(basename $c)
  lxc init ubuntu: $name
  #  lxc config set $name environment.http_proxy "http://imohibidu:ezzyst24@10.249.61.21:80"
  #  lxc config set $name environment.https_proxy "http://imohibidu:ezzyst24@10.249.61.21:80"
  #  lxc config set $name environment.ftp_proxy "http://imohibidu:ezzyst24@10.249.61.21:80"
  #  lxc config set $name environment.no_proxy "localhost,127.0.0.1,::1" 
  # install script
done

ufw allow 80/tcp
ufw allow 443/tcp

# set ip addresses
sudo lxc network attach lxdbr0 nginx eth0 eth0
sudo lxc config device set nginx eth0 ipv4.address 192.168.0.2  
sudo lxc network attach lxdbr0 postgres eth0 eth0
sudo lxc config device set postgres eth0 ipv4.address 192.168.0.20
sudo lxc network attach lxdbr0 monitor eth0 eth0
sudo lxc config device set monitor eth0 ipv4.address 192.168.0.30

lxc config device add nginx myport443 proxy listen=tcp:0.0.0.0:443 connect=tcp:192.168.0.2:443
lxc config device add nginx myport80 proxy listen=tcp:0.0.0.0:80 connect=tcp:192.168.0.2:80

lxc config set postgres boot.autostart false

lxc config device add postgres cryptdata disk source=/mnt/cryptdata path=/data

for c in $CONTAINERS; do
  name=$(basename $c)
  echo "Starting $name ..."
  lxc start $name
  sleep 5
  cat $c | lxc exec $name -- bash
done

echo "Sleeping for 5 ..."
sleep 5

mount /dev/mapper/cryptdata /mnt/cryptdata
OWNERSHIP=$(stat -c "%u.%g" /var/lib/lxd/containers/postgres/rootfs/var/lib/postgresql/10)
mkdir /mnt/cryptdata/postgres
chown -R $OWNERSHIP /mnt/cryptdata/postgres

# Remove swap to unencrypted disk
sed -i '/\sswap\s/s/^/#/' /etc/fstab
swapoff /swap.img

# Create swap file on encrypted disk
fallocate -l 4G /mnt/cryptdata/swapfile
chmod 600 /mnt/cryptdata/swapfile
mkswap /mnt/cryptdata/swapfile
swapon /mnt/cryptdata/swapfile

lxc exec postgres -- service postgresql stop
sleep 1
lxc exec postgres -- rsync -av /var/lib/postgresql/10 /data/postgres
lxc exec postgres -- mv /var/lib/postgresql/10 /var/lib/postgresql/10.bak

lxc exec postgres -- sed -i "s/^data_directory.*$wq/data_directory=\'\/data\/postgres\/10\/main\'/" /etc/postgresql/10/main/postgresql.conf

lxc exec postgres -- sed -i "s/^#listen_addresses.*$/listen_addresses = '*'/" /etc/postgresql/10/main/postgresql.conf 

 
lxc exec postgres -- service postgresql start

# umount /mnt/cryptdata


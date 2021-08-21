#!/usr/bin/env bash

echo "Installing service scripts"
cp service/* /usr/local/bin

# Installing db backup template in cron
if [ -f /etc/cron.d/dhis ]; then
  echo "DHIS2 cron already exists"
else
  cat << EOF > /etc/cron.d/dhis
# CRON jobs for DHIS2
PATH=/snap/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Run backup script at 8:25pm (adjust and uncomment) 
# 25 20 * * *     root /usr/local/bin/dhis2-backup
EOF
fi

# copy some files
mkdir -p /usr/local/etc/dhis

# set restricted permissions on copied files
umask 137

for FILE in $(find etc/*); do
  BASE=$(basename $FILE)
	if [ -f /usr/local/etc/dhis/$BASE ]; then
     echo "$BASE already exists, not over-writing"
  else
     cp $FILE /usr/local/etc/dhis
  fi
done

# copy containers.json to /usr/local/etc/dhis/
if [ -f configs/containers.json ];
then
  cp configs/containers.json /usr/local/etc/dhis
else
  echo "configs/containers.json configuration file does not exist. Create a configuration file to continue."
  exit 1;
fi

chown root:lxd /usr/local/etc/dhis/*
 
echo "Done"

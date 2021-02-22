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

chown root:lxd /usr/local/etc/dhis/*
 
echo "Done"

#!/usr/bin/env bash
DHIS2_CONFIG_DIR="/usr/local/etc/dhis"

if [ "$UID" -ne 0 ]; then
  echo "You must be root to run this script. Please do so with sudo ./install_scripts.sh"
  exit 1
fi

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
mkdir -p "$DHIS2_CONFIG_DIR"

# set restricted permissions on copied files
umask 137

for FILE in $(find etc/*); do
  BASE=$(basename $FILE)
	if [ -f ${DHIS2_CONFIG_DIR}/$BASE ]; then
    echo "$BASE already exists, not over-writing"
  else
    echo "Copying $BASE"
    cp $FILE $DHIS2_CONFIG_DIR
  fi
done

# copy credentials file
if [ -f ${DHIS2_CONFIG_DIR}/.credentials.json ]; then
  echo "Credentials file already exists, not over-writing"
else
  cp etc/.credentials.json $DHIS2_CONFIG_DIR
fi

# copy glowroot-admin.json to /usr/local/etc/dhis/
if [ -f configs/glowroot-admin.json ];
then
  cp configs/glowroot-admin.json $DHIS2_CONFIG_DIR
else
  echo "configs/glowroot-admin.json file does not exist."
  exit 1
fi

# copy containers.json to /usr/local/etc/dhis/
if [ -f configs/containers.json ];
then
  if [ -f ${DHIS2_CONFIG_DIR}/containers.json ]; then
    echo "containers.json already exists, not over-writing"
  else
    cp configs/containers.json $DHIS2_CONFIG_DIR
  fi
else
  echo "configs/containers.json configuration file does not exist. Create a configuration file to continue."
  exit 1
fi

chown root:lxd ${DHIS2_CONFIG_DIR}/*
 
echo "Done"

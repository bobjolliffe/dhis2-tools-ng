# Parse the contents of containers.json into bash variables
CONFIG=$(cat configs/containers.json)

# Abort script on errors
#set -o errexit
# test for a valid json config
TESTCONFIG=$(echo $CONFIG |jq .) || { echo "Invalid containers.json"; exit 1; }

FQDN=$(echo $CONFIG | jq -r .fqdn)
EMAIL=$(echo $CONFIG | jq -r .email)
NETWORK=$(echo $CONFIG | jq -r .network)
MONITORING=$(echo $CONFIG | jq -r .monitoring)
APM=$(echo $CONFIG | jq -r .apm)
PROXY=$(echo $CONFIG| jq -r .proxy)
ENCDEVICE=$(echo $CONFIG | jq -r .encrypted_device)
ENVIRONMENT=$(cat configs/containers.json |jq ".environment")
if [[ ! $ENVIRONMENT == "null" ]]; then
  ENVVARS=$(echo $ENVIRONMENT | jq -c "to_entries[]")
fi

# get configs for individual containers
CONTAINERS=$(echo $CONFIG | jq -c .containers[])
NAMES=$(cat configs/containers.json | jq -r .containers[].name)
TYPES=$(cat configs/containers.json | jq -r .containers[].type)

case $MONITORING in
     munin)
          # echo "Using munin monitor"
          ;;
     *)
          echo "$MONITORING not supported yet"
          ;;
esac

for TYPE in $TYPES; do
  if [ ! -f "containers/$TYPE" ]; then 
	  echo "Profile for $TYPE doesn't exist .. aborting"
	  exit 1
  fi
done 

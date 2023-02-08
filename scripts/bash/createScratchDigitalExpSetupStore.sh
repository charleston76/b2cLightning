#!/bin/bash
# This script will:
# Create the scratch or and call the other configrations needed
function exit_error_message() {
  local red_color='\033[0;31m'
  local no_color='\033[0m'
  echo -e "${red_color}$1${no_color}"
  exit 0
}

function echo_attention() {
  local green='\033[0;32m'
  local no_color='\033[0m'
  echo -e "${green}$1${no_color}"
}

if [ -z "$1" ]
then
	exit_error_message "You need to specify the scratch org name to create it."
fi

if [ -z "$2" ]
then
	exit_error_message "You need to specify the the store name to create it."
fi

echo_attention "Starting the scratch org creation at $(date)"
echo ""
echo ""

scratchOrgName=$1
storename=$2

echo_attention "Creating the $scratchOrgName scratch org with one day of duration."
echo_attention "That can take few seconds to a couple minutes, please, be patient."
sfdx force:org:create -f config/project-scratch-def.json -a $scratchOrgName -d 30

echo_attention "Setting the $scratchOrgName as default"
sfdx force:config:set defaultusername=$scratchOrgName

echo ""
echo ""
echo_attention "Finishing the scratch org creation at $(date)"
echo ""
echo ""

./scripts/bash/createDigitalExpSetupStore.sh $scratchOrgName $storename
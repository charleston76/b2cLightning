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

if [ -z "$3" ]
then
	exit_error_message "You need to specify the template type (B2B or B2C) to create it."
fi

if [ -z "$4" ]
then
	exit_error_message "You need to specify if it is a Windows environment (Yes or No)."
fi


echo_attention "Starting the scratch org creation at $(date)"
echo ""
echo ""

scratchOrgDuration=30
scratchOrgName=$1
storename=$2
templateType=$3
windowsEnvironment=$4


if [[ "$templateType" != "B2B" && "$templateType" != "B2C" ]]
then
  exit_error_message "You need to specify the template type as B2B or B2C to create it."
fi

echo_attention "Creating the $scratchOrgName scratch org with $scratchOrgDuration days of duration."
echo_attention "That will be created following the $templateType template"
echo_attention "That can take few seconds to a couple minutes, please, be patient."
sf org create scratch -f config/project-scratch-def.json -a $scratchOrgName -y $scratchOrgDuration

echo_attention "Setting the $scratchOrgName as default"
sf config set target-org $scratchOrgName

echo ""
echo ""
echo_attention "Finishing the scratch org creation at $(date)"
echo ""
echo ""

./scripts/bash/2-createDigitalExpSetupStore.sh $scratchOrgName $storename $templateType $windowsEnvironment

# ./scripts/bash/2-createDigitalExpSetupStore.sh tmpB2c d2cStore B2C Yes
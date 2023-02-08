#!/bin/bash
# This script will:
# - amend files needed to fill out Product data
# - import Products and related data to make store functional
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
	exit_error_message "You need to specify the the store name to import it."
fi

storename=$1
echo_attention "Checking if the store $storename already exists"
storeId=`sfdx force:data:soql:query -q "SELECT Id FROM WebStore WHERE Name='$1' LIMIT 1" -r csv |tail -n +2`

if [ -z "$storeId" ]
then
    echo_attention "This store name $storename doesn't exist"
    exit_error_message "The setup will stop."
fi

echo_attention "Store front id: $storeId found to $storename"

echo_attention "Checking if community $storename already exists"
communityId=`sfdx force:data:soql:query -q "SELECT Id from Network WHERE Name='$1' LIMIT 1" -r csv |tail -n +2`

if [ -z "$communityId" ]
then
    echo_attention "This community name $storename doesn't exist"
    exit_error_message "The setup will stop."
fi

echo_attention "community id: $communityId found to $storename"

echo_attention "Creating a folder to copy the apex script file"
rm -rf setupB2b
mkdir setupB2b

# Replace the names of the components that will be retrieved.
sed -E "s/YOUR_COMMUNITY_NAME_HERE/$storename/g;s/YOUR_COMMUNITY_ID_HERE/$communityId/g;s/YOUR_WEBSTORE_ID_HERE/$storeId/g" scripts/apex/managedContentCreation.apex > setupB2b/managedContentCreation.apex

echo_attention "Executing the apex script file"
# sfdx force:apex:execute -f setupB2b/managedContentCreation.apex
returned=`sfdx force:apex:execute -f setupB2b/managedContentCreation.apex`

echo_attention "Removing the setupB2b folder"
rm -rf setupB2b


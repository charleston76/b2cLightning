#!/bin/sh

if [[ -z "$1" ]] || [[ -z "$2" ]]
then
	echo "You need to specify the name of the store and name of the buyer group."
	echo "Command should look like: ./enable-guest-browsing.sh <YourStoreName> <NameOfBuyerGroup>"
	exit 1
fi

function echo_attention() {
  local green='\033[0;32m'
  local no_color='\033[0m'
  echo -e "${green}$1${no_color}"
}


communityNetworkName=$1
# If the name of the store starts with a digit, the CustomSite name will have a prepended X.
communitySiteName="$(echo $1 | sed -E 's/(^[0-9])/X\1/g')"
# The ExperienceBundle name is similar to the CustomSite name, but has a 1 appended.
buyergroupName=$2

echo_attention "Creating guest user to $buyergroupName"

# Enable Guest Browsing for WebStore and create Guest Buyer Profile. 
# Assign to Buyer Group of choice.
sfdx force:data:record:update -s WebStore -w "Name='$communityNetworkName'" -v "OptionsGuestBrowsingEnabled='true'" 
guestBuyerProfileId=`sfdx force:data:soql:query --query \ "SELECT GuestBuyerProfileId FROM WebStore WHERE Name = '$communityNetworkName'" -r csv |tail -n +2`
echo_attention "Guest Buyer Profile Id $guestBuyerProfileId"

buyergroupID=`sfdx force:data:soql:query --query \ "SELECT Id FROM BuyerGroup WHERE Name = '$buyergroupName'" -r csv |tail -n +2`
echo_attention "Buyer Group ID $buyergroupID"

sfdx force:data:record:create -s BuyerGroupMember -v "BuyerId='$guestBuyerProfileId' BuyerGroupId='$buyergroupID'"

echo "Rebuilding the  search index."
sfdx 1commerce:search:start -n "$communityNetworkName"

echo "Publishing the community."
sfdx force:community:publish -n "$communityNetworkName"
sleep 10

echo
echo
echo "Done! Guest Buyer Access is setup!"
echo
echo
#!/bin/bash
# Use this command followed by a store name.
#
# Before running this script make sure that you completed all the previous steps in the setup
# (run convert-examples-to-sfdx.sh, execute sfdx force:source:push -f, create store)
#
# This script will:
# - register the Apex classes needed for checkout integrations and map them to your store
# - associate the clone of the checkout flow to the checkout component in your store
# - add the Customer Community Plus Profile clone to the list of members for the store
# - import Products and necessary related store data in order to get you started
# - create a Buyer User and attach a Buyer Profile to it
# - create a Buyer Account and add it to the relevant Buyer Group
# - add Contact Point Addresses for Shipping and Billing to your new buyer Account
# - activate the store
# - publish your store so that the changes are reflected

function createJsonFile() {
    fieldValues="{\"records\": [ {$1} ]}" 
    echo $fieldValues
    # Clear the previous data
    echo ""  > Data.json
    rm  Data.json
    # Save the new data
    echo "$fieldValues" > Data.json
}


function createNewQuery() {
    soqlQuery=$1
    echo "$soqlQuery"
    # Clear the previous data
    echo ""  > query.txt
    rm  query.txt
    # Save the new data
    echo $soqlQuery > query.txt
}

function removeTempFiles(){
    rm  query.txt
    rm  apexRun.apex
	rm  Data.json
}

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

echo_attention "Starting the d2cStore set up and  buyer user creation at $(date)"
echo ""
echo ""

rm -rf experience-bundle-package
mkdir experience-bundle-package
#############################
#    Retrieve Store Info    #
#############################

scratchOrgName=$1
storename=$2


communityNetworkName=$storename
# If the name of the store starts with a digit, the CustomSite name will have a prepended X.
communitySiteName="$(echo $storename | sed -E 's/(^[0-9])/X\1/g')"
# The ExperienceBundle name is similar to the CustomSite name, but has a 1 appended.
communityExperienceBundleName="$communitySiteName"1

# Replace the names of the components that will be retrieved.
##sed -E "s/YourCommunitySiteNameHere/$communitySiteName/g;s/YourCommunityExperienceBundleNameHere/$communityExperienceBundleName/g;s/YourCommunityNetworkNameHere/$communityNetworkName/g" quickstart-config/package-retrieve-template.xml > package-retrieve.xml
sed -E "s/YourCommunitySiteNameHere/$communitySiteName/g;s/YourCommunityExperienceBundleNameHere/$communityExperienceBundleName/g;s/YourCommunityNetworkNameHere/$communityNetworkName/g" manifest/package-retrieve-template.xml > package-retrieve.xml

echo "Using this to retrieve your store info:"
cat package-retrieve.xml

echo "Retrieving the store metadata and extracting it from the zip file."
# project retrieve start
sfdx force:mdapi:retrieve -r experience-bundle-package -k  package-retrieve.xml
unzip -d experience-bundle-package experience-bundle-package/unpackaged.zip


#############################
#       Update Store        #
#############################

# storeId=`sf data query -q "SELECT Id FROM WebStore WHERE Name='$storename' LIMIT 1" -r csv |tail -n +2`
createNewQuery "SELECT Id FROM WebStore WHERE Name='$storename' LIMIT 1"
storeId=`sf data query --file query.txt -r csv |tail -n +2`

# Register Apex classes needed for checkout integrations and map them to the store
echo "1. Setting up your integrations."

# For each Apex class needed for integrations, register it and map to the store
function register_and_map_integration() {
	# $1 is Apex class name
	# $2 is DeveloperName
	# $3 is ExternalServiceProviderType

	echo "Registering Apex class $1 ($2) for $3 integration."

	# Get the Id of the Apex class
	# local apexClassId=`sf data query -q "SELECT Id FROM ApexClass WHERE Name='$1' LIMIT 1" -r csv |tail -n +2`
	createNewQuery "SELECT Id FROM ApexClass WHERE Name='$1' LIMIT 1"
	local apexClassId=`sf data query --file query.txt -r csv |tail -n +2`

	if [ -z "$apexClassId" ]
	then
		echo "There was a problem getting the ID of the Apex class $1 for checkout integrations."
		echo "The registration and mapping for this class will be skipped!"
		echo "Make sure that you run convert-examples-to-sfdx.sh and execute sfdx force:source:push -f before setting up your store."
	else
		# Register the Apex class. If the class is already registered, a "duplicate value found" error will be displayed but the script will continue.
		# sfdx force:data:record:create -s RegisteredExternalService -v "DeveloperName=$2 ExternalServiceProviderId=$apexClassId ExternalServiceProviderType=$3 MasterLabel=$2"
		objectName="RegisteredExternalService"
		attributes="\"attributes\": { \"type\": \"$objectName\", \"referenceId\": \"${objectName}Ref1\"},"
		fieldValues="\"DeveloperName\":\"$2\", \"ExternalServiceProviderId\":\"$apexClassId\", \"ExternalServiceProviderType\":\"$3\", \"MasterLabel\":\"$2\""
		createJsonFile "$attributes $fieldValues"
		sf data import tree --files Data.json

		# Map the Apex class to the store if no other mapping exists for the same Service Provider Type
		# local storeIntegratedServiceId=`sf data query -q "SELECT Id FROM StoreIntegratedService WHERE ServiceProviderType='$3' AND StoreId='$storeId' LIMIT 1" -r csv |tail -n +2`
		createNewQuery "SELECT Id FROM StoreIntegratedService WHERE ServiceProviderType='$3' AND StoreId='$storeId' LIMIT 1"
		local storeIntegratedServiceId=`sf data query --file query.txt -r csv |tail -n +2`

		if [ -z "$storeIntegratedServiceId" ]
		then
			# No mapping exists, so we will create one
			# local registeredExternalServiceId=`sf data query -q "SELECT Id FROM RegisteredExternalService WHERE ExternalServiceProviderId='$apexClassId' LIMIT 1" -r csv |tail -n +2`
			createNewQuery "SELECT Id FROM RegisteredExternalService WHERE ExternalServiceProviderId='$apexClassId' LIMIT 1"
			local registeredExternalServiceId=`sf data query --file query.txt -r csv |tail -n +2`

			# sfdx force:data:record:create -s StoreIntegratedService -v "Integration=$registeredExternalServiceId StoreId=$storeId ServiceProviderType=$3"
			objectName="StoreIntegratedService"
			attributes="\"attributes\": { \"type\": \"$objectName\", \"referenceId\": \"${objectName}Ref1\"},"
			fieldValues="\"Integration\":\"$registeredExternalServiceId\", \"StoreId\":\"$storeId\", \"ServiceProviderType\":\"$3\""
			createJsonFile "$attributes $fieldValues"
			sf data import tree --files Data.json

		else
			echo "There is already a mapping in this store for $3 ServiceProviderType: $storeIntegratedServiceId"
		fi
	fi
}

# Maps a standard integration. This is for nodes like pricing and promotions which don't require external services to run.
function map_standard_integration {
	local serviceProviderType=$1
	local integrationName=$2

	echo "Mapping internal ($integrationName) for $serviceProviderType integration."

	# local integrationId=`sf data query -q "SELECT Id FROM StoreIntegratedService WHERE ServiceProviderType='$serviceProviderType' AND StoreId='$storeId' LIMIT 1" -r csv |tail -n +2`
	createNewQuery "SELECT Id FROM StoreIntegratedService WHERE ServiceProviderType='$serviceProviderType' AND StoreId='$storeId' LIMIT 1"
	local integrationId=`sf data query --file query.txt -r csv |tail -n +2`

	if [ -z "$integrationId" ]
	then
		# sfdx force:data:record:create -s StoreIntegratedService -v "Integration=$integrationName StoreId=$storeId ServiceProviderType=$serviceProviderType"
		objectName="StoreIntegratedService"
		attributes="\"attributes\": { \"type\": \"$objectName\", \"referenceId\": \"${objectName}Ref1\"},"
		fieldValues="\"Integration\":\"$integrationName\", \"StoreId\":\"$storeId\", \"ServiceProviderType\":\"$serviceProviderType\""
		createJsonFile "$attributes $fieldValues"
		sf data import tree --files Data.json
		echo "To register an external ($serviceProviderType) integration, delete the internal mapping and then add the external ($serviceProviderType) mapping.  See the code for details how."
	else
		echo "There is already a mapping in this store for ($serviceProviderType) ServiceProviderType: $integrationId"
	fi
}

function register_and_map_pricing_integration {
	map_standard_integration "Price" "Price__B2B_STOREFRONT__StandardPricing"
}

function register_and_map_promotions_integration {
	map_standard_integration "Promotions" "Promotions__B2B_STOREFRONT__StandardPromotions"
}

function register_and_map_credit_card_payment_integration {
	echo "Registering credit card payment integration."

	# Creating Payment Gateway Provider
	# apexClassId=`sf data query -q "SELECT Id FROM ApexClass WHERE Name='AuthorizeNetAdapter' LIMIT 1" -r csv |tail -n +2`
	createNewQuery "SELECT Id FROM ApexClass WHERE Name='AuthorizeNetAdapter' LIMIT 1"
	apexClassId=`sf data query --file query.txt -r csv |tail -n +2`

	echo "Creating PaymentGatewayProvider record using ApexAdapterId=$apexClassId."
	# sfdx force:data:record:create -s PaymentGatewayProvider -v "DeveloperName=AuthorizeNetPGProvider ApexAdapterId=$apexClassId MasterLabel=AuthorizeNetPGProvider IdempotencySupported=Yes Comments=Comments"
	objectName="PaymentGatewayProvider"
	attributes="\"attributes\": { \"type\": \"$objectName\", \"referenceId\": \"${objectName}Ref1\"},"
	fieldValues="\"DeveloperName\":\"AuthorizeNetPGProvider\", \"ApexAdapterId\":\"$apexClassId\", \"MasterLabel\":\"AuthorizeNetPGProvider\", \"IdempotencySupported\":\"Yes\", \"Comments\":\"Comments\""
	createJsonFile "$attributes $fieldValues"
	sf data import tree --files Data.json


	# Creating Payment Gateway
	# paymentGatewayProviderId=`sf data query -q "SELECT Id FROM PaymentGatewayProvider WHERE DeveloperName='AuthorizeNetPGProvider' LIMIT 1" -r csv | tail -n +2`
	createNewQuery "SELECT Id FROM PaymentGatewayProvider WHERE DeveloperName='AuthorizeNetPGProvider' LIMIT 1"
	paymentGatewayProviderId=`sf data query --file query.txt -r csv |tail -n +2`

	# namedCredentialId=`sf data query -q "SELECT Id FROM NamedCredential WHERE MasterLabel='Authorize.Net' LIMIT 1" -r csv | tail -n +2`
	createNewQuery "SELECT Id FROM NamedCredential WHERE MasterLabel='Authorize.Net' LIMIT 1"
	namedCredentialId=`sf data query --file query.txt -r csv |tail -n +2`

	echo "Creating PaymentGateway record using MerchantCredentialId=$namedCredentialId, PaymentGatewayProviderId=$paymentGatewayProviderId."
	# sfdx force:data:record:create -s PaymentGateway -v "MerchantCredentialId=$namedCredentialId PaymentGatewayName=AuthorizeNetPGateway PaymentGatewayProviderId=$paymentGatewayProviderId Status=ACTIVE Comments='This is the payment gateway related with Authorize.Net'"
	objectName="PaymentGateway"
	attributes="\"attributes\": { \"type\": \"$objectName\", \"referenceId\": \"${objectName}Ref1\"},"
	fieldValues="\"MerchantCredentialId\":\"$namedCredentialId\", \"PaymentGatewayName\":\"AuthorizeNetPGateway\", \"PaymentGatewayProviderId\":\"$paymentGatewayProviderId\", \"Status\":\"ACTIVE\", \"Comments\":\"This is the payment gateway related with Authorize.Net\""
	createJsonFile "$attributes $fieldValues"
	sf data import tree --files Data.json


	# Creating Store Integrated Service
	# storeId=`sf data query -q "SELECT Id FROM WebStore WHERE Name='$communityNetworkName' LIMIT 1" -r csv | tail -n +2`
	createNewQuery "SELECT Id FROM WebStore WHERE Name='$communityNetworkName' LIMIT 1"
	storeId=`sf data query --file query.txt -r csv |tail -n +2`


	# paymentGatewayId=`sf data query -q "SELECT Id FROM PaymentGateway WHERE PaymentGatewayName='AuthorizeNetPGateway' LIMIT 1" -r csv | tail -n +2`
	createNewQuery "SELECT Id FROM PaymentGateway WHERE PaymentGatewayName='AuthorizeNetPGateway' LIMIT 1"
	paymentGatewayId=`sf data query --file query.txt -r csv |tail -n +2`


	echo "Creating StoreIntegratedService using the $communityNetworkName store and Integration=$paymentGatewayId (PaymentGatewayId)"
	# sfdx force:data:record:create -s StoreIntegratedService -v "Integration=$paymentGatewayId StoreId=$storeId ServiceProviderType=Payment"
	objectName="StoreIntegratedService"
	attributes="\"attributes\": { \"type\": \"$objectName\", \"referenceId\": \"${objectName}Ref1\"},"
	fieldValues="\"Integration\":\"$paymentGatewayId\", \"StoreId\":\"$storeId\", \"ServiceProviderType\":\"Payment\""
	createJsonFile "$attributes $fieldValues"
	sf data import tree --files Data.json

}

register_and_map_integration "B2BCheckInventorySample" "CHECK_INVENTORY" "Inventory"
register_and_map_integration "B2BDeliverySample" "COMPUTE_SHIPPING" "Shipment"
register_and_map_integration "B2BTaxSample" "COMPUTE_TAXES" "Tax"

# By default, use the internal pricing integration
register_and_map_pricing_integration
# To use an external integration instead, use the code below:
# register_and_map_integration "B2BPricingSample" "COMPUTE_PRICE" "Price"
# Or follow the documentation for setting up the integration manually:
# https://developer.salesforce.com/docs/atlas.en-us.b2b_comm_lex_dev.meta/b2b_comm_lex_dev/b2b_comm_lex_integration_setup.htm

# By default, use the internal promotions integration
register_and_map_promotions_integration 

register_and_map_credit_card_payment_integration

echo "You can view the results of the mapping in the Store Integrations page at /lightning/page/storeDetail?lightning__webStoreId=$storeId&storeDetail__selectedTab=store_integrations"

# Map the checkout flow with the checkout component in the store
# This is to allow for changes in case for the checkout meta file which we have noticed to shift around quite a lot.
echo "2. Updating flow associated to checkout."
checkoutMetaFolder="experience-bundle-package/unpackaged/experiences/$communityExperienceBundleName/views/"
checkoutFileToGrep="Checkout.json"
# Do a case insensitive grep and capture file
greppedFile=`ls $checkoutMetaFolder | egrep -i "^$checkoutFileToGrep"`
echo "Grepped File is: " $greppedFile
checkoutMetaFile=$checkoutMetaFolder$greppedFile	
tmpfile=$(mktemp)
# This determines the name of the main flow as it will always be the only flow to terminate in "Checkout.flow"
mainFlowName=`ls force-app/main/default/flows/*Checkout.flow-meta.xml | sed 's/.*flows\/\(.*\).flow-meta.xml/\1/'`
echo "Main Flow Name File is: " $mainFlowName
# This will make this the selected checkout flow in the store
sed "s/sfdc_checkout__CheckoutTemplate/$mainFlowName/g" $checkoutMetaFile > $tmpfile
mv -f $tmpfile $checkoutMetaFile


# This adding group member needs to be evalueted better, since it is not a scratch org
# due that I'm removing it
# Add the Customer Community Plus Profile clone to the list of members for the store
#    + add value 'Live' to field 'status' to activate community
echo "3. Updating members list and activating community."
networkMetaFile="experience-bundle-package/unpackaged/networks/$communityNetworkName".network
tmpfile=$(mktemp)
sed "s/<networkMemberGroups>/<networkMemberGroups><profile>Buyer Profile<\/profile>/g;s/<status>.*/<status>Live<\/status>/g" $networkMetaFile > $tmpfile
mv -f $tmpfile $networkMetaFile

# Import Products and related data
# Get new Buyer Group Name
echo "4. Importing products and the other things"
buyergroupName=$(bash ./scripts/bash/5-importProductSample.sh $storename | tail -n 1)
echo_attention "Buyer group name $buyergroupName"

# If notnot working with scratch orgs, comment the code below
# Assign a role to the admin user, else update user will error out
echo "5. Mapping Admin User to Role."
# First of all, checks if that is not already created there...
# newRoleID=`sf data query --query \ "SELECT Id FROM UserRole WHERE Name = 'AdminRoleScriptCreation'" -r csv |tail -n +2`
createNewQuery "SELECT Id FROM UserRole WHERE Name = 'AdminRoleScriptCreation'"
newRoleID=`sf data query --file query.txt -r csv |tail -n +2`


if [ -z "$newRoleID" ]
then
	# ceoID=`sf data query --query \ "SELECT Id FROM UserRole WHERE Name = 'CEO'" -r csv |tail -n +2`
	createNewQuery "SELECT Id FROM UserRole WHERE Name = 'CEO'"
	ceoID=`sf data query --file query.txt -r csv |tail -n +2`

	# sfdx force:data:record:create -s UserRole -v "ParentRoleId='$ceoID' Name='AdminRoleScriptCreation' DeveloperName='AdminRoleScriptCreation' RollupDescription='AdminRoleScriptCreation' "
	objectName="UserRole"
	attributes="\"attributes\": { \"type\": \"$objectName\", \"referenceId\": \"${objectName}Ref1\"},"
	fieldValues="\"ParentRoleId\":\"$ceoID\", \"Name\":\"AdminRoleScriptCreation\", \"DeveloperName\":\"AdminRoleScriptCreation\", \"RollupDescription\":\"AdminRoleScriptCreation\""
	createJsonFile "$attributes $fieldValues"
	sf data import tree --files Data.json

	# after creating, just wait a little to get the id back
	# newRoleID=`sf data query --query \ "SELECT Id FROM UserRole WHERE Name = 'AdminRoleScriptCreation'" -r csv |tail -n +2`
	createNewQuery "SELECT Id FROM UserRole WHERE Name = 'AdminRoleScriptCreation'"
	newRoleID=`sf data query --file query.txt -r csv |tail -n +2`

	echo_attention "Admin user roleID ID created now $newRoleID"
else
	echo "Admin user roleID ID alreadt created $newRoleID"
fi


# after creating, just wait a little to get the id back
userName=`sfdx force:user:display | grep "Username" | sed 's/Username//g;s/^[[:space:]]*//g'`
trimName=`echo $userName | sed 's/ *$//g'`
userName=$trimName
# userId=`sf data query --query \ "SELECT Id FROM User WHERE username = '$userName'" -r csv |tail -n +2`
createNewQuery "SELECT Id FROM User WHERE username = '$userName'"
userId=`sf data query --file query.txt -r csv |tail -n +2`


echo_attention "Logged in username $userName ID $userId"
# after creating, just wait a little to get the id back
# sfdx force:data:record:update -s User -w "Id='$userId' username='$userName'" -v "UserRoleId='$newRoleID'" 
# Since we have a bash issue running on windows system, I have separeted the update
sf data update record --sobject User --record-id $userId --values "username='$userName'"
sf data update record --sobject User --record-id $userId --values "UserRoleId='$newRoleID'"

# Putted on the manifest to deploy there
# echo_attention "Deploying the profile to create the user"
# sfdx force:source:deploy -p ./force-app/main/default/profiles/Buyer\ Profile.profile-meta.xml

# Create Buyer User. Go to config/buyer-user-def.json to change name, email and alias.
echo "6. Creating Buyer User with associated Contact and Account."

echo_attention "Creating a folder to copy json file"
rm -rf setupB2b
mkdir setupB2b

# First of all, you need change the file information, and do the importation, that user, and account will be created, in one shot
# Replace the names there and put with the scratch org and store names
# Get the Contact user name
echo "Changing the configuration file information."
sed -E "s/YOUR_SCRATCH_NAME/$scratchOrgName/g;s/YOUR_STORE_NAME/$storename/g" scripts/json/buyer-user-def.json > setupB2b/tmpBuyerUserDef.json
createdUsername=`grep -i '"Username":' setupB2b/tmpBuyerUserDef.json|cut -d "\"" -f 4`

echo "Creating the user, contact and account"
sfdx force:user:create -f setupB2b/tmpBuyerUserDef.json

echo_attention "Assigning the Buyer permission set to the new user $createdUsername"

# sfdx force:user:permset:assign --permsetname <permset_name> --targetusername <admin-user> --onbehalfof <non-admin-user>
sfdx force:user:permset:assign --permsetname B2BBuyer --targetusername  $userName --onbehalfof $createdUsername

# Update the user information to something more friendly
# First get the user ID
# userId=`sf data query --query \ "SELECT Id FROM User WHERE username = '$userName'" -r csv |tail -n +2`
createNewQuery "SELECT Id FROM User WHERE username = '$createdUsername'"
createdUserId=`sf data query --file query.txt -r csv |tail -n +2`
# sfdx force:data:record:update -s User -w "Username='$createdUsername'" -v "FirstName='User ${scratchOrgName}'" 
# Since we have a bash issue running on windows system, I have separeted the update
sf data update record --sobject User --record-id $createdUserId --values "Username='$createdUsername'"
sf data update record --sobject User --record-id $createdUserId --values "FirstName='User $scratchOrgName'"


echo "Getting the contactId"
# contactId=`sf data query --query \ "SELECT ContactId FROM User WHERE Username = '${createdUsername}' ORDER BY CreatedDate Desc LIMIT 1" -r csv |tail -n +2`
createNewQuery "SELECT ContactId FROM User WHERE Username = '${createdUsername}' ORDER BY CreatedDate Desc LIMIT 1"
contactId=`sf data query --file query.txt -r csv |tail -n +2`


echo_attention "Updating the contact information to the createdUsername $createdUsername ContactId $contactId"

# Update the contact information to something more friendly
# sfdx force:data:record:update -s Contact -w "Id='$contactId'" -v "FirstName='Contact $scratchOrgName' LastName='$storename' Title='Mr.'" 
sf data update record --sobject Contact --record-id $contactId --values "FirstName='Contact $scratchOrgName'"
sf data update record --sobject Contact --record-id $contactId --values "LastName='$storename'"
sf data update record --sobject Contact --record-id $contactId --values "Title='Mr.'"

echo "Selecting Account ID."
# accountID=`sf data query --query \ "SELECT AccountId FROM Contact WHERE Id='$contactId' ORDER BY CreatedDate Desc LIMIT 1" -r csv |tail -n +2`
createNewQuery "SELECT AccountId FROM Contact WHERE Id='$contactId' ORDER BY CreatedDate Desc LIMIT 1"
accountID=`sf data query --file query.txt -r csv |tail -n +2`


echo_attention "ContactId $contactId related with AccountId $accountID "

# Update the account information to something more friendly
# sfdx force:data:record:update -s Account -w "Id='$accountID'" -v "Name='Account ${scratchOrgName} ${storename}' isBuyerEnabled__c=true" 
sf data update record --sobject Account --record-id $accountID --values "Name='Account $scratchOrgName $storename'"
sf data update record --sobject Account --record-id $accountID --values "isBuyerEnabled__c=true"


buyerAccountName="$storename Buyer Account"
echo "Buyer account name defined as $buyerAccountName" 

echo "Making the Account a Buyer Account."
# sfdx force:data:record:create -s BuyerAccount -v "BuyerId='$accountID' Name='$buyerAccountName' isActive=true"
objectName="BuyerAccount"
attributes="\"attributes\": { \"type\": \"$objectName\", \"referenceId\": \"${objectName}Ref1\"},"
fieldValues="\"BuyerId\":\"$accountID\", \"Name\":\"$buyerAccountName\", \"isActive\":\"true\""
createJsonFile "$attributes $fieldValues"
sf data import tree --files Data.json


# Assign Account to Buyer Group
echo "Assigning Buyer Account to Buyer Group."
# buyergroupID=`sf data query --query \ "SELECT Id FROM BuyerGroup WHERE Name = '${buyergroupName}'" -r csv |tail -n +2`
createNewQuery "SELECT Id FROM BuyerGroup WHERE Name = '${buyergroupName}'"
buyergroupID=`sf data query --file query.txt -r csv |tail -n +2`

# sfdx force:data:record:create -s BuyerGroupMember -v "BuyerGroupId='$buyergroupID' BuyerId='$accountID'"
objectName="BuyerGroupMember"
attributes="\"attributes\": { \"type\": \"$objectName\", \"referenceId\": \"${objectName}Ref1\"},"
fieldValues="\"BuyerGroupId\":\"$buyergroupID\", \"BuyerId\":\"$accountID\""
createJsonFile "$attributes $fieldValues"
sf data import tree --files Data.json


rm -rf setupB2b

# Add Contact Point Addresses to the buyer account associated with the buyer user.
# The account will have 2 Shipping and 2 billing addresses associated to it.
# To view the addresses in the UI you need to add Contact Point Addresses to the related lists for Account
echo "7. Add Contact Point Addresses to the Buyer Account."
# existingCPAForBuyerAccount=`sf data query --query \ "SELECT Id FROM ContactPointAddress WHERE ParentId='${accountID}' LIMIT 1" -r csv |tail -n +2`
createNewQuery "SELECT Id FROM ContactPointAddress WHERE ParentId='${accountID}' LIMIT 1"
existingCPAForBuyerAccount=`sf data query --file query.txt -r csv |tail -n +2`

if [ -z "$existingCPAForBuyerAccount" ]
then
	# sfdx force:data:record:create -s ContactPointAddress -v "AddressType='Shipping' ParentId='$accountID' ActiveFromDate='2020-01-01' ActiveToDate='2040-01-01' City='California' Country='US' IsDefault='true' Name='Default Shipping' PostalCode='99950' Street='333 Seymour Street (Shipping)'"
	objectName="ContactPointAddress"
	attributes="\"attributes\": { \"type\": \"$objectName\", \"referenceId\": \"${objectName}Ref1\"},"
	fieldValues="\"AddressType\":\"Shipping\", \"ParentId\":\"$accountID\", \"ActiveFromDate\":\"2023-01-01\", \"ActiveToDate\":\"2040-01-01\", \"City\":\"California\", \"Country\":\"US\", \"IsDefault\":\"true\", \"Name\":\"Default Shipping\", \"PostalCode\":\"99950\", \"Street\":\"333 Seymour Street (Shipping)\""
	createJsonFile "$attributes $fieldValues"
	sf data import tree --files Data.json

	# sfdx force:data:record:create -s ContactPointAddress -v "AddressType='Billing' ParentId='$accountID' ActiveFromDate='2020-01-01' ActiveToDate='2040-01-01' City='California' Country='US' IsDefault='true' Name='Default Billing' PostalCode='99949' Street='333 Seymour Street (Billing)'"
	fieldValues="\"AddressType\":\"Billing\", \"ParentId\":\"$accountID\", \"ActiveFromDate\":\"2023-01-01\", \"ActiveToDate\":\"2040-01-01\", \"City\":\"California\", \"Country\":\"US\", \"IsDefault\":\"true\", \"Name\":\"Default Billing\", \"PostalCode\":\"99950\", \"Street\":\"333 Seymour Street (Billing)\""
	createJsonFile "$attributes $fieldValues"
	sf data import tree --files Data.json

	# sfdx force:data:record:create -s ContactPointAddress -v "AddressType='Shipping' ParentId='$accountID' ActiveFromDate='2020-01-01' ActiveToDate='2040-01-01' City='California' Country='US' IsDefault='false' Name='Non-Default Shipping' PostalCode='99948' Street='415 Mission Street (Shipping)'"
	# sfdx force:data:record:create -s ContactPointAddress -v "AddressType='Billing' ParentId='$accountID' ActiveFromDate='2020-01-01' ActiveToDate='2040-01-01' City='California' Country='US' IsDefault='false' Name='Non-Default Billing' PostalCode='99957' Street='415 Mission Street (Billing)'"
else
	echo "There is already at least 1 Contact Point Address for your Buyer Account ${buyerAccountName}"
fi

echo "Setup Guest Browsing."
# storeType=`sf data query --query \ "SELECT Type FROM WebStore WHERE Name = '${communityNetworkName}'" -r csv |tail -n +2`
createNewQuery "SELECT Type FROM WebStore WHERE Name = '${communityNetworkName}'"
storeType=`sf data query --file query.txt -r csv |tail -n +2`

echo "Store Type is $storeType"
# Originally it just was doing to b2c... but...
# # Update Guest Profile with required CRUD and FLS
# if [ "$storeType" = "B2C" ]
# then
	sh ./scripts/bash/4-b2bGuestBrowsing.sh "$communityNetworkName" "$buyergroupName"
# fi	
#############################
#   Deploy Updated Store    #
#############################

echo "Creating the package to deploy, including the new flow."
cd experience-bundle-package/unpackaged/
# Before creating the package to deploy, let deactivate some options that are not going fine
# # This option update the field, but even comming with false, the error persis
# echo_attention "Deactivating some Network object options for storeId $networkId"
# sfdx force:data:record:update -s Network -w "Id='$networkId' " -v "OptionsApexCDNCachingEnabled=false" 


echo "Removing some options from the networks/$storename.network file"
# sed -i '' -e '/<meta>/,/<\/meta>/d' my-file.xml
# Since it is suposed to work in the api 56.0, this commands are not needed anymore
# sed -i -e "s/<enableApexCDNCaching>true<\/enableApexCDNCaching>//g" networks/$storename.network
# sed -i -e "s/<enableImageOptimizationCDN>true<\/enableImageOptimizationCDN>//g" networks/$storename.network
# sed -i -e "s/<enableImageOptimizationCDN>false<\/enableImageOptimizationCDN>//g" networks/$storename.network

cp -f ../../manifest/package-deploy-template.xml package.xml
zip -r -X ../"$communityExperienceBundleName"ToDeploy.zip *
cd ../..

# Uncomment the line below if you'd like to pause the script in order to save the zip file to deploy
read -p "Wait a little and, press <Enter> to resume... Just to avoind the UNABLE_TO_LOCK_ROW error..."

echo "Deploy the new zip including the flow, ignoring warnings, then clean-up."
sfdx force:mdapi:deploy -g -f experience-bundle-package/"$communityExperienceBundleName"ToDeploy.zip --wait -1 --verbose --singlepackage
# sfdx force:mdapi:deploy -g -f experience-bundle-package/storeFront1ToDeploy.zip --wait -1 --verbose --singlepackage

echo "Removing the package xml files used for retrieving and deploying metadata at this step."
rm package-retrieve.xml

echo "Publishing the community."
sfdx force:community:publish -n "$communityNetworkName"
sleep 10

echo "Creating search index."
sfdx 1commerce:search:start -n "$communityNetworkName"


echo_attention "Doing the layouts update"
sf project deploy start --ignore-conflicts --manifest manifest/package-03layouts.xml

# # Clean the path after running
rm -rf Deploy
rm -rf experience-bundle-package

removeTempFiles

echo ""
echo ""
echo_attention "Finishing the d2cStore set up and  buyer user creation at $(date)"

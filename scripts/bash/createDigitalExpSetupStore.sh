#!/bin/bash
# Use this command to create a new store.
# The name of the store can be passed as a parameter.
# shopt -s expand_aliases
# echo alias 
# alias 
# 
export SFDX_NPM_REGISTRY="http://platform-cli-registry.eng.sfdc.net:4880/"
export SFDX_S3_HOST="http://platform-cli-s3.eng.sfdc.net:9000/sfdx/media/salesforce-cli"
# 
#templateName="b2c-lite-storefront"
templateName="B2B Commerce"
# 
function echo_attention() {
  local green='\033[0;32m'
  local no_color='\033[0m'
  echo -e "${green}$1${no_color}"
}

#If you will run in a windows environment, please uncomment the code below
# sfdx="C:\\PROGRA~1\\sfdx\\bin\\sfdx"
# where sfdx
# where sfdx2

function error_and_exit() {
  local red_color='\033[0;31m'
  local no_color='\033[0m'
  echo -e "${red_color}$1${no_color}"
  exit 1
}

if [ -z "$1" ]
then
	error_and_exit "You need to specify the scratch org name to create it."
fi

if [ -z "$2" ]
then
	error_and_exit "You need to specify the the store name to create it."
fi

echo_attention "Starting the digital experience creation at $(date)"
echo ""
echo ""

scratchOrgName=$1
storename=$2

# Check if the store nam already exist, to no try create with error
checkExistinStoreId=`sfdx force:data:soql:query -q "SELECT Id FROM WebStore WHERE Name='$storename' LIMIT 1" -r csv |tail -n +2`

if [ ! -z "$checkExistinStoreId" ]
then
    echo_attention "Already exists an web store with this name, please define another."
    error_and_exit "The setup will stop."
fi

echo_attention "Doing the first settings definition (being scratch organization or not)"
rm -rf Deploy
sfdx force:source:convert -r force-app/ -d Deploy -x manifest/package-01additionalSettings.xml
sfdx force:mdapi:deploy -d Deploy/ -w -1 


sfdx force:community:create --name "$storename" --templatename "B2B Commerce" --urlpathprefix "$storename" --description "Store $storename created by the script."
echo ""

storeId=""

while [ -z "${storeId}" ];
do
    echo_attention "Store not yet created, waiting 10 seconds..."
    storeId=$(sfdx force:data:soql:query -q "SELECT Id FROM WebStore WHERE Name='${storename}' LIMIT 1" -r csv |tail -n +2)
    
    sleep 10
done

echo ""

echo_attention "Store found with id ${storeId}"
echo ""

# But we need it in an sandbox or productive orgs
echo_attention "Doing the second deployment"
rm -rf Deploy
sfdx force:source:convert -r force-app/ -d Deploy -x manifest/package-02mainObjects.xml

# These test classes will be added as soon as possible
# sfdx force:mdapi:deploy -d ..\..\Deploy/ -w 10 -l RunSpecifiedTests -r B2BAuthorizeTokenizedPaymentTest,B2BCheckInventorySampleTest,B2BDeliverySampleTest,B2BPaymentControllerTest,B2BPricingSampleTest,B2BSyncCheckInventoryTest,B2BSyncDeliveryTest,B2BSyncPricingTest,B2BSyncTaxTest,B2BTaxSampleTest,QuickStartIntegrationTest
# But for now, we'll just deploy it
sfdx force:mdapi:deploy -d Deploy/ -w 10 

# # Clean the path after runnin
rm -rf Deploy

set +x

echo ""

# Cleaning up if a previous run failed
rm -rf experience-bundle-package

echo ""
echo ""
echo_attention "Finishing the digital experience creation at $(date)"
echo ""
echo ""

./scripts/bash/setupStore.sh $scratchOrgName $storename || error_and_exit "Store setup failed."

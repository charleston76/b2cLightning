#!/bin/bash
# Use this command to create a new store.
# The name of the store can be passed as a parameter.
# shopt -s expand_aliases
# echo alias 
# alias 
# 
export SF_NPM_REGISTRY="http://platform-cli-registry.eng.sfdc.net:4880/"
export SF_S3_HOST="http://platform-cli-s3.eng.sfdc.net:9000/sfdx/media/salesforce-cli"
# 
templateName="B2B Commerce (LWR)"
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

function readValue(){
  local  definedValue=""

  while [ "$definedValue" = "" ]
  do
    read -p "Enter the $1 value to continue: " definedValue
  done

  echo "$definedValue"

}

function readParameterValue(){
  if [ -z "$1" ]
  then
      error_and_exit "You need to define which parameter will be read"
  fi

  local parameterToRead=$1
  echo_attention "$parameterToRead parameter value definition $2"

  local parameterValue=""
  parameterValue=$(readValue $parameterToRead)
  # echo_attention "Parameter to read $parameterToRead with value $parameterValue"

  case $parameterToRead in
    checkExistinStoreContinue)
      checkExistinStoreAnswer=$parameterValue
      ;;
  esac

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
checkExistinStoreContinue=""
checkExistinStoreAnswer=""

# Check if the store nam already exist, to no try create with error
# checkExistinStoreId=`sfdx force:data:soql:query -q "SELECT Id FROM WebStore WHERE Name='$storename' LIMIT 1" -r csv |tail -n +2`
checkExistinStoreId=`sf data query -q "SELECT Id FROM WebStore WHERE Name='$storename' LIMIT 1" -r csv |tail -n +2`


echo_attention "Doing the first settings definition (being scratch organization or not)"
# rm -rf Deploy
sf project deploy start --ignore-conflicts --manifest manifest/package-01additionalSettings.xml

if [ ! -z "$checkExistinStoreId" ]
then
    echo_attention "Already exists an web store with this name, do you want to continue loading the data to there?"
    readParameterValue "checkExistinStoreContinue" "(Y or N) anything different of Y will be considered N"

    if [[ "$checkExistinStoreAnswer" != "Y" && "$checkExistinStoreAnswer" != "y" ]]
    then
      # copyBuyerGroupsAnswer="N"
      error_and_exit "The process will stop!"
    else
      echo "Yes, let's continue loading the things!"
    fi
else
  sf community create --name "$storename" --template-name "$templateName" --url-path-prefix "$storename" --description "Store $storename created by the script."
  echo ""
fi

storeId=""

while [ -z "${storeId}" ];
do
    echo_attention "Store not yet created, waiting 10 seconds..."
    storeId=$(sf data query -q "SELECT Id FROM WebStore WHERE Name='${storename}' LIMIT 1" -r csv |tail -n +2)
    
    sleep 10
done

echo ""

echo_attention "Store found with id ${storeId}"
echo ""

# But we need it in an sandbox or productive orgs
echo_attention "Doing the second deployment"
# These test classes will be added as soon as possible
# But for now, we'll just deploy it
sf project deploy start --ignore-conflicts --manifest manifest/package-02mainObjects.xml

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

./scripts/bash/3-setupStore.sh $scratchOrgName $storename || error_and_exit "Store setup failed."

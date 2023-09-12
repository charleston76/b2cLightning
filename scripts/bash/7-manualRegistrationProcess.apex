// Based on the registration script
// register_and_map_integration "B2BCheckInventorySample" "CHECK_INVENTORY" "Inventory"
// register_and_map_integration "B2BDeliverySample" "COMPUTE_SHIPPING" "Shipment"
// register_and_map_integration "B2BTaxSample" "COMPUTE_TAXES" "Tax"
// register_and_map_integration "CustomPricingService" "CustomPricingService" "Extension" "Commerce_Domain_Pricing_Service"

// I've created the code below
String apexClassName = 'B2BTaxSample';
String developerName = 'COMPUTE_TAXES';
String providerType = 'Tax';
// This value is used just for custom price service
// String extensionPointName = 'Commerce_Domain_Pricing_Service';
// Otherwise need to be null
String extensionPointName = '';

//SELECT Id, Name FROM ApexClass WHERE Name IN ('CustomPricingService','B2BCheckInventorySample', 'B2BDeliverySample', 'B2BTaxSample')
String apexClassId = String.valueof([
    SELECT Id 
    FROM ApexClass 
    WHERE Name =: apexClassName]?.Id 
);
    
system.debug('apexClassName ' + apexClassName);
system.debug('apexClassId ' + apexClassId);
system.debug('providerType ' + providerType);
system.debug('extensionPointName ' + extensionPointName);

List<RegisteredExternalService> checkExists = [
    SELECT Id FROM RegisteredExternalService
    WHERE DeveloperName =: developerName
    OR    ExternalServiceProviderId =: apexClassId
];

system.debug('checkExists ' + checkExists);

if(checkExists.size()==0){
    RegisteredExternalService serviceList = new RegisteredExternalService(
        DeveloperName=developerName,
        MasterLabel=developerName ,
        ExternalServiceProviderType= providerType,
        ExternalServiceProviderId = apexClassId
    );

    if (String.isNotEmpty(extensionPointName)) serviceList.ExtensionPointName = extensionPointName;

    insert serviceList;
    
    system.debug('serviceList ' + serviceList);
}


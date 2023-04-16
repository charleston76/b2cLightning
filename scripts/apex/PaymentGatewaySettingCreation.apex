Map<string,string> objMap = new Map<string,string>();
List<PaymentGatewaySetting__c> objInsert = new List<PaymentGatewaySetting__c>();
// Adding the values in the map
objMap.put('PAYMENT_GATEWAY_SETTING' , 'AUTHORIZE.NET');
objMap.put('PAYMENT_GATEWAY_API_LOGIN' , 'YOUR_API_LOGIN_HERE');
objMap.put('PAYMENT_GATEWAY_TRANSACTION_KEY' , 'YOUR_TRANSACTION_KEY_HERE');
// sandbox      = 'https://apitest.authorize.net/xml/v1/request.api';
// production   = 'https://api.authorize.net/xml/v1/request.api';
objMap.put('PAYMENT_GATEWAY_ENVIRONMENT' , 'https://apitest.authorize.net/xml/v1/request.api');

// Select the existing information
List<PaymentGatewaySetting__c> lstPayGatSet = [
    SELECT Id, Name
    FROM PaymentGatewaySetting__c
    WHERE NAME =: objMap.get('PAYMENT_GATEWAY_SETTING')
];

If (lstPayGatSet.size() == 0){
    PaymentGatewaySetting__c newRow = new PaymentGatewaySetting__c(
        Name = objMap.get('PAYMENT_GATEWAY_SETTING'),
        APILogin__c = objMap.get('PAYMENT_GATEWAY_API_LOGIN'),
        APITransactionKey__c = objMap.get('PAYMENT_GATEWAY_TRANSACTION_KEY'),
        Environment__c = objMap.get('PAYMENT_GATEWAY_ENVIRONMENT')
    );
    objInsert.add(newRow);
}

system.debug('objInsert '  + objInsert);
if (objInsert.size()>0 ) insert objInsert;
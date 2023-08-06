/*
 * This class file acts as a controller to fetch and return the required JSON
 * for Authorize.Net Transactions.
 * 
 ***Please Note: Authorize.Net does not have a native JSON parser, it remaps the JSON
 ***string this file sends, into XML for processing on their side.  What this means
 ***for this class, it must maintain PERFECT ordering of the json elements as its
 ***being generated.  This is why APEX classes were not used for the request.  APEX
 ***classes are being used for all responses.
 */
public with sharing class B2BAuthorizeNetRequest {
    private static final String CLASS_NAME = 'B2BAuthorizeNetRequest';

    public HttpResponse sendRequest(String json) {
        String METHOD_NAME = 'sendRequest';
        system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' json ' + json);
        HttpRequest request = new HttpRequest();
        request.setEndpoint(''); // Uses the named credentials URL this gateway is mapped to.
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Content-Length', 'text');
        request.setHeader('Content-Encoding', 'UTF-8');
        request.setHeader('Host', 'Request');
        request.setHeader('Accept', 'application/json');
        
        // Add our body
        request.setBody(json);
        
        commercepayments.PaymentsHttp http = new commercepayments.PaymentsHttp();
        HttpResponse response = http.send(request);

        // Detects Server Response
        if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
            // Handle response
            return response;
        }
    
        // Beef up error detecting
        throw new CalloutException(response.getBody());
    }

    public HttpResponse createAuthTransaction(commercepayments.AuthorizationRequest authRequest) {
        String METHOD_NAME = 'createAuthTransaction';
        system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' authRequest ' + authRequest);
        commercepayments.AuthApiPaymentMethodRequest paymentMethod  = authRequest.paymentMethod;        
        commercepayments.AddressRequest addressRequest  = paymentMethod.address;        
        commercepayments.CardPaymentMethodRequest cardRequest = paymentMethod.cardPaymentMethod;
        system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' paymentMethod ' + paymentMethod);
        system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' addressRequest ' + addressRequest);
        system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' cardRequest ' + cardRequest);
        // Build our JSON
        JSONGenerator gen = JSON.createGenerator(true);

        try {
            CredentialCheck objCredent = getCredentialCheck();

            gen.writeStartObject();
            // Add CreateTransactionRequest
            gen.writeFieldName('createTransactionRequest');
            gen.writeStartObject();
            
            // Add MerchantAuthentication
            gen.writeFieldName('merchantAuthentication');
            gen.writeStartObject();
            gen.writeStringField('name', objCredent.loginId);
            gen.writeStringField('transactionKey',objCredent.transKey);
            gen.writeEndObject();
            // End MerchantAuthentication

            gen.writeStringField('refId','');
            
            // Add TransactionRequest
            gen.writeFieldName('transactionRequest');
            gen.writeStartObject();
            gen.writeStringField('transactionType', 'authOnlyTransaction'); // Authorize ONLY
            gen.writeStringField('amount',String.valueOf(authRequest.amount));
            gen.writeStringField('currencyCode',authRequest.currencyIsoCode); // Pull context
            
            // Add Payment
            gen.writeFieldName('payment');
            gen.writeStartObject();
            gen.writeFieldName('creditCard');
            gen.writeStartObject();
            gen.writeStringField('cardNumber', cardRequest.cardNumber);
            gen.writeStringField('expirationDate',cardRequest.expiryYear+'-'+cardRequest.expiryMonth); //2025-12
            gen.writeStringField('cardCode',cardRequest.cvv);
            gen.writeEndObject();
            gen.writeEndObject();
            // End Payment

            // Add Line items
            // Add Tax
            // Add Duty
            // Add Shipping
            // Add PoNumber
            // Add Customer

            String fname = cardRequest.cardHolderFirstName == null ? '' : cardRequest.cardHolderFirstName;
            String lname = cardRequest.cardHolderLastName == null ? '' : cardRequest.cardHolderLastName;

            // Add BillTo
            gen.writeFieldName('billTo');
            gen.writeStartObject();
            //gen.writeStringField('firstName', cardRequest.cardHolderName);
            //gen.writeStringField('lastName', cardRequest.cardHolderName);
            //gen.writeStringField('company',addressRequest.companyName);
            gen.writeStringField('address',addressRequest.street);
            gen.writeStringField('city',addressRequest.city);
            gen.writeStringField('state',addressRequest.state);
            gen.writeStringField('zip',addressRequest.postalCode);
            gen.writeStringField('country',addressRequest.country);
            gen.writeEndObject();
            // End BillTo

            // ShipTo
            // CustomerIp

            /* Add TransactionSettings
            gen.writeFieldName('transactionSettings');
            gen.writeStartObject();
            gen.writeFieldName('settings');
            gen.writeStartObject();
            gen.writeStringField('settingName','testRequest');
            gen.writeStringField('settingValue','false');
            gen.writeEndObject();
            gen.writeEndObject();
            // End TransactionSettings*/
            
            
            // Add ProcessingOptions
            gen.writeFieldName('processingOptions');
            gen.writeStartObject();
            gen.writeStringField('isFirstSubsequentAuth','true');
            gen.writeEndObject();
            // End ProcessingOptions
            
            // Add AuthorizationIndicatorType
            gen.writeFieldName('authorizationIndicatorType');
            gen.writeStartObject();
            gen.writeStringField('authorizationIndicator','final');
            gen.writeEndObject();
            // End AuthorizationIndicatorType
            
            // End TransactionRequest
            gen.writeEndObject();
            // End CreateTransactionRequest
            gen.writeEndObject();
            // End initial Object
            gen.writeEndObject();            
        } catch (Exception objEx) {
            // System.debug(CLASS_NAME + ' ' + METHOD_NAME + ' Error Line Number: ' + objEx.getLineNumber() + ' Message ' + objEx.getMessage());
            throw objEx;
        }
        // Send the Request
        return this.sendRequest(gen.getAsString());
    }

    public static CredentialCheck getCredentialCheck(){
        String METHOD_NAME = 'getCredentialCheck';

        string PAYMENT_GATEWAY_SETTING_NAME = 'AUTHORIZE.NET';
        CredentialCheck objCred = new CredentialCheck();
        try {
            
            Map<String, PaymentGatewaySetting__c> objSettings = PaymentGatewaySetting__c.getAll();

            objCred.loginId = objSettings.get('PAYMENT_GATEWAY_API_LOGIN').Value__c;
            objCred.transKey = objSettings.get('PAYMENT_GATEWAY_TRANSACTION_KEY').Value__c;
            system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' objCred.loginId ' + objCred.loginId);    
            system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' objCred.transKey ' + objCred.transKey);    
        } catch (Exception objEx) {
            // System.debug(CLASS_NAME + ' ' + METHOD_NAME + ' Error Line Number: ' + objEx.getLineNumber() + ' Message ' + objEx.getMessage());
            throw objEx;
        }
        return objCred;
    }

    public class CredentialCheck {
        public string loginId = '';
        public string transKey = '';
    }

}
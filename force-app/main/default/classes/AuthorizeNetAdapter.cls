public with sharing class AuthorizeNetAdapter implements commercepayments.PaymentGatewayAdapter {
    
    public commercepayments.GatewayResponse processRequest(commercepayments.paymentGatewayContext gatewayContext) {
        commercepayments.RequestType requestType = gatewayContext.getPaymentRequestType();
        commercepayments.GatewayResponse response;
        try {
            if(String.valueOf(requestType) == 'Authorize') {  // AUTH ONLY
                commercepayments.AuthorizationRequest authRequest = (commercepayments.AuthorizationRequest) gatewayContext.getPaymentRequest();
                response = createAuthResponse((commercepayments.AuthorizationRequest)gatewayContext.getPaymentRequest());
            }
            return response;
        } catch(Exception e) {
            system.debug(e.getMessage());
            return new commercepayments.GatewayErrorResponse('400', e.getMessage());
        }
    }

    public commercepayments.GatewayResponse createAuthResponse(commercepayments.AuthorizationRequest authRequest) {
		// Setup Authorize.Net
        B2BAuthorizeNetRequest authNetRequest = new B2BAuthorizeNetRequest();
        HttpResponse authNetRequestResponse = authNetRequest.createAuthTransaction(authRequest);
        // Handle our Response
        B2BAuthorizeNetResponse authNetResponse = B2BAuthorizeNetResponse.parse(authNetRequestResponse.getBody().replace('\uFEFF','').trim());
        
        commercepayments.AuthorizationResponse authResponse = new commercepayments.AuthorizationResponse();
        authResponse.setGatewayDate(System.now());
        authResponse.setAmount(authRequest.amount);

        // Setup default messages.
        B2BAuthorizeNetResponse.Messages_Z messages = authNetResponse.messages;
        B2BAuthorizeNetResponse.Message message = messages.message[0];
        authResponse.setGatewayResultCode(messages.resultCode);
        authResponse.setGatewayMessage(message.text);

        B2BAuthorizeNetResponse.TransactionResponse transactionResponse = authNetResponse.transactionResponse;
        if(messages.resultCode == 'Ok') {
            
            //authResponse.setAuthorizationExpirationDate(authExpDate);
            authResponse.setGatewayAuthCode(transactionResponse.authCode);
            authResponse.setGatewayAvsCode(transactionResponse.avsResultCode);            
            //authResponse.setGatewayReferenceDetails(gatewayReferenceDetails);
            authResponse.setGatewayReferenceNumber(transactionResponse.transId);
            authResponse.setGatewayResultCode('200');
            
            commercepayments.PaymentMethodTokenizationResponse paymentMethodTokenizationResponse = new commercepayments.PaymentMethodTokenizationResponse();
            paymentMethodTokenizationResponse.setGatewayTokenDetails(transactionResponse.accountNumber);
            paymentMethodTokenizationResponse.setGatewayDate(System.now());
            paymentMethodTokenizationResponse.setGatewayTokenEncrypted(transactionResponse.transHashSha2);
            B2BAuthorizeNetResponse.Messages transMessage = transactionResponse.messages[0];
            paymentMethodTokenizationResponse.setGatewayResultCode(transMessage.code);
	        paymentMethodTokenizationResponse.setGatewayMessage(transMessage.description);
            authResponse.setPaymentMethodTokenizationResponse(paymentMethodTokenizationResponse);
            
            authResponse.setGatewayResultCodeDescription(message.text);
            authResponse.setSalesforceResultCodeInfo(new commercepayments.SalesforceResultCodeInfo(commercepayments.SalesforceResultCode.Success));
            return authResponse;
        }
        
        if(messages.resultCode == 'Error') {
            List<B2BAuthorizeNetResponse.Errors> authNetErrors = transactionResponse.errors;
            authResponse.setGatewayMessage(authNetErrors[0].errorText);
            authResponse.setGatewayResultCode(authNetErrors[0].errorCode);
            return new commercepayments.GatewayErrorResponse('400', authNetErrors[0].errorText);
        }
        
        // Handle Errors
        authResponse.setSalesforceResultCodeInfo(new commercepayments.SalesforceResultCodeInfo(commercepayments.SalesforceResultCode.ValidationError));
        return authResponse;
        
    }
}
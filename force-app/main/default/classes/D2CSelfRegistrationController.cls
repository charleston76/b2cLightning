/**
 * @description The controller class to do the self registration
 */
public without sharing class D2CSelfRegistrationController {
    @AuraEnabled(cacheable=true)
    public static String isEmailContactExist(String email){
        return D2CSelfRegistrationHelper.isEmailContactExist(email);
    }

    @AuraEnabled
    public static String createUserContact(String strAccount, String strContact, String strUserType) {
        return D2CSelfRegistrationHelper.createUserContact(strAccount, strContact, strUserType);
    }    
}
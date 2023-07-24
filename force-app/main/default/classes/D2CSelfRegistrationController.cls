/**
 * @description The controller class to do the self registration
 */
public without sharing class D2CSelfRegistrationController {
    private static Map<String,String> mapConfig = new  Map<String,String>();
    private static final String CLASS_NAME = 'D2CSelfRegistrationController';
    private static final String GENERAL_CASE_CREATION_NAME = 'GENERAL_CASE_CREATION';
    private static final String DEFAULT_B2B_USER_TYPE = 'B2B';
    /**
     * @description Instantiate the class and get the configuration 
     */
    private static void getSelfRegistrationConfigurations(){
        // Read the custom metadata
        for (D2CSelfRegistration__mdt objConfig : [
            SELECT Id, DeveloperName, MasterLabel, isActive__c 
            FROM D2CSelfRegistration__mdt
            WITH SECURITY_ENFORCED ]){
            // Just add if the configuration is active
            if (objConfig.isActive__c) { mapConfig.put(objConfig.DeveloperName, objConfig.DeveloperName == GENERAL_CASE_CREATION_NAME ? 'true' : objConfig.MasterLabel); }
        }

        if (Test.isRunningTest()) {
            // Create the data
            mapConfig = new Map<string,string>{
                'GENERAL_GUEST_ACCOUNT' => 'B2B Guest Account', 
                'GENERAL_BUYER_GROUP' => 'Web Store',
                'GENERAL_PROFILE' => 'Customer Community Plus Login User',
                'GENERAL_CASE_CREATION'  => 'true',
                'GENERAL_CASE_DESCRIPTION'  => 'New User in storefront requires approval.',
                'GENERAL_CASE_SUBJECT'  => 'New User Approval'
            };
        }

    }

    // Look up and find any contact currenly in the system, that has this email
    // There could be more than 1, store the Account Ids for later.
    // Use the Account Ids to check against the Find your Instution result the user selects.
    @AuraEnabled(cacheable=true)
  /**
   * @description retrieve recommendation products
   * @param email the email account to do the registration
   * @return return string to json
   */
    public static String isEmailContactExist(String email){
        List<Contact> contactList = [
                SELECT AccountId, Account.Name, Account.BillingAddress, Account.IsBuyer, FirstName, LastName, Email,
                        (SELECT Id, IsActive FROM Users)
                FROM Contact WHERE Email =:email
                WITH SECURITY_ENFORCED
        ];
        return JSON.serialize(contactList);
    }

    @AuraEnabled
  /**
   * @description retrieve recommendation products
   * @param contact the contact record
   * @return return true or false
   */
    public static Boolean registerUser(Contact contact) {
        Boolean userRegistered = false;
        try {
            // We could check for communityNickname, if exists, add numbers.
            String communityNickname = contact.FirstName + contact.LastName;
            if (communityNickname.length() > 4) {
                communityNickname = communityNickname.substring(0, 4);
            }
            
            List<User> lstUser = getUser( communityNickname);
            Set<String> communityNicknameSet = getCommunityNicknameSet(lstUser);

            String uniqueCommunityNickName;
            if(communityNicknameSet.isEmpty()) {
                uniqueCommunityNickName = communityNickname + String.valueOf(Integer.valueOf(Math.random() * 10000));
            } else {
                for (Integer i=1; i <= 9999 ; i++) {
                    uniqueCommunityNickName = communityNickname + String.valueOf(Integer.valueOf(Math.random() * 10000));
                    if (!communityNicknameSet.contains(uniqueCommunityNickName)) {break;}
                }
            }

            if (Test.isRunningTest() ) { 
                getSelfRegistrationConfigurations();
            }

            // Create the external user with the contact information
            createExternalUser(contact, uniqueCommunityNickName);
            // Create a case if this configuration is enabled
            if (Boolean.valueOf(mapConfig.get('GENERAL_CASE_CREATION'))) { createCase(contact); }

            userRegistered = true;
        } catch (Exception e) {throw new UtilApplicationException(e.getMessage());
        }

        return userRegistered;
    }


  /**
   * @description get the community set accoring with the users
   * @param lstUser the value to get
   * @return set with the ones found
   */
    private static Set<String> getCommunityNicknameSet(List<User> lstUser){
        Set<String> communityNicknameSet = new Set<String>();
        for(User user : lstUser) {communityNicknameSet.add(user.CommunityNickname);}

        return communityNicknameSet;
    }

  /**
   * @description get the community profile Id
   * @return community profile
   */
    private static ID getCommunityProfileId(){
        return [SELECT Id FROM Profile WHERE Name =: mapConfig.get('GENERAL_PROFILE')]?.Id;
    }

  /**
   * @description get the user data
   * @param communityNickname the value to get
   * @return user list
   */
    private static List<User> getUser(String communityNickname){
        return [
            SELECT Id, CommunityNickname FROM User 
            WHERE CommunityNickname LIKE :communityNickname + '%'
            WITH SECURITY_ENFORCED
        ];
    }

  /**
   * @description create the externa user
   * @param contact the contact that will be an user
   * @param uniqueCommunityNickName the unique name defined
   */
    private static void createExternalUser(Contact contact, String uniqueCommunityNickName){
        User user = new User();
        user.FirstName = contact.FirstName;
        user.LastName = contact.LastName;
        user.Username = contact.Email;
        user.Email = contact.Email;
        user.CommunityNickname = uniqueCommunityNickName;
        user.ContactId = contact.Id;

        Id profileId = getCommunityProfileId();

        user.ProfileId = profileId;

        Site.createExternalUser(user, contact.AccountId);
    }
    
  /**
   * @description create a case to let the internal team knows about it
   * @param objContact the contact record
   * @return return true or false
   */
    public static Boolean createCase(Contact objContact) {

        try {
            Case objCase = new Case(
                ContactId = objContact.Id,
                AccountId = objContact.AccountId,
                Subject = mapConfig.get('GENERAL_CASE_SUBJECT'),
                Description = mapConfig.get('GENERAL_CASE_DESCRIPTION') );
    
            UtilDatabase.insertRecords( objCase,true); 
                
        } catch (Exception objEx) {throw new UtilApplicationException(objEx.getMessage());}

        return true;
    }
   
    @AuraEnabled
  /**
   * @description Creates the buyer account
   * @param strAccount the account parameter to create
   * @param strContact the contact parameter to create
   * @return return true or false
   */
    public static Boolean createUserContact(String strAccount, String strContact, String strUserType) {
        String METHOD_NAME = 'createUserContact';
        Boolean blnReturn = false;

        system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' strAccount ' + strAccount);
        system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' strContact ' + strContact);
        system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' strUserType ' + strUserType);

        /*
         * I'll adjust this method to work with B2B and B2C configurations
         * since we need define an account to create an user in B2B definition
         * for now, I'll do just the B2C creation, but the B2B is already defined
         * when you get getSelfRegistrationConfigurations 
         */
        try {
            if (strUserType == DEFAULT_B2B_USER_TYPE) {
                blnReturn = createB2bUserContact(strAccount, strContact);
            } else {
                blnReturn = createPersonAccount(strContact);
            }
        } catch (Exception objEx) {
            String strErrorMessage = 'LineNumber ' + objEx.getLineNumber() + ' Message: ' + objEx.getMessage();
            system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' strErrorMessage ' + strErrorMessage);
            throw new UtilApplicationException(strErrorMessage);
        }

        return blnReturn;
    }


    private static Boolean createPersonAccount(String strContact) {
        String METHOD_NAME = 'createPersonAccount';
        Boolean blnReturn = false;
        system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' strContact ' + strContact);
        try {

            Contact objContact = (Contact)JSON.deserialize(strContact, Contact.class);
            system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' objContact ' + objContact);
            // Get the recordType to create the person account
            // Id recordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Person_Account').getRecordTypeId();
            Id recordTypeId = [SELECT Id FROM RecordType WHERE IsPersonType = TRUE AND SObjectType='Account' LIMIT 1].Id;


            Account personAccount = new Account(RecordTypeId = recordTypeId);
            
            // for person accounts we can not update the Name field instead we have to update the    FirstName and LastName individually
            personAccount.FirstName = objContact.FirstName;
            personAccount.LastName = objContact.LastName;
            UtilDatabase.insertRecords(personAccount, true);
            system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' personAccount ' + personAccount);

            objContact.AccountId = personAccount.Id;
            objContact.Id = personAccount.PersonContactId;
            system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' objContact ' + objContact);
            blnReturn = registerUser(objContact);

        } catch (Exception objEx) {
            String strErrorMessage = 'LineNumber ' + objEx.getLineNumber() + ' Message: ' + objEx.getMessage();
            system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' strErrorMessage ' + strErrorMessage);
            throw new UtilApplicationException(strErrorMessage);
        }

        return blnReturn;
    }    

    private static Boolean createB2bUserContact(String strAccount, String strContact) {
        String METHOD_NAME = 'createB2bUserContact';
        Account account;
        Contact contact;
        Boolean blnReturn = false;
        try {
            getSelfRegistrationConfigurations();
            contact = (Contact)JSON.deserialize(strContact, Contact.class);
            if (String.isNotBlank(strAccount)) {
                account = (Account) JSON.deserialize(strAccount, Account.class);
            } else {
                account = [
                    SELECT Id, Name 
                    FROM Account 
                    WHERE Name =: mapConfig.get('GENERAL_GUEST_ACCOUNT')
                    WITH SECURITY_ENFORCED 
                    LIMIT 1 ];
            }
            contact.AccountId = account.Id;
            UtilDatabase.insertRecords(contact, true);
            blnReturn = registerUser(contact);
        } catch (Exception objEx) {
            String strErrorMessage = 'LineNumber ' + objEx.getLineNumber() + ' Message: ' + objEx.getMessage();
            system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' strErrorMessage ' + strErrorMessage);
            throw new UtilApplicationException(strErrorMessage);
        }

        return blnReturn ;
    }    
}
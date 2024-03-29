public without sharing class D2CSelfRegistrationHelper {
    private static Map<String,String> mapConfig = new  Map<String,String>();
    private static final String CLASS_NAME = 'D2CSelfRegistrationController';
    private static final String GENERAL_CASE_CREATION_NAME = 'GENERAL_CASE_CREATION';
    private static final String DEFAULT_B2B_USER_TYPE = 'B2B';
    /**
     * @description Instantiate the class and get the configuration 
     */
    public static Map<String,String> getSelfRegistrationConfigurations(){
        Map<String,String> mapReturnConfig = new Map<String,String>();
        // Read the custom metadata
        for (D2CSelfRegistration__mdt objConfig : [
            SELECT Id, DeveloperName, MasterLabel, isActive__c 
            FROM D2CSelfRegistration__mdt
            WITH SECURITY_ENFORCED ]){
            // Just add if the configuration is active
            if (objConfig.isActive__c) { mapConfig.put(objConfig.DeveloperName, objConfig.DeveloperName == GENERAL_CASE_CREATION_NAME ? 'true' : objConfig.MasterLabel); }
            if (objConfig.isActive__c) { mapReturnConfig.put(objConfig.DeveloperName, objConfig.DeveloperName == GENERAL_CASE_CREATION_NAME ? 'true' : objConfig.MasterLabel); }
        }

        if (Test.isRunningTest()) {
            // Create the data
            mapConfig = new Map<string,string>{
                'GENERAL_GUEST_ACCOUNT' => 'B2B Guest Account', 
                'GENERAL_BUYER_GROUP' => 'd2cStore Buyer Group',
                'GENERAL_B2B_PROFILE' => 'Buyer Profile',
                'GENERAL_D2C_PROFILE' => 'Shopper Profile',
                'GENERAL_CASE_CREATION'  => 'true',
                'GENERAL_CASE_DESCRIPTION'  => 'New User in storefront requires approval.',
                'GENERAL_CASE_SUBJECT'  => 'New User Approval'
            };
        }

        return mapReturnConfig;

    }

    // Look up and find any contact currenly in the system, that has this email
    // There could be more than 1, store the Account Ids for later.
    // Use the Account Ids to check against the Find your Instution result the user selects.
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

  /**
   * @description retrieve recommendation products
   * @param contact the contact record
   * @return return true or false
   */
    private static D2CSelfRegistrationHelper.SelfRegistrationReturn registerUser(Contact contact, String strUserType) {
        String METHOD_NAME = 'registerUser';
        system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' contact ' + contact);
        D2CSelfRegistrationHelper.SelfRegistrationReturn userRegistered ;
        try {
            // We could check for communityNickname, if exists, add numbers.
            String communityNickname = contact.FirstName + contact.LastName;
            if (communityNickname.length() > 4) {
                communityNickname = communityNickname.substring(0, 4);
            }
            // system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' communityNickname ' + communityNickname);

            List<User> lstUser = getUser( communityNickname);
            // system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' lstUser ' + lstUser);
            Set<String> communityNicknameSet = getCommunityNicknameSet(lstUser);
            // system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' communityNicknameSet ' + communityNicknameSet);

            String uniqueCommunityNickName;
            if(communityNicknameSet.isEmpty()) {
                uniqueCommunityNickName = communityNickname + String.valueOf(Integer.valueOf(Math.random() * 10000));
            } else {
                for (Integer i=1; i <= 9999 ; i++) {
                    uniqueCommunityNickName = communityNickname + String.valueOf(Integer.valueOf(Math.random() * 10000));
                    if (!communityNicknameSet.contains(uniqueCommunityNickName)) {break;}
                }
            }
            // system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' uniqueCommunityNickName ' + uniqueCommunityNickName);
            if (Test.isRunningTest() ) { 
                getSelfRegistrationConfigurations();
            }

            // Create the external user with the contact information
            String userId = createExternalUser(contact, uniqueCommunityNickName, strUserType);
            system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' userId ' + userId);

            userRegistered = new D2CSelfRegistrationHelper.SelfRegistrationReturn(true, contact.accountId, contact.Id, '', userId);
        } catch (Exception objEx) {
            String strErrorMessage = CLASS_NAME + ' ' + METHOD_NAME + ' LineNumber ' + objEx.getLineNumber() + ' Message: ' + objEx.getMessage();
            userRegistered = new D2CSelfRegistrationHelper.SelfRegistrationReturn(false, '', '', strErrorMessage,'');
            system.debug(' strErrorMessage ' + strErrorMessage);
            system.debug(' userRegistered ' + userRegistered);
            throw new UtilApplicationException(strErrorMessage);
        } 

        return userRegistered;
    }

    private static String jsonConversion(D2CSelfRegistrationHelper.SelfRegistrationReturn objConvert){
        return JSON.serialize(objConvert);
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
    private static ID getCommunityProfileId(String strUserType){
        String METHOD_NAME = 'getCommunityProfileId';
        String profileName = strUserType == DEFAULT_B2B_USER_TYPE ? mapConfig.get('GENERAL_B2B_PROFILE') : mapConfig.get('GENERAL_D2C_PROFILE');
        // system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' GENERAL_B2B_PROFILE ' + mapConfig.get('GENERAL_B2B_PROFILE'));
        // system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' GENERAL_D2C_PROFILE ' + mapConfig.get('GENERAL_D2C_PROFILE'));
        system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' profileName ' + profileName);
        
        Id profileId = [SELECT Id FROM Profile WHERE Name =: profileName]?.Id;
        system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' profileId ' + profileId);

        return profileId;
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
    private static String createExternalUser(Contact contact, String uniqueCommunityNickName, String strUserType){
        String METHOD_NAME = 'createExternalUser';
        String strUserId = '';

        try {
            // system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' uniqueCommunityNickName ' + uniqueCommunityNickName);
            User user = new User();
            user.FirstName = contact.FirstName;
            user.LastName = contact.LastName;
            user.Username = contact.Email;
            user.Email = contact.Email;
            user.CommunityNickname = uniqueCommunityNickName;
            user.ContactId = contact.Id;
    
            Id profileId = getCommunityProfileId(strUserType);
    
            user.ProfileId = profileId;
            
            // system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' contact ' + contact);
            Site.createExternalUser(user, contact.AccountId);
            // system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' user ' + user);

            strUserId = String.valueOf([
                SELECT Id FROM User
                WHERE ContactId =: contact.Id
            ]?.Id);
            system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' strUserId ' + strUserId);
        } catch (Exception objEx) {
            String strErrorMessage = CLASS_NAME + ' ' + METHOD_NAME + ' LineNumber ' + objEx.getLineNumber() + ' Message: ' + objEx.getMessage();
            system.debug(' strErrorMessage ' + strErrorMessage);
            throw new UtilApplicationException(strErrorMessage);
        }

        return strUserId ;
    }
    
  /**
   * @description create a case to let the internal team knows about it
   * @param objContact the contact record
   * @return return true or false
   */
    private static void createCase(Map<String,Contact> mapContacts) {
        String METHOD_NAME = 'createCase';
        List<Case> lstCase = new List<Case>();
        system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' mapContacts ' + mapContacts);
        system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' GENERAL_CASE_SUBJECT ' + mapConfig.get('GENERAL_CASE_SUBJECT'));
        system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' GENERAL_CASE_DESCRIPTION ' + mapConfig.get('GENERAL_CASE_DESCRIPTION'));

        try {

            string storeName = getBuyerGoupStoreName();

            for (String contactId : mapContacts.keySet()){
                system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' contactId ' + contactId);
        
                Case objCase = new Case();
                objCase.AccountId = mapContacts.get(contactId).Account.Id;
                objCase.ContactId = contactId;
                objCase.Subject = mapConfig.get('GENERAL_CASE_SUBJECT') + ' in ' + storeName;
                objCase.Description = mapConfig.get('GENERAL_CASE_DESCRIPTION') + ' in ' + storeName;

                lstCase.add(objCase);
            }            
    
            if (lstCase.size() > 0) UtilDatabase.insertRecords( lstCase,true); 
                
        } catch (Exception objEx) {
            String strErrorMessage = CLASS_NAME + ' ' + METHOD_NAME + ' LineNumber ' + objEx.getLineNumber() + ' Message: ' + objEx.getMessage();
            system.debug(' strErrorMessage ' + strErrorMessage);
            throw new UtilApplicationException(strErrorMessage);
        }
    }
   
  /**
   * @description Creates the buyer account
   * @param strAccount the account parameter to create
   * @param strContact the contact parameter to create
   * @return return true or false
   */
    public static String createUserContact(String strAccount, String strContact, String strUserType) {
        String METHOD_NAME = 'createUserContact';
        String strReturn = '';

        // system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' strAccount ' + strAccount);
        // system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' strContact ' + strContact);
        // system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' strUserType ' + strUserType);

        /*
         * I'll adjust this method to work with B2B and B2C configurations
         * since we need define an account to create an user in B2B definition
         * for now, I'll do just the B2C creation, but the B2B is already defined
         * when you get getSelfRegistrationConfigurations 
         */
        try {
            getSelfRegistrationConfigurations();

            if (strUserType == DEFAULT_B2B_USER_TYPE) {
                strReturn = createB2bUserContact(strAccount, strContact, strUserType);
            } else {
                strReturn = createPersonAccount(strContact, strUserType);
            }
        } catch (Exception objEx) {
            String strErrorMessage = CLASS_NAME + ' ' + METHOD_NAME + ' LineNumber ' + objEx.getLineNumber() + ' Message: ' + objEx.getMessage();
            system.debug(' strErrorMessage ' + strErrorMessage);
            throw new UtilApplicationException(strErrorMessage);
        }

        return strReturn;
    }


    private static String createPersonAccount(String strContact, String strUserType) {
        String METHOD_NAME = 'createPersonAccount';
        String strReturn = '';
        // system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' strContact ' + strContact);
        try {

            Contact objContact = (Contact)JSON.deserialize(strContact, Contact.class);
            // system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' objContact ' + objContact);
            // Get the recordType to create the person account
            // Id recordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Person_Account').getRecordTypeId();
            Id recordTypeId = [SELECT Id FROM RecordType WHERE IsPersonType = TRUE AND SObjectType='Account' LIMIT 1].Id;

            Account personAccount = new Account(RecordTypeId = recordTypeId);
            
            // for person accounts we can not update the Name field instead we have to update the    FirstName and LastName individually
            personAccount.FirstName = objContact.FirstName;
            personAccount.LastName = objContact.LastName;
            UtilDatabase.insertRecords(personAccount, true);
            // system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' personAccount ' + personAccount);

            objContact.AccountId = personAccount.Id;
            // Get the person contact ID created to this person account
            objContact.Id = String.valueOf([
                SELECT Id, PersonContactId FROM Account
                WHERE Id =: personAccount.Id
            ]?.PersonContactId);

            // system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' objContact ' + objContact);
            D2CSelfRegistrationHelper.SelfRegistrationReturn objConvert = registerUser(objContact, strUserType);
            system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' objConvert ' + objConvert);
            definePermissionset(String.valueOf(objConvert.userId), true);
            strReturn = jsonConversion(objConvert);            

        } catch (Exception objEx) {
            String strErrorMessage = CLASS_NAME + ' ' + METHOD_NAME + ' LineNumber ' + objEx.getLineNumber() + ' Message: ' + objEx.getMessage();
            system.debug(' strErrorMessage ' + strErrorMessage);
            throw new UtilApplicationException(strErrorMessage);
        }

        return strReturn;
    }

    @future
    private static void definePermissionset(String userId, Boolean isPersonAccount){
        string METHOD_NAME = 'definePermissionset';
        system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' userId ' + userId);

        try {
            // Get the configuration
            Map<String,String> mapPermission = new Map<String,String>();
            for (PermissionSet rowPerm : [
                SELECT Id, Name 
                FROM PermissionSet 
                WHERE Name IN ('Shopper_PSG' , 'B2BBuyer') LIMIT 1
            ]){
                mapPermission.put(rowPerm.Name, rowPerm.Id);
            }

            // Add the permission set to the user
            // "Shopper_PSG" is the "Shopper PSG" label used to person accounts
            // "B2BBuyer" is the "BBuyer" label used to contacts under an
            String permissionId = isPersonAccount ? mapPermission.get('Shopper_PSG')  : mapPermission.get('B2BBuyer');

            PermissionSetAssignment objPSA = new PermissionSetAssignment();
            objPSA.AssigneeId = userId;
            objPSA.PermissionSetId = permissionId;

            insert objPSA;
                
        } catch (Exception objEx) {
            String strErrorMessage = CLASS_NAME + ' ' + METHOD_NAME + ' LineNumber ' + objEx.getLineNumber() + ' Message: ' + objEx.getMessage();
            system.debug(' strErrorMessage ' + strErrorMessage);
            throw new UtilApplicationException(strErrorMessage);
        }
    }

    public static void createBuyerInformation(Map<String,Contact> mapContacts){
        string METHOD_NAME = 'createBuyerInformation';
        List<Account> lstAccount = new List<Account>();
        List<BuyerAccount> lstBuyerAccount = new List<BuyerAccount>();
        List<String> memberId = new List<String>();

        system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' mapContacts ' + mapContacts);

        try {
            // This account needs to be included in the Buyer group
            String buyerGoupId = getBuyerGoupId();
            system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' buyerGoupId ' + buyerGoupId);

            for (String contactId : mapContacts.keySet()){
                system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' contactId ' + contactId);
                //  SELECT Id, Name, BuyerId, BuyerStatus, IsActive, CreditLimit, CurrentBalance, AvailableCredit, SendToId, PayerId, CommerceType FROM BuyerAccount
                BuyerAccount objBuyerAccount = new BuyerAccount();
                String accountId = mapContacts.get(contactId).Account.Id ;
                system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' accountId ' + accountId);
                system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' Account.Name ' + mapContacts.get(contactId).Account.Name);
                objBuyerAccount.Name = mapContacts.get(contactId).Account.Name;
                objBuyerAccount.BuyerId = accountId;
                objBuyerAccount.IsActive = true;
                objBuyerAccount.CommerceType = 'Buyer';
                objBuyerAccount.BuyerStatus = 'Active';
    
                lstBuyerAccount.add(objBuyerAccount);

                memberId.add(accountId);

                Account objAccount = new Account(
                    Id = accountId,
                    isBuyerEnabled__c = true
                );

                lstAccount.add(objAccount);
            }

            if (lstBuyerAccount.size()>0) {UtilDatabase.insertRecords(lstBuyerAccount, true);}
            
            system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' lstBuyerAccount ' + lstBuyerAccount);

            if (lstAccount.size()>0) UtilDatabase.updateRecords(lstAccount, true);
            system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' lstAccount ' + lstAccount);

            // Since is necessary to add the members in another transaction
            // That will be done in a queueable process
            if (memberId.size()>0) System.enqueueJob(new D2CBuyerMemberQueueable(memberId));

            // Create a case if this configuration is enabled
            if (Boolean.valueOf(mapConfig.get('GENERAL_CASE_CREATION')) && lstBuyerAccount.size()>0 ) { createCase(mapContacts); }
               
        } catch (Exception objEx) {
            String strErrorMessage = CLASS_NAME + ' ' + METHOD_NAME + ' LineNumber ' + objEx.getLineNumber() + ' Message: ' + objEx.getMessage();
            system.debug(' strErrorMessage ' + strErrorMessage);
            throw new UtilApplicationException(strErrorMessage);
        }
    }

    private static string getBuyerGoupStoreName(){
        String METHOD_NAME = 'getBuyerGoupStoreName';

        String buyerGoupId = getBuyerGoupId();
        system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' buyerGoupId ' + buyerGoupId);
        String storeName = String.valueOf([
            SELECT Id, WebStoreId, WebStore.Name  
            FROM WebStoreBuyerGroup
            WHERE BuyerGroupId =: buyerGoupId
        ]?.WebStore.Name);
        
        system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' storeName ' + storeName);

        return storeName;
    }

    private static String getBuyerGoupId(){
        String METHOD_NAME = 'getBuyerGoupId';
        getSelfRegistrationConfigurations();
        // This account needs to be included in the Buyer group
        String buyerGoupId = String.valueOf([
            SELECT Id FROM BuyerGroup
            WHERE Name = :mapConfig.get('GENERAL_BUYER_GROUP')
            LIMIT 1
        ]?.Id);
        system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' buyerGoupId ' + buyerGoupId);

        return buyerGoupId;
    }

    public static void insertBuyerMember(List<String> memberId){
        String METHOD_NAME = 'insertBuyerMember';
        List<BuyerGroupMember> lstMember = new List<BuyerGroupMember>();

        // This account needs to be included in the Buyer group
        String buyerGoupId = getBuyerGoupId();
        system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' buyerGoupId ' + buyerGoupId);

        for (String accountId : memberId){
            system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' accountId ' + accountId);
            BuyerGroupMember objMember = new BuyerGroupMember(
                BuyerGroupId =  buyerGoupId,
                BuyerId = accountId
            );
    
            lstMember.add(objMember);    
        }

        system.debug(CLASS_NAME + ' ' + METHOD_NAME + ' lstMember ' + lstMember);
         UtilDatabase.insertRecords(lstMember, true);
    }

    private static string createB2bUserContact(String strAccount, String strContact, String strUserType) {
        String METHOD_NAME = 'createB2bUserContact';
        Account account;
        Contact contact;
        String strReturn = '';
        try {
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
            strReturn = jsonConversion(registerUser(contact, strUserType));
        } catch (Exception objEx) {
            String strErrorMessage = CLASS_NAME + ' ' + METHOD_NAME + ' LineNumber ' + objEx.getLineNumber() + ' Message: ' + objEx.getMessage();
            system.debug(' strErrorMessage ' + strErrorMessage);
            throw new UtilApplicationException(strErrorMessage);
        }

        return strReturn ;
    }    


    public class SelfRegistrationReturn{
        public Boolean isSuccess = false;
        public String accountId = '';
        public String contactId = '';
        public String errorMessage = '';
        public String userId = '';

        public SelfRegistrationReturn(Boolean isSuccess, String accountId , String contactId , String errorMessage, String userId){
            this.isSuccess = isSuccess;
            this.accountId = accountId;
            this.contactId = contactId;
            this.errorMessage = errorMessage;
            this.userId = userId;
        }

    }
}
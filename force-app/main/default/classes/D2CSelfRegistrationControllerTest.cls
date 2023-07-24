@IsTest
public class D2CSelfRegistrationControllerTest {

    @TestSetup
    static void createContact() {


        setUserRole();

        Account guestAccount = new Account(Name = 'B2B Guest Account');
        insert guestAccount;

        BuyerAccount buyerAccount = new BuyerAccount();
        buyerAccount.Name = guestAccount.Name;
        buyerAccount.BuyerId = guestAccount.Id;
        buyerAccount.IsActive = true;
        buyerAccount.CommerceType = 'Buyer';
        buyerAccount.BuyerStatus = 'Active';

        insert buyerAccount;


        Account accn = new Account(
            Name = 'Don John  ' +generateRandomString(5));
        insert accn;

        Account accn1 = new Account(
            Name = 'John Secada ' +generateRandomString(5));
        insert accn1;

        Contact con = new Contact();
        con.FirstName = 'con' ;
        con.LastName = generateRandomString(9);
        con.Email = 'tempmail1@tempmail.com';
        con.MailingStreet ='Ivy Chaselane';
        con.MailingCity='Atlanta';
        con.MailingState='Georgia';
        con.MailingPostalCode='30092';
        con.MailingCountry='US';
        con.AccountId = accn.Id;
        con.Phone = '1238887547';
        insert con;

        Contact con1 = new Contact();
        con1.FirstName = 'con1' ;
        con1.LastName = generateRandomString(10);
        con1.Email = 'tempmail2@tempmail.com';
        con1.MailingStreet ='Ivy Chaselane';
        con1.MailingCity='Atlanta';
        con1.MailingState='Georgia';
        con1.MailingPostalCode='30092';
        con1.MailingCountry='US';
        con1.AccountId = null;
        con1.Phone = '1238887548';
        insert con1;

        BuyerGroup buyergroupObj = new BuyerGroup(Name = 'Web Store');
        insert buyergroupObj;

        Profile profileId = [SELECT Id FROM Profile WHERE Name = 'Customer Community Plus Login User' LIMIT 1];

        User userObj = new User(
            Username = 'hmackenzie@raintree.co.uk.devgk1',
            LastName = 'Mackenzie1',
            FirstName = 'Hannah1',
            CompanyName = 'Capstone1',
            Division = 'Capstone International1',
            Department = 'Sales',
            Title = 'Account Manager',
            Street = 'Halley Court Jordan Hill',
            City = 'Oxford',
            PostalCode = 'OX2 8EJ',
            Country = 'United Kingdom',
            // CountryCode = 'GB',
            Email = 'hmackenzie@raintree.co.uk.invalid',
            EmailPreferencesAutoBcc = true,
            EmailPreferencesStayInTouchReminder = true,
            Alias = 'hmack1',
            CommunityNickname = 'hmackenzie1',
            TimeZoneSidKey = 'Europe/London',
            LocaleSidKey = 'en_IE_EURO',
            ReceivesInfoEmails = true,
            EmailEncodingKey = 'ISO-8859-1',
            ProfileId = profileId.Id,
            ContactId = con.Id,
            LanguageLocaleKey = 'en_US',
            UserPermissionsSFContentUser = true,
            UserPreferencesActivityRemindersPopup = true,
            UserPreferencesEventRemindersCheckboxDefault = true,
            UserPreferencesTaskRemindersCheckboxDefault = true,
            UserPreferencesHideChatterOnboardingSplash = true,
            UserPreferencesDisableLikeEmail = true,
            UserPreferencesSortFeedByComment = true,
            UserPreferencesShowTitleToExternalUsers = true,
            DigestFrequency = 'D',
            DefaultGroupNotificationFrequency = 'D'
        );
        insert userObj;
    }

    @IsTest
    public static void shouldEmailContactExistTestSuccess(){
        String email =[select email from contact limit 1].email;
        Test.startTest();
        String con= D2CSelfRegistrationController.isEmailContactExist(email);
        System.assert(!String.isEmpty(con),'string is empty');
        Test.stopTest();
    }

    @IsTest
    public static void shouldEmailContactExistTestFailed(){
        String email =null;
        Test.startTest();
        String con= D2CSelfRegistrationController.isEmailContactExist(email);
        System.assert((con!=null),'Result is not null');
        Test.stopTest();
    }

    @IsTest
    public static void shouldRegisterUserSuccessCommunity(){
        Contact contact = [SELECT Id, Email, FirstName, LastName, AccountId FROM Contact LIMIT 1];

        Test.startTest();
        Boolean isCreatedUser = D2CSelfRegistrationController.registerUser(contact);
        System.assert(isCreatedUser == true, 'Register is successful-registerUserSuccessNotAccount');
        Test.stopTest();
    }

    @IsTest
    public static void shouldRegisterUserSuccessCommunityLenghtLess4(){
        Contact contact = [SELECT Id, Email, FirstName, LastName, AccountId FROM Contact LIMIT 1];

        Test.startTest();
        Boolean isCreatedUser = D2CSelfRegistrationController.registerUser(contact);
        System.assert(isCreatedUser == true, 'Register is successful-registerUserSuccessNotAccount');
        Test.stopTest();
    }

    @IsTest
    public static void shouldCreateUserContactNoAccn(){
        // Contact contact = [SELECT Id, Email, FirstName, LastName FROM Contact LIMIT 1];
        Contact conTest = new Contact();
        conTest.FirstName = 'con3' ;
        conTest.LastName = generateRandomString(6);
        conTest.Email = 'tempmail3@tempmail.com';
        conTest.MailingStreet ='Ivy Chaselane';
        conTest.MailingCity='Atlanta';
        conTest.MailingState='Georgia';
        conTest.MailingPostalCode='30092';
        conTest.MailingCountry='US';
        conTest.AccountId = null;
        conTest.Phone = '1238887549';

        Test.startTest();
        Boolean isCreatedUserCon = D2CSelfRegistrationController.createUserContact(null, JSON.serialize(conTest));
        System.assert(isCreatedUserCon == true, 'Error on user and account creation');
        Test.stopTest();
    }

    @IsTest
    public static void shouldCreateUserContactWithAccn(){
        Account account = [SELECT Id, IsBuyer, Name FROM Account LIMIT 1];
        Contact contact = [SELECT Id, Email, FirstName, LastName FROM Contact LIMIT 1];
        contact.Id = null;
        contact.Email = 'no-dup' + contact.Email;
        contact.LastName = 'no-dup' + contact.LastName;

        Test.startTest();
        Boolean isCreatedUserCon = D2CSelfRegistrationController.createUserContact(JSON.serialize(account), JSON.serialize(contact));
        System.assert(isCreatedUserCon == true, 'Error on user and account creation');
        Test.stopTest();
    }

    @IsTest
    public static void shouldCreateAnotherContact(){
        Account account = [SELECT Id, IsBuyer, Name FROM Account LIMIT 1];
        Contact contact = [SELECT Id, Email, FirstName, LastName FROM Contact LIMIT 1];
        contact.Id = null;
        contact.Email = 'no-dup' + contact.Email;
        contact.LastName = 'no-dup' + contact.LastName;

        Test.startTest();
        Boolean isCreatedUserCon = D2CSelfRegistrationController.createUserContact(JSON.serialize(account), JSON.serialize(contact));
        System.assert(isCreatedUserCon == true, 'Error on user and account creation');
        Test.stopTest();
    }


    @IsTest
    public static void shouldCreateUserContactWithAccnNotBuyer(){
        Account account = [SELECT Id, IsBuyer, Name FROM Account WHERE IsBuyer = FALSE LIMIT 1];
        Contact contact = [SELECT Id, Email, FirstName, LastName, AccountId FROM Contact LIMIT 1];
        contact.Id = null;
        contact.Email = 'no-dup' + contact.Email;
        contact.LastName = 'no-dup' + contact.LastName;

        Test.startTest();
        Boolean isCreatedUserCon = D2CSelfRegistrationController.createUserContact(JSON.serialize(account), JSON.serialize(contact));
        System.assert(isCreatedUserCon == true, 'Error on user and account creation');
        Test.stopTest();
    }

  /**
   * @description generat a random string
   * @param len the length used in the string
   * @return return string
   */
    public static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr ='';
        while (randStr.length() < len) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx+1);
        }
        return randStr;
    }

  /**
   * @description set the current user role
   */
    public static void setUserRole(){
        // Set the user role
        String userRoleId = String.valueOf([
            SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName = 'CEO' LIMIT 1
        ]?.Id);
        USER testUser = [SELECT Id, UserRoleId FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
        testUser.UserRoleId = userRoleId;

        UPDATE testUser;
    }

}
import { LightningElement,api } from 'lwc';
import isEmailContactExist from '@salesforce/apex/D2CSelfRegistrationController.isEmailContactExist';
import createUserContact from '@salesforce/apex/D2CSelfRegistrationController.createUserContact';
import createBuyerInformation from '@salesforce/apex/D2CSelfRegistrationController.createBuyerInformation';
import { NavigationMixin } from 'lightning/navigation';

export default class d2cSelfRegistration extends NavigationMixin(LightningElement) {
    @api firstNameLabel;
    @api firstNamePlaceholder;
    @api lastNameLabel;
    @api lastNamePlaceholder;
    @api emailLabel;
    @api emailPlaceholder;
    // I'm just registering the B2C guys, since the B2B needs an account behind that
    // The structure is already created but I'll show how to to that in the future
    DEFAULT_B2C_USER_TYPE = 'B2C';
    hasError = false;
    errorMessage='';
    isLoading;
    firstName;
    lastName;
    email;
    showRegisterSuccessModal=false;

    contactList = [];
    isCreateContactUser = false;
    _isUserExists=false;
    @api
    get isUserExists() {
        return this._isUserExists;
    }
    _isUserExistsInactive=false;
    @api
    get isUserExistsInactive() {
        return this._isUserExistsInactive;
    }

    // Section Control
    _isShowFinalCheckBoxes = false;
    set isShowFinalCheckBoxes (value) {
        this._isShowFinalCheckBoxes = value;
    }
    isShowAddInstitution=false;
    isHiddenButtonContinue;

    _emailIsValid=false;
    handleUserEmailChange(event){
        this.email = event.target.value;
        // Validate email
        this._emailIsValid=false;
        let regex = new RegExp('[a-z0-9]+@[a-z]+.[a-z]{2,3}');

        if(regex.test(this.email)) this._emailIsValid=true;

        // Turn off the email exists since we are changing this value.
        this._isUserExists=false;
        this._isUserExistsInactive=false;
    }
       
    handleFirstNameChange(event){
        this.firstName = event.target.value;
    }
    handleLastNameChange(event){
        this.lastName = event.target.value;
    }

    @api
    get isContinueButtonDisabled() {
        return !(
            this.firstName?.length > 0 &&
            this.lastName?.length > 0 &&
            this._emailIsValid === true
        );
    }
    
    //click event button continue and check if email exists in contact list
    handleRegIsEmailExists() {
        this.isLoading = true;
        isEmailContactExist({
            email: this.email
        }).then((result) => {
            this.contactList = JSON.parse(result);
            this.isLoading = false;
            // If user is active, display message to have them reset their password.
            // If user exists, but not active, that means their account was shut down?  Contact Customer Service?
            // If contact exists, but no user account.  Keep track of contacts that could be enabled as users.
            this.contactHasUserActivated(this.contactList);
        }).catch((error) => {
            console.error(error);
            this.hasError = true;
            this.errorMessage = error.body.message;
            this.isLoading = false;
        });
    }


    handleNewUserCreation(){
        this.isLoading = true;
        this.hasError = false;
        this.errorMessage = '';
        // I'm letting this account variable here, to be handled if any customer 
        // changes the business rule and starts to apply custom registration with real account definition
        let accountObj = '';
        let newContactUser = {
            AccountId: '',
            FirstName: this.firstName,
            LastName: this.lastName,
            Email: this.email
        };
        this.showRegisterSuccessModal = false;

        createUserContact({
            strAccount: accountObj,
            strContact: JSON.stringify(newContactUser),
            strUserType: this.DEFAULT_B2C_USER_TYPE
        }).then(result => {
            console.log('d2cSelfRegistration handleNewUserCreation createUserContact ' + result);
            let parseReturn = JSON.parse(result);
            if (parseReturn.isSuccess) {
                return parseReturn;
            } else {
                this.isLoading = false;
                this.hasError = true;
                this.errorMessage = parseReturn.errorMessage;
                this.isLoading = false;
            }
        }).then(result => {
            this.isLoading = false;
            console.log('d2cSelfRegistration handleNewUserCreation createUserContact ' + result);
I NEED TO CALL THE OTHER METHOD HERE 
createBuyerInformation

            if (parseReturn.isSuccess) {
                
                return parseReturn;
                this.showRegisterSuccessModal = true;
            } else {
                this.isLoading = false;
                this.hasError = true;
                this.errorMessage = parseReturn.errorMessage;
                this.isLoading = false;
            }
        }).catch((error) => {
            console.error(error);
            this.hasError = true;
            this.errorMessage = error.body.message;
            this.isLoading = false;
        });    
    }


    //check if the users with that email address are already registered as user. If doesn't exist users, show account information and find by institution name and create user
    contactHasUserActivated(listCon) {
        listCon.forEach(element => {
            // if(element.Users){
            if(element){
                // I have found any records, already means that not will be possible to register
                this._isUserExists=true;
                this._emailIsValid=false;

                if (element.Users){
                    element.Users.records.forEach(e=>{
                        if(e.IsActive === false) {
                             this._isUserExistsInactive=true;
                             this._isUserExists=false;
                            return;
                        } 
                     })     
                }
            } else {
                // We found a contact that is not associated to a user, use during creation.
                // We may have found multiple contacts, we need to pick the associated one if they choose an account that exists.
                // This really doesn't matter as we are letting the user select their Account.
                //Display the next step.
                this.isHiddenButtonContinue=true;
            }
        });
        
        if (!listCon.length) {
            // No contact or user found, proceed regular
            // New contact, New user, assigned to selected account or 'Other' account if none selected.
            this.isCreateContactUser= true;// create contact and user with selected account
            this.isHiddenButtonContinue=true;
            this.handleNewUserCreation();
        }
    }
 
    goToForgotPassword(){
        this.goToCommunityPage('Forgot_Password');
    }

    goToHomePage() {
        this.goToCommunityPage('Home');
    }

    goToLoginPage(){
        this.goToCommunityPage('Login');
    }

    goToCommunityPage(pageName) {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: pageName
            }
        });
    }

}
import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation'

import getCreditCards from '@salesforce/apex/B2BPaymentMethodsController.getCardPaymentMethods';
import convertCartToOrder from '@salesforce/apex/B2BPaymentMethodsController.convertCartToOrder';
import processPayments from '@salesforce/apex/B2BPaymentMethodsController.processPayments';
import communityBasePath from '@salesforce/community/basePath';
import getCountryStatePicklists from '@salesforce/apex/B2BPaymentMethodsController.getCountryStatePicklists';
import updatePaymentMethod from '@salesforce/apex/B2BPaymentMethodsController.updatePaymentMethod';

import { CartSummaryAdapter } from 'commerce/cartApi'; 
import { getSessionContext } from 'commerce/contextApi';


const LABELS = {
    creditCards: 'Credit Cards',
    close: 'Close',
    newCreditCard: 'Add New Credit Card',
    areYouSureYouWanToDeleteThisCard: 'Are you sure you want to delete this Card?',
    cancel: 'Cancel',
    delete: 'Delete',
    save: 'Save',
    successfullyUpdated: 'Successfully updated',
    errorPleaseTryAgain: 'Error, please try again',
    successfullyDeleted: 'Successfully deleted',
    thereAreNoSavedCreditCardsYet: 'There are no saved credit cards yet'
}

export default class b2bCheckoutPayment extends NavigationMixin(LightningElement) {
    @wire(CartSummaryAdapter, {'cartStateOrId': 'active'})
    async wiredCartSummaryData(result) {
        if(result.data && result.data.cartId){
            this.recordId = result.data.cartId;
        }
    }

    @api
    checkoutMode = 1;

    @track data = [];
    @track currentRow = {};
    @track countryStateOptions = {};
    @track billingAddress = {
        country: '',
        street: '',
        city: '',
        state: '',
        postalCode: ''
    };


    recordId;
    effectiveAccountId = null;

    isEditMode = false;
    isLoading = false;
    dataFound = false;
    showError = false;
    processing = false;
    useShippingAddress = true;

    LABELS = LABELS;

    cardModalWindowId = 'newCardModal';
    selectedPaymentMethodId;
    errorMessage = '';


    get countryOptions() {
        let options = [];
        Object.keys(this.countryStateOptions).forEach(opt => {
            options.push({label: opt, value: opt});
        });

        return options.length ? options : null;
    }

    get stateOptions() {
        let options = [];

        if(this.billingAddress.country && this.countryStateOptions[this.billingAddress.country]) {
            this.countryStateOptions[this.billingAddress.country].forEach(state => {
                options.push({label: state, value: state});
            });
        }

        return options.length ?  options : null;
    }

    get options() {
        let options = [];
        this.data.forEach(item => {
            options.push({ label: `${item.DisplayCardNumber} (${item.CardType})`, value: item.Id });
        });

        return options;
    }

    handleSwitchAddress(event) {
        this.useShippingAddress = event.target.checked;
    }

    handleChangeAddress(event) {
        this.billingAddress.city = event.detail.city
        this.billingAddress.country = event.detail.country
        this.billingAddress.postalCode = event.detail.postalCode
        this.billingAddress.province = event.detail.province
        this.billingAddress.street = event.detail.street
    }

    // ============================ COMPONENT LIFECYCLE =================================
    async connectedCallback(){
        this.effectiveAccountId = await this.getEffectiveAccountId();
        this.getPicklistEntries();
        this.isLoading = true;
        await this.getPaymentMethods();
        this.isLoading = false;
    }

    @api
    get checkValidity() {
        if(!this.selectedPaymentMethodId) {
            this.showError = true;
            this.errorMessage  = 'Please, select payment method';
        } else {
            this.showError = false;
            this.errorMessage  = '';
        }
        return !this.showError;
    }
  
    @api
    reportValidity() {
        if(!this.selectedPaymentMethodId) {
            this.showError = true;
            this.errorMessage  = 'Please, select payment method';
        } else {
            this.showError = false;
            this.errorMessage  = '';
        }

        return !this.showError;
    }

    @api
    checkoutSave() {
      if (!this.checkValidity) {
        throw new 
          Error(
          'Payment method must be selected');
        }
    }
 
    @api
    async placeOrder() {
        this.isLoading = true;
        let paymentId = await this.processPayments();


        if(paymentId) {
            let summaryNumber = await this.convertCartToOrder(paymentId);

            if(summaryNumber != null) {
                window.location = `${communityBasePath}/order?orderNumber=${summaryNumber}`;
            } else {
                isSuccess = false;
            }
        }
        this.isLoading = false;
    }

    async processPayments() {
        await this.updatePaymentMethod();

        let { isSuccess, result, errorMessage } = await this.doRequest(
            processPayments, 
            {
                cardPaymentMethodId: this.selectedPaymentMethodId,
                webCartId:  this.recordId
            }
        );
        return result;
       
    }

    async updatePaymentMethod() {
        let { isSuccess, result, errorMessage } = await this.doRequest(
            updatePaymentMethod, 
            {
                cardPaymentMethodId: this.selectedPaymentMethodId,
                webCartId:  this.recordId,
                addressJSON: JSON.stringify(this.billingAddress),
                sameAsShipping: this.useShippingAddress
            }
        );
    }

    async convertCartToOrder(paymentId) {
        let { isSuccess, result, errorMessage } = await this.doRequest(
            convertCartToOrder, 
            {
                webCartId: this.recordId,
                cardPaymentMethodId:  this.selectedPaymentMethodId,
                paymentId: paymentId
            }
        );

        this.isLoading = false;
        if (isSuccess) {
            return result;
        }  else {
            return null;
        }
    }

    // ============================ HANDLERS ============================================
    handleSelectPaymentMethod(event){ 
        this.selectedPaymentMethodId = event.detail.value;
    }

    handleCardClose() {
        this.handleCloseModal(this.cardModalWindowId);
    }

    handleAddNewCard() {
        this.handleOpenModal(this.cardModalWindowId);
    }

    // ============================ MAIN LOGIC ==========================================

    handleOpenModal(modalComponentId) {
        this.template.querySelector("[data-id=" + modalComponentId + "]").openModal();
    }

    handleCloseModal(modalComponentId) {
        this.template.querySelector("[data-id=" + modalComponentId + "]").closeModal();
    }


    handleNewCardAdded() {
        this.handleCardClose();
        this.getPaymentMethods();
    }

    async getPaymentMethods() {
        let { isSuccess, result, errorMessage } = await this.doRequest(getCreditCards, 
            {
                accountId: this.effectiveAccountId
            }
        );
        if (isSuccess) {
            this.data = result || [];

            this.data.forEach(item => {
                item.expiryDate = item.ExpiryYear + '-' + (parseInt(item.ExpiryMonth) < 10 ? '0'+ item.ExpiryMonth : item.ExpiryMonth);
            })
            this.dataFound = this.data.length > 0;
        } else {
            console.error(responseMessage);
        }
    }

    async getPicklistEntries() {
        let { isSuccess, result, errorMessage } = await this.doRequest(getCountryStatePicklists, {});

        if(isSuccess) {
            this.countryStateOptions = result;
        }
    }

    doRequest(action, params) {
        this.showError = false;
        this.errorMessage = '';
        return new Promise((resolve, reject) => {
            action(params)
            .then(res => {
                resolve({
                    isSuccess: true,
                    result: res,
                    errorMessage: ''
                });
            })
            .catch(error => {
                console.error(error);
                let message = error.body.pageErrors && error.body.pageErrors.length ? error.body.pageErrors[0].message : error.body.message;
                try{
                    let errorObj = JSON.parse(message);
                    message = errorObj.message;
                } catch(e) {}

                this.showError = true;
                this.errorMessage = message;

                resolve({
                    isSuccess: false,
                    errorMessage: message
                });
            });
        });
    }

    async getEffectiveAccountId() {
        let result = null;
        await getSessionContext()
            .then((response) => {
                result = response.effectiveAccountId;
            })
            .catch((error) => {
                console.error(error);
            });
        return result;
    }
    
    navigateToUrl(url) {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: { url }
        });
    }
}

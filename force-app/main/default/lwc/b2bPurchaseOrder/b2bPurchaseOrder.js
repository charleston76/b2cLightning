import { LightningElement, api } from 'lwc';
/**
 * Pruchase Order Number is a mandatory field at checkout 
 * Place order should be blocked by this component when 
 * placed in the payment step before or after the payment component.
 * 
 * One page layout: this component may be placed in its own section 
 * before or after payment.
 *
 * Accordion layout: this component may be placed in its own section 
 * before the payment section.
 * 
 * Accordion layout: this component may be placed directly in the 
 * payment section before or after the payment component.
 */
export default class B2bPurchaseOrder extends LightningElement {
    @api
    errorMessage;
    @api
    placeHolder;
    purchaseOrderNumber = '';
    showError=false;

    /**
     * Required by checkout to register as a checkout component
     * 1 = EDIT mode
     */
    @api
    checkoutMode = 1;

    isValidPurchaseOrder(){
        console.log('isValidPurchaseOrder ', this.purchaseOrderNumber.trim() != '' && this.purchaseOrderNumber.length > 3);
        return this.purchaseOrderNumber.trim() != '' && this.purchaseOrderNumber.length > 3
    }

    handleChange(event) {
        this.purchaseOrderNumber = event.target.value;
    }

    /**
     * Report false and show the error message until the user accepts the Terms
     */
    @api
    get checkValidity() {
        console.log('checkValidity ');
        return this.isValidPurchaseOrder();
    }

    /**
     * Report false and show the error message until the pruchase order have being filled
     * purchaseOrderNumber has reportValidity functionality.
     * 
     * One-page Layout: reportValidity is triggered clicking place order.
     * 
     * Accordion Layout: reportValidity is triggered clicking each section's 
     * proceed button.
     *
     * @returns boolean
     */
    @api
    reportValidity() {
        let isValid = ! this.isValidPurchaseOrder();
        console.log('reportValidity isValid ', isValid);
        this.showError = isValid;
        console.log('reportValidity showError ', this.showError);
        return isValid;
    }    
 
}
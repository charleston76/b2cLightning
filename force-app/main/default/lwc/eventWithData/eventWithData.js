import { LightningElement, wire, api } from 'lwc';
import getContactList from '@salesforce/apex/ContactController.getContactList';
import EmployeePhotos from '@salesforce/resourceUrl/EmployeePhotos';

export default class EventWithData extends LightningElement {
    selectedContact;
    @api recordId;
    _imagePath = '';

    @wire(getContactList, { accountId: '$recordId' }) contacts;

    handleSelect(event) {
        const contactId = event.detail;
        this.selectedContact = this.contacts.data.find(
            (contact) => contact.Id === contactId
        );
        let firstName = this.selectedContact.FirstName ?? 'Sadie';
        this._imagePath = `${EmployeePhotos}` + '/' + firstName + '.png';
    }
}
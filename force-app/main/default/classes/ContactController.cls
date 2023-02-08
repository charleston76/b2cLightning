public with sharing class ContactController {
    @AuraEnabled(cacheable=true)
    public static List<Contact> getContactList(String accountId) {
        //Id convertedId = (Id)accountId;
        return [
            SELECT Id, Name, Title, Phone, Email, FirstName, LastName
            FROM Contact
            WHERE AccountId = :accountId
            WITH SECURITY_ENFORCED
            LIMIT 10
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Contact> findContacts(String searchKey) {
        String key = '%' + searchKey + '%';
        return [
            SELECT Id, Name, Title, Phone, Email, FirstName, LastName
            FROM Contact
            WHERE Name LIKE :key
            WITH SECURITY_ENFORCED
            LIMIT 10
        ];
    }

    @AuraEnabled(cacheable=true)
    public static Contact getSingleContact() {
        return [
            SELECT Id, Name, Title, Phone, Email, FirstName, LastName
            FROM Contact
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
    }
}
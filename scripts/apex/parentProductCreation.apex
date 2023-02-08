// The productset is saved in this objec
// SELECT Id, DeveloperName, MasterLabel, Description FROM ProductAttributeSet

// The productset item, that are the fields that make part of the product set
// are saved in this object
// SELECT Id, Field, Sequence, ProductAttributeSetId FROM ProductAttributeSetItem

// And the combination between the product set, and the products (parent variation in this example)
// are saved in this object
// SELECT Id, ProductAttributeSetId, Product.Name, ProductId  FROM ProductAttributeSetProduct


// Get the attibut set by developer name
String attributeSetName = 'Clothing_options';
String attributeSetId = String.valueof([
    SELECT Id FROM ProductAttributeSet
    WHERE DeveloperName =:attributeSetName
    LIMIT 1
    ]?.Id
);

system.debug('attributeSetId ' + attributeSetId);

// create the new attribute set, if that doesn't exist
if (String.isBlank(attributeSetId)){
    ProductAttributeSet newAttSet = new ProductAttributeSet(
        DeveloperName = 'Clothing_options', 
        Description = 'Clothing variation options ', 
        MasterLabel = 'Clothing options'
    );

    insert newAttSet;
}


//  SELECT Id, DeveloperName, Description, MasterLabel FROM ProductAttributeSet



// sfdx force:apex:execute -f scripts/apex/parentProductCreation.apex
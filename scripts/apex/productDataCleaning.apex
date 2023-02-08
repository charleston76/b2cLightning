// Remove the undesired products, for now
List<Product2> lstDelProd = [
    SELECT Id FROM Product2
];


system.debug('lstDelProd.size() ' + lstDelProd.size());
if (lstDelProd.size() > 0 ) delete lstDelProd;

// Remove the undesired categoris, for now
List<ProductCategory> lstDelCateg = [
    SELECT Id FROM ProductCategory
];

system.debug('lstDelCateg.size() ' + lstDelCateg.size());

if (lstDelCateg.size() > 0 ) delete lstDelCateg;

// sfdx force:apex:execute -f scripts/apex/productDataCleaning.apex
// Find the relation ship between the product and images
// and creates the media type thing
// This script just can be ran after the image importation, ensuring the relationship between the sku and the image title
String communityName = 'YOUR_COMMUNITY_NAME_HERE';
String communityId = 'YOUR_COMMUNITY_ID_HERE';
String webStoreId = 'YOUR_WEBSTORE_ID_HERE';

String contentType = '';
String language = 'en_US';
Integer pageSize = 100;
Integer pageNumber = 0;

String workspaceName = communityName + ' Workspace';
String productDetailImage = 'productDetailImage';
String productListImage = 'productListImage';
List<String> managedContentIds = new List<String>();
List<String> topicNames = new List<String>();
Map<String,String> mpaMediaGroupId = new Map<String,String>();
Map<String,Product2> mapProduct = new Map<String,Product2>();
Map<String,String> mapContentItem = new Map<String,String>();
List<String> buyerGroupIds = new List<String>();
List<String> entitlementPolicyIds = new List<String>();
List<String> entitlementProductIds = new List<String>();
List<ProductMedia> newProductMedia = new List<ProductMedia>();
Integer countMatchesFound = 0;

for (ElectronicMediaGroup rowGroup : [
    SELECT Id , DeveloperName FROM ElectronicMediaGroup
    WHERE DeveloperName IN : new List<String>{productDetailImage,productListImage}
    ORDER BY DeveloperName]){
    mpaMediaGroupId.put(rowGroup.DeveloperName, rowGroup.Id);
}

// System.debug('mpaMediaGroupId ' + mpaMediaGroupId);
// System.debug('community ' + communityName + ' - ' + communityId + ' webStoreId ' + webStoreId);

for (WebStoreBuyerGroup rowContent : [
    SELECT BuyerGroupId FROM WebStoreBuyerGroup
    WHERE WebStoreId =: webStoreId
    LIMIT :pageSize
]){
    buyerGroupIds.add(rowContent.BuyerGroupId);
}

// System.debug('buyerGroupIds ' + buyerGroupIds);

for (CommerceEntitlementBuyerGroup rowEntitlement : [
    SELECT PolicyId FROM CommerceEntitlementBuyerGroup
    WHERE BuyerGroupId IN :buyerGroupIds
    LIMIT :pageSize
]){
    entitlementPolicyIds.add(rowEntitlement.PolicyId);
}

// System.debug('entitlementPolicyIds ' + entitlementPolicyIds);

String workspaceId = String.valueOf([
    SELECT Id, Name FROM ManagedContentSpace
    WHERE Name =:workspaceName 
]?.Id);

// System.debug('workspace ' + workspaceName + ' - ' + workspaceId);

for (ManagedContent rowContent : [
    SELECT Id
    FROM ManagedContent WHERE AuthoredManagedContentSpaceId =:workspaceId
    LIMIT :pageSize
]){
    managedContentIds.add(rowContent.Id);
}

// System.debug('managedContentIds.size() ' + managedContentIds.size() );

// Call the API
ConnectApi.ManagedContentVersionCollection contentCollection = ConnectApi.ManagedContent.getManagedContentByTopicsAndIds(communityId, managedContentIds, topicNames, pageNumber, pageSize, language, contentType);
// System.debug('contentCollection ' + contentCollection );
List<ConnectApi.ManagedContentVersion> lstContentItems = contentCollection.items;
// System.debug('lstContentItems ' + lstContentItems );

for (ConnectApi.ManagedContentVersion rowVersion : lstContentItems){
    // system.debug('rowVersion ' + rowVersion);
    // system.debug('rowVersion.contentKey ' + rowVersion.contentKey);
    // system.debug('rowVersion.title ' + rowVersion.title);
    // system.debug('rowVersion.managedContentId ' + rowVersion.managedContentId);
    mapContentItem.put(rowVersion.title, rowVersion.managedContentId);
}

// System.debug('mapContentItem ' + mapContentItem );

// Check the products that are in the right entitlement policies
for (CommerceEntitlementProduct objRow : [
    SELECT ProductId FROM CommerceEntitlementProduct
    WHERE PolicyId IN : entitlementPolicyIds
    LIMIT :pageSize]){
    entitlementProductIds.add(objRow.ProductId);
}

// System.debug('entitlementProductIds ' + entitlementProductIds );


// Create a map to related the images by the StockKeepingUnit and the title
for (Product2 objRow : [
    SELECT StockKeepingUnit, Id, Name, ProductCode, IsActive, Type 
    FROM Product2 
    WHERE StockKeepingUnit != NULL
    AND   Id IN : entitlementProductIds
    AND   IsActive = true
    AND   Id NOT IN (SELECT ProductId FROM ProductMedia)
    LIMIT :pageSize]){
    mapProduct.put(objRow.StockKeepingUnit, objRow);
}

// System.debug('mapProduct ' + mapProduct );

// Verify the products and try to findout the images in the map
for (String stockKeepingUnit : mapProduct.keySet()){
    if (mapContentItem.containsKey(stockKeepingUnit)){
        // System.debug(mapContentItem.get(stockKeepingUnit));
        // add the product product detail image
        newProductMedia.add(
            new ProductMedia(
                ProductId = mapProduct.get(stockKeepingUnit).Id,
                ElectronicMediaId = mapContentItem.get(stockKeepingUnit),
                ElectronicMediaGroupId = mpaMediaGroupId.get(productDetailImage)
            )
        );
        // add the product product list image
        newProductMedia.add(
            new ProductMedia(
                ProductId = mapProduct.get(stockKeepingUnit).Id,
                ElectronicMediaId = mapContentItem.get(stockKeepingUnit),
                ElectronicMediaGroupId = mpaMediaGroupId.get(productListImage)
            )
        );

        countMatchesFound++;
    } else{
        System.debug('does not contain stockKeepingUnit ' + stockKeepingUnit);
    }
}

// System.debug('countMatchesFound ' + countMatchesFound );
System.debug('newProductMedia.size() ' + newProductMedia.size() );
if (newProductMedia.size() > 0) insert newProductMedia;

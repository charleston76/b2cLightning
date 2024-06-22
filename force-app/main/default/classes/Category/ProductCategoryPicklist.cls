public with sharing class ProductCategoryPicklist extends VisualEditor.DynamicPickList {
    List<String> sObjects = new List<String>();

    public ProductCategoryPicklist() {
        this.sObjects = getSObjects();
    }

    public override VisualEditor.DynamicPickListRows getValues() {
        VisualEditor.DynamicPickListRows values = new VisualEditor.DynamicPickListRows();
        for (String sobj : sObjects) {
            VisualEditor.DataRow tempVal = new VisualEditor.DataRow(sobj, sobj);
            values.addRow(tempVal);
        }
        return values;
    }

    public override VisualEditor.DataRow getDefaultValue(){
        return new VisualEditor.DataRow(sObjects[0], sObjects[0]);
    }

    @AuraEnabled
    public static String getProductCategoryIdByName(String categoryName) {
        return[SELECT Id FROM ProductCategory WHERE Name = :categoryName LIMIT 1].Id;
    }

    private List<String> getSObjects() {
        Set<String> sobjects = new Set<String>();
        for (ProductCategory prodCat : queryProductCategory()) {
            sobjects.add(prodCat.Name);
        }
        return new List<String>(sobjects);
    }

    private List<ProductCategory> queryProductCategory() {
        return [SELECT Id, Name FROM ProductCategory];
    }
}
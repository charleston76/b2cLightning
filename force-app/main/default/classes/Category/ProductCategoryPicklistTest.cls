@isTest
public class ProductCategoryPicklistTest {

    @testSetup
    static void setup() {
        ProductCatalog catlog = new ProductCatalog();
        catlog.Name = 'Catalog01';
        insert catlog;

        ProductCategory prodCat01 = new ProductCategory();
        prodCat01.Name = 'ProductCategory01';
        prodCat01.CatalogId = catlog.Id;
        insert prodCat01;

        ProductCategory prodCat02 = new ProductCategory();
        prodCat02.Name = 'ProductCategory02';
        prodCat02.CatalogId = catlog.Id;
        insert prodCat02;
    }

    @isTest
    static void testValues() {
        Test.startTest();
        VisualEditor.DynamicPickListRows expectedValues = new VisualEditor.DynamicPickListRows();

        List<String> mockCategories = new List<String>();
        mockCategories.add('ProductCategory01');
        mockCategories.add('ProductCategory02');

        for (String category : mockCategories) {
            VisualEditor.DataRow row = new VisualEditor.DataRow(category, category);
            expectedValues.addRow(row);
        }

        ProductCategoryPicklist picklist = new ProductCategoryPicklist();

        Test.stopTest();
        Assert.areEqual(expectedValues.containsAllRows(), picklist.getValues().containsAllRows(), 'Expected: ' + expectedValues.containsAllRows() + ' Result: ' + picklist.getValues().containsAllRows());
    }

    @isTest
    static void testDefaultValue() {
        Test.startTest();
        ProductCategoryPicklist picklist = new ProductCategoryPicklist();

        List<String> mockCategories = new List<String>();
        mockCategories.add('ProductCategory01');

        VisualEditor.DataRow data = new VisualEditor.DataRow(mockCategories[0], mockCategories[0]);

        Test.stopTest();
        Assert.areEqual(data.isSelected(), picklist.getDefaultValue().isSelected(), 'Expected: ' + data.isSelected() + ' Result: ' + picklist.getDefaultValue().isSelected());
    }

    @isTest
    static void testGetProductCategoryIdByName() {
        Test.startTest();

        String categoryId = ProductCategoryPicklist.getProductCategoryIdByName('ProductCategory01');
        Test.stopTest();
        Assert.isNotNull(categoryId);
    }
}
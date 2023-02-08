/*
 * Copyright (c) 2020, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

global with sharing class menusManagerController {
    
    @AuraEnabled(cacheable=true)
    public static String getMenus()
    {
        Map<String,Object> resultMap = new Map<String,Object>();
        try {
            if(Menu__c.sObjectType.getDescribe().isAccessible()
                && Schema.sObjectType.Menu__c.fields.Name.isAccessible()
            )
            {
                List<Menu__c> menuList = [SELECT Id, Name FROM Menu__c ORDER BY Name LIMIT 100];
                resultMap.put('menuList', menuList);
            }
            else 
            {
                resultMap.put('error', 'CRUD or FLS checks failed on the Menu object. Please review the user\'s permissions.');
            }
        }
        catch(Exception e) {
            resultMap.put('error', e+'');
        }
        return System.JSON.serialize(resultMap);
    }

    @AuraEnabled
    global static String deleteMenu(Id menuId)
    {
        String result = 'success';
        try {
            if(Menu__c.sObjectType.getDescribe().isDeletable())
            {
                List<Menu_Item__c> menuItemList = [SELECT Id FROM Menu_Item__c WHERE Menu__c = :menuId];
                delete menuItemList;
                Menu__c menu = new Menu__c(Id=menuId);
                delete menu;
            }
            else 
            {
                result = 'CRUD checks failed on the Menu object. Please review the user\'s permissions.';
            }
        } catch(Exception e) {
            result = e+'';
        }
        return result;
    }

    @AuraEnabled(cacheable=true)
    global static String getMenu(String menuId, String language)
    {
        Map<String,Object> resultMap = new Map<String,Object>();
        List<treeItem> listTOCLevel1 = new List<treeItem>();

        try {
            if(Menu__c.sObjectType.getDescribe().isAccessible() && Menu_Item__c.sObjectType.getDescribe().isAccessible()
                && Schema.sObjectType.Menu__c.fields.Name.isAccessible()
                && checkMenuItemsFLSisAccessible()
            )
            {
                Boolean expanded = false;
                Map<Id,Menu_Item__c>  tocMap = queryMenu(menuId, language);

                listTOCLevel1 = populateTreeItemsByParent(tocMap, expanded);
                resultMap.put('itemsList',listTOCLevel1);
                resultMap.put('itemsMap',tocMap);
            }
            else 
            {
                resultMap.put('error', 'CRUD or FLS checks failed on the Menu and/or Menu Item object(s). Please review the user\'s permissions.');
            }

        } catch(Exception e){
            resultMap.put('error', e+'');
        }

        return System.JSON.serialize(resultMap).replaceAll('"items"','"_children"');
    }

    @AuraEnabled
    global static String deleteMenuItem(Id menuItemId)
    {
        String result = 'success';
        try {
            if(Menu_Item__c.sObjectType.getDescribe().isAccessible()
                && Menu_Item__c.sObjectType.getDescribe().isDeletable())
            {
                List<Menu_Item__c> menuItemList = [SELECT Id FROM Menu_Item__c WHERE 
                Id =: menuItemId OR Menu_Item__c = :menuItemId OR Menu_Item__r.Menu_Item__c = :menuItemId
                OR Menu_Item__r.Menu_Item__r.Menu_Item__c  = :menuItemId 
                OR Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__c = :menuItemId
                OR Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__c = :menuItemId 
                OR Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__c  = :menuItemId];
                delete menuItemList;
            } 
            else 
            {
                result = 'CRUD checks failed on the Menu Item object. Please review the user\'s permissions.';
            }
        } catch(Exception e) {
            result = e+'';
        }
        return result;
    }

    @AuraEnabled(cacheable=true)
    global static String getLanguages()
    {
        List<String> languageList = new List<String>();
        if(Menu_Item__c.sObjectType.getDescribe().isAccessible() 
            && Schema.sObjectType.Menu_Item__c.fields.Language__c.isAccessible())
        {
            languageList.add('none');
            Schema.DescribeFieldResult F = Menu_Item__c.Language__c.getDescribe();
            Schema.sObjectField T = F.getSObjectField();
            List<PicklistEntry> entries = T.getDescribe().getPicklistValues();
            for(PicklistEntry pe : entries)
            {
                languageList.add(pe.getValue());
            }
        }
        return System.JSON.serialize(languageList);
    }

    @AuraEnabled 
    global static String importMenu(String menuJSON)
    {
        Savepoint sp = Database.setSavepoint();
        Map<String,String> resultMap = new Map<String,String>();
        try {

            if(Menu__c.sObjectType.getDescribe().isCreateable() && Menu_Item__c.sObjectType.getDescribe().isCreateable()
                && Schema.sObjectType.Menu__c.fields.Name.isCreateable()
                && checkMenuItemsFLSisCreateable()
            )
            {
                Map<String,Object> menuMap = (Map<String,Object>)System.JSON.deserializeUntyped(menuJSON);
                String menuName = (String)menuMap.get('name');
                menuName = (menuName != null && menuName.trim() != '') ? menuName : 'NoName - ' + System.now().getTime(); 

                Menu__c menu = new Menu__c(Name=menuName);
                insert menu;

                Object children = (Object)menuMap.get('_children');
                String childrenJSON = System.JSON.serialize(children);
                childrenJSON = childrenJSON.replaceAll('"_children"','"items"');

                List<treeItem> treeItemList = (List<treeItem>)System.JSON.deserialize(childrenJSON, List<treeItem>.class);
                createMenuItems(menu.Id, treeItemList);
                resultMap.put('menuId', menu.Id);
                resultMap.put('error', '');
            }
            else 
            {
                resultMap.put('error', 'CRUD or FLS checks failed on the Menu and/or Menu Item object(s). Please review the user\'s permissions.');
            }

        } catch(Exception e) {
            Database.rollback(sp);
            resultMap.put('error', e+'');
        }

        return System.JSON.serialize(resultMap);
    }

    private static Map<Id,Menu_Item__c> queryMenu(String menuId, String language)
    {
        language = (language == null || language.trim() == '') ? null : language;

        String fields = 'SELECT Id, Name, URL__c, Menu_Path__c, Open_in_New_Window__c, Position__c, Menu_Item_Type__c, Menu_Item_Style__c, Menu_Item_Marketing_Image__c,';
        fields += 'Public__c,SLDS_Icon__c,SLDS_Icon_Position__c,Language__c,Menu_Item__c, Menu_Item__r.Menu_Item__c,';
        fields += 'Menu_Item__r.Menu_Item__r.Menu_Item__c, Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__c,';
        fields += 'Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__c,';
        fields += 'Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__c ';

        String query = fields;
        query += 'FROM Menu_Item__c WHERE Menu__c = :menuId';
        query += (language != null) ? ' AND (Language__c includes (\'' + language + '\'))' : '';
        query += ' ORDER BY Menu_Path__c ASC';

        Map<Id, Menu_Item__c> miMap = new Map<Id, Menu_Item__c>(
            (List<Menu_Item__c>)Database.query(query)
            );

        

        if(language != null)
        {
            Set<Id> miIdSet = new Set<Id>();

            for(Menu_Item__c mi : miMap.values())
            {
                miIdSet.add(mi.Id);
                if(mi.Menu_Item__c != null)
                {
                    miIdSet.add(mi.Menu_Item__c);
                    if(mi.Menu_Item__r.Menu_Item__c != null)
                    {
                        miIdSet.add(mi.Menu_Item__r.Menu_Item__c);
                        if(mi.Menu_Item__r.Menu_Item__r.Menu_Item__c != null)
                        {
                            miIdSet.add(mi.Menu_Item__r.Menu_Item__r.Menu_Item__c);
                            if(mi.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__c != null)
                            {
                                miIdSet.add(mi.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__c);
                                if(mi.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__c != null)
                                {
                                    miIdSet.add(mi.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__c);
                                    if(mi.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__c != null)
                                    {
                                        miIdSet.add(mi.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__c);
                                    }
                                }
                            }
                        }
                    }
                }   
            }
            
            String query2 = fields;
            query2 += 'FROM Menu_Item__c WHERE Menu__c = :menuId';
            query2 += ' AND Id IN :miIdSet';
            query2 += ' ORDER BY Menu_Path__c ASC';

            miMap = new Map<Id, Menu_Item__c>(
                (List<Menu_Item__c>)Database.query(query2)
                );

        }

        return miMap;
    }

    private static List<treeItem> populateTreeItemsByParent(Map<Id,Menu_Item__c> tocMap, Boolean expanded)
    {
        
        Map<String,treeItem> treeItemMapTop = new Map<String,treeItem>();
        Map<String,treeItem2> treeItemMapLevel2 = new Map<String,treeItem2>();
        Map<String,treeItem3> treeItemMapLevel3 = new Map<String,treeItem3>();
        Map<String,treeItem4> treeItemMapLevel4 = new Map<String,treeItem4>();
        Map<String,treeItem5> treeItemMapLevel5 = new Map<String,treeItem5>();
        Map<String,treeItem6> treeItemMapLevel6 = new Map<String,treeItem6>();

        for(Menu_Item__c toc : tocMap.values())
        {

            if(toc.Menu_Item__c == null) //toplevel
            {
                treeItem ti = createTreeItem(toc, expanded);
                treeItemMapTop.put(toc.Id, ti);
                
            }
            else if(toc.Menu_Item__r.Menu_Item__c == null) //1 level down
            {
                treeItem2 ti2 = createTreeItem2(toc, expanded);
                
                treeItem ti = treeItemMapTop.get(toc.Menu_Item__c);
                ti = (ti == null) ? createTreeItem(tocMap.get(toc.Menu_Item__c), expanded) : ti;
                ti.itemsMap.put(ti2.id, ti2);
                ti.items = ti.itemsMap.values();
                

                treeItemMapTop.put(toc.Menu_Item__c, ti);
                treeItemMapLevel2.put(toc.Id,ti2);
            }
            else if(toc.Menu_Item__r.Menu_Item__r.Menu_Item__c == null) //2 levels down
            {
                treeItem3 ti3 = createTreeItem3(toc, expanded);
                
                treeItem2 ti2 = treeItemMapLevel2.get(toc.Menu_Item__c);
                ti2 = (ti2 == null) ? createTreeItem2(tocMap.get(toc.Menu_Item__c), expanded) : ti2;
                ti2.itemsMap.put(ti3.id, ti3);
                ti2.items = ti2.itemsMap.values();

                treeItem ti = treeItemMapTop.get(toc.Menu_Item__r.Menu_Item__c);
                ti = (ti == null) ? createTreeItem(tocMap.get(toc.Menu_Item__r.Menu_Item__c), expanded) : ti;
                ti.itemsMap.put(ti2.id, ti2);
                ti.items = ti.itemsMap.values();

                treeItemMapTop.put(toc.Menu_Item__r.Menu_Item__c, ti);
                treeItemMapLevel2.put(toc.Menu_Item__c,ti2);
                treeItemMapLevel3.put(toc.Id,ti3);
            }
            else if(toc.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__c == null) //3 levels down
            {
                treeItem4 ti4 = createTreeItem4(toc, expanded);
                
                treeItem3 ti3 = treeItemMapLevel3.get(toc.Menu_Item__c);
                ti3 = (ti3 == null) ? createTreeItem3(tocMap.get(toc.Menu_Item__c), expanded) : ti3;
                ti3.itemsMap.put(ti4.id, ti4);
                ti3.items = ti3.itemsMap.values();

                treeItem2 ti2 = treeItemMapLevel2.get(toc.Menu_Item__r.Menu_Item__c);
                ti2 = (ti2 == null) ? createTreeItem2(tocMap.get(toc.Menu_Item__r.Menu_Item__c), expanded) : ti2;
                ti2.itemsMap.put(ti3.id, ti3);
                ti2.items = ti2.itemsMap.values();

                treeItem ti = treeItemMapTop.get(toc.Menu_Item__r.Menu_Item__r.Menu_Item__c);
                ti = (ti == null) ? createTreeItem(tocMap.get(toc.Menu_Item__r.Menu_Item__r.Menu_Item__c), expanded) : ti;
                ti.itemsMap.put(ti2.id, ti2);
                ti.items = ti.itemsMap.values();

                treeItemMapTop.put(toc.Menu_Item__r.Menu_Item__r.Menu_Item__c, ti);
                treeItemMapLevel2.put(toc.Menu_Item__r.Menu_Item__c, ti2);
                treeItemMapLevel3.put(toc.Menu_Item__c,ti3);
                treeItemMapLevel4.put(toc.Id,ti4);
            }
            else if(toc.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__c == null) //4 levels down
            {
                treeItem5 ti5 = createTreeItem5(toc, expanded);
                
                treeItem4 ti4 = treeItemMapLevel4.get(toc.Menu_Item__c);
                ti4 = (ti4 == null) ? createTreeItem4(tocMap.get(toc.Menu_Item__c), expanded) : ti4;
                ti4.itemsMap.put(ti5.id, ti5);
                ti4.items = ti4.itemsMap.values();

                treeItem3 ti3 = treeItemMapLevel3.get(toc.Menu_Item__r.Menu_Item__c);
                ti3 = (ti3 == null) ? createTreeItem3(tocMap.get(toc.Menu_Item__r.Menu_Item__c), expanded) : ti3;
                ti3.itemsMap.put(ti4.id, ti4);
                ti3.items = ti3.itemsMap.values();

                treeItem2 ti2 = treeItemMapLevel2.get(toc.Menu_Item__r.Menu_Item__r.Menu_Item__c);
                ti2 = (ti2 == null) ? createTreeItem2(tocMap.get(toc.Menu_Item__r.Menu_Item__r.Menu_Item__c), expanded) : ti2;
                ti2.itemsMap.put(ti3.id, ti3);
                ti2.items = ti2.itemsMap.values();

                treeItem ti = treeItemMapTop.get(toc.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__c);
                ti = (ti == null) ? createTreeItem(tocMap.get(toc.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__c), expanded) : ti;
                ti.itemsMap.put(ti2.id, ti2);
                ti.items = ti.itemsMap.values();

                treeItemMapTop.put(toc.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__c, ti);
                treeItemMapLevel2.put(toc.Menu_Item__r.Menu_Item__r.Menu_Item__c, ti2);
                treeItemMapLevel3.put(toc.Menu_Item__r.Menu_Item__c, ti3);
                treeItemMapLevel4.put(toc.Menu_Item__c,ti4);
                treeItemMapLevel5.put(toc.Id,ti5);
            }
            else if(toc.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__c == null) //5 levels down
            {
                treeItem6 ti6 = createTreeItem6(toc, expanded);
                
                treeItem5 ti5 = treeItemMapLevel5.get(toc.Menu_Item__c);
                ti5 = (ti5 == null) ? createTreeItem5(tocMap.get(toc.Menu_Item__c), expanded) : ti5;
                ti5.itemsMap.put(ti6.id, ti6);
                ti5.items = ti5.itemsMap.values();

                treeItem4 ti4 = treeItemMapLevel4.get(toc.Menu_Item__r.Menu_Item__c);
                ti4 = (ti4 == null) ? createTreeItem4(tocMap.get(toc.Menu_Item__r.Menu_Item__c), expanded) : ti4;
                ti4.itemsMap.put(ti5.id, ti5);
                ti4.items = ti4.itemsMap.values();

                treeItem3 ti3 = treeItemMapLevel3.get(toc.Menu_Item__r.Menu_Item__r.Menu_Item__c);
                ti3 = (ti3 == null) ? createTreeItem3(tocMap.get(toc.Menu_Item__r.Menu_Item__r.Menu_Item__c), expanded) : ti3;
                ti3.itemsMap.put(ti4.id, ti4);
                ti3.items = ti3.itemsMap.values();

                treeItem2 ti2 = treeItemMapLevel2.get(toc.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__c);
                ti2 = (ti2 == null) ? createTreeItem2(tocMap.get(toc.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__c), expanded) : ti2;
                ti2.itemsMap.put(ti3.id, ti3);
                ti2.items = ti2.itemsMap.values();

                treeItem ti = treeItemMapTop.get(toc.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__c);
                ti = (ti == null) ? createTreeItem(tocMap.get(toc.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__c), expanded) : ti;
                ti.itemsMap.put(ti2.id, ti2);
                ti.items = ti.itemsMap.values();

                treeItemMapTop.put(toc.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__c, ti);
                treeItemMapLevel2.put(toc.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__c, ti2);
                treeItemMapLevel3.put(toc.Menu_Item__r.Menu_Item__r.Menu_Item__c, ti3);
                treeItemMapLevel4.put(toc.Menu_Item__r.Menu_Item__c, ti4);
                treeItemMapLevel5.put(toc.Menu_Item__c,ti5);
                treeItemMapLevel6.put(toc.Id,ti6);
            }

        }


        return treeItemMapTop.values();

    }

    private static void createMenuItems(String menuId, List<treeItem> treeItemList)
    {
        List<Menu_Item__c> miList1 = new List<Menu_Item__c>();
        List<Menu_Item__c> miList2 = new List<Menu_Item__c>();
        List<Menu_Item__c> miList3 = new List<Menu_Item__c>();
        List<Menu_Item__c> miList4 = new List<Menu_Item__c>();
        List<Menu_Item__c> miList5 = new List<Menu_Item__c>();
        List<Menu_Item__c> miList6 = new List<Menu_Item__c>();
        
        for(treeItem ti :  treeItemList)
        {
            ti.id = ti.label + '-' + System.now().getTime();
            ti.id = ti.id.replace(' ','-');
            Menu_Item__c mi = createMenuItem(ti, menuId, null);
            miList1.add(mi);

            if(ti.items != null)
            {
                for(treeItem2 ti2 : ti.items)
                {
                    ti2.id = ti2.label + '-' + System.now().getTime();
                    ti2.id = ti2.id.replace(' ','-');
                    Menu_Item__c mi2 = createMenuItem2(ti2, menuId, ti.id);
                    miList2.add(mi2);

                    if(ti2.items != null)
                    {
                        for(treeItem3 ti3 : ti2.items)
                        {
                            ti3.id = ti3.label + '-' + System.now().getTime();
                            ti3.id = ti3.id.replace(' ','-');
                            Menu_Item__c mi3 = createMenuItem3(ti3, menuId, ti2.id);
                            miList3.add(mi3);

                            if(ti3.items != null)
                            {
                                for(treeItem4 ti4 : ti3.items)
                                {
                                    ti4.id = ti4.label + '-' + System.now().getTime();
                                    ti4.id = ti4.id.replace(' ','-');
                                    Menu_Item__c mi4 = createMenuItem4(ti4, menuId, ti3.id);
                                    miList4.add(mi4);

                                    if(ti4.items != null)
                                    {
                                        for(treeItem5 ti5 : ti4.items)
                                        {
                                            ti5.id = ti5.label + '-' + System.now().getTime();
                                            ti5.id = ti5.id.replace(' ','-');
                                            Menu_Item__c mi5 = createMenuItem5(ti5, menuId, ti4.id);
                                            miList5.add(mi5);

                                            if(ti5.items != null)
                                            {
                                                for(treeItem6 ti6 : ti5.items)
                                                {
                                                    ti6.id = ti6.label + '-' + System.now().getTime();
                                                    ti6.id = ti6.id.replace(' ','-');
                                                    Menu_Item__c mi6 = createMenuItem6(ti6, menuId, ti5.id);
                                                    miList6.add(mi6);
                                                }
                                            } 
                                            
                                        }
                                    } 
                                    
                                }
                            } 
                            
                        }
                    } 

                }
            }    
        }

        insert miList1;
        insert miList2;
        insert miList3;
        insert miList4;
        insert miList5;
        insert miList6;

    }

    private static Menu_Item__c createMenuItem(treeItem ti, String menuId, String parentMenuItemExtId)
    {
        Menu_Item__c parentMenuItem = (parentMenuItemExtId != null) ? new Menu_Item__c(External_Id__c=parentMenuItemExtId) : null; 

        Menu_Item__c mi = new Menu_Item__c();
        mi.Name = ti.label;
        mi.Menu__c = menuId;
        mi.URL__c = (ti.href != null) ? ti.href : 'javascript:void(0);';
        mi.SLDS_Icon__c = ti.icon;
        mi.SLDS_Icon_Position__c = (ti.iconPosition != null) ? ti.iconPosition : 'left';
        mi.Position__c = ti.position;
        mi.Menu_Item__r = (parentMenuItem != null) ? parentMenuItem: null ;
        mi.Open_in_New_Window__c = ti.openInNewWindow != null && ti.openInNewWindow == 'Yes';
        mi.Public__c = ti.isPublic != null && ti.isPublic == 'Yes';
        mi.Language__c = ti.language;
        mi.External_Id__c = (ti.id != null ) ? ti.id : null;
        mi.Menu_Item_Type__c =(ti.menuItemType != null ? ti.menuItemType : null );
        mi.Menu_Item_Style__c =(ti.menuItemStyle != null ? ti.menuItemStyle : null );
        mi.Menu_Item_Marketing_Image__c = (ti.menuItemMarketingImage != null ? ti.menuItemMarketingImage : null );
        
        return mi;
    }

    private static Menu_Item__c createMenuItem2(treeItem2 ti, String menuId, String parentMenuItemExtId)
    {
        Menu_Item__c parentMenuItem = (parentMenuItemExtId != null) ? new Menu_Item__c(External_Id__c=parentMenuItemExtId) : null;

        Menu_Item__c mi = new Menu_Item__c();
        mi.Name = ti.label;
        mi.Menu__c = menuId;
        mi.URL__c = (ti.href != null) ? ti.href : 'javascript:void(0);';
        mi.SLDS_Icon__c = ti.icon;
        mi.SLDS_Icon_Position__c = (ti.iconPosition != null) ? ti.iconPosition : 'left';
        mi.Position__c = ti.position;
        mi.Menu_Item__r = (parentMenuItem != null) ? parentMenuItem: null ;
        mi.Open_in_New_Window__c = ti.openInNewWindow != null && ti.openInNewWindow == 'Yes';
        mi.Public__c = ti.isPublic != null && ti.isPublic == 'Yes';
        mi.Language__c = ti.language;
        mi.External_Id__c = (ti.id != null ) ? ti.id : null;
        mi.Menu_Item_Type__c =(ti.menuItemType != null ? ti.menuItemType : null );
        mi.Menu_Item_Style__c =(ti.menuItemStyle != null ? ti.menuItemStyle : null );
        mi.Menu_Item_Marketing_Image__c = (ti.menuItemMarketingImage != null ? ti.menuItemMarketingImage : null );
        return mi;
    }

    private static Menu_Item__c createMenuItem3(treeItem3 ti, String menuId, String parentMenuItemExtId)
    {
        Menu_Item__c parentMenuItem = (parentMenuItemExtId != null) ? new Menu_Item__c(External_Id__c=parentMenuItemExtId) : null;

        Menu_Item__c mi = new Menu_Item__c();
        mi.Name = ti.label;
        mi.Menu__c = menuId;
        mi.URL__c = (ti.href != null) ? ti.href : 'javascript:void(0);';
        mi.SLDS_Icon__c = ti.icon;
        mi.SLDS_Icon_Position__c = (ti.iconPosition != null) ? ti.iconPosition : 'left';
        mi.Position__c = ti.position;
        mi.Menu_Item__r = (parentMenuItem != null) ? parentMenuItem: null ;
        mi.Open_in_New_Window__c = ti.openInNewWindow != null && ti.openInNewWindow == 'Yes';
        mi.Public__c = ti.isPublic != null && ti.isPublic == 'Yes';
        mi.Language__c = ti.language;
        mi.External_Id__c = (ti.id != null ) ? ti.id : null;
        mi.Menu_Item_Type__c =(ti.menuItemType != null ? ti.menuItemType : null );
        mi.Menu_Item_Style__c =(ti.menuItemStyle != null ? ti.menuItemStyle : null );
        mi.Menu_Item_Marketing_Image__c = (ti.menuItemMarketingImage != null ? ti.menuItemMarketingImage : null );
        return mi;
    }

    private static Menu_Item__c createMenuItem4(treeItem4 ti, String menuId, String parentMenuItemExtId)
    {
        Menu_Item__c parentMenuItem = (parentMenuItemExtId != null) ? new Menu_Item__c(External_Id__c=parentMenuItemExtId) : null;

        Menu_Item__c mi = new Menu_Item__c();
        mi.Name = ti.label;
        mi.Menu__c = menuId;
        mi.URL__c = (ti.href != null) ? ti.href : 'javascript:void(0);';
        mi.SLDS_Icon__c = ti.icon;
        mi.SLDS_Icon_Position__c = (ti.iconPosition != null) ? ti.iconPosition : 'left';
        mi.Position__c = ti.position;
        mi.Menu_Item__r = (parentMenuItem != null) ? parentMenuItem: null ;
        mi.Open_in_New_Window__c = ti.openInNewWindow != null && ti.openInNewWindow == 'Yes';
        mi.Public__c = ti.isPublic != null && ti.isPublic == 'Yes';
        mi.Language__c = ti.language;
        mi.External_Id__c = (ti.id != null ) ? ti.id : null;
        mi.Menu_Item_Type__c =(ti.menuItemType != null ? ti.menuItemType : null );
        mi.Menu_Item_Style__c =(ti.menuItemStyle != null ? ti.menuItemStyle : null );
        mi.Menu_Item_Marketing_Image__c = (ti.menuItemMarketingImage != null ? ti.menuItemMarketingImage : null );
        return mi;
    }

    private static Menu_Item__c createMenuItem5(treeItem5 ti, String menuId, String parentMenuItemExtId)
    {
        Menu_Item__c parentMenuItem = (parentMenuItemExtId != null) ? new Menu_Item__c(External_Id__c=parentMenuItemExtId) : null;
        
        Menu_Item__c mi = new Menu_Item__c();
        mi.Name = ti.label;
        mi.Menu__c = menuId;
        mi.URL__c = (ti.href != null) ? ti.href : 'javascript:void(0);';
        mi.SLDS_Icon__c = ti.icon;
        mi.SLDS_Icon_Position__c = (ti.iconPosition != null) ? ti.iconPosition : 'left';
        mi.Position__c = ti.position;
        mi.Menu_Item__r = (parentMenuItem != null) ? parentMenuItem: null ;
        mi.Open_in_New_Window__c = ti.openInNewWindow != null && ti.openInNewWindow == 'Yes';
        mi.Public__c = ti.isPublic != null && ti.isPublic == 'Yes';
        mi.Language__c = ti.language;
        mi.External_Id__c = (ti.id != null ) ? ti.id : null;
        mi.Menu_Item_Type__c =(ti.menuItemType != null ? ti.menuItemType : null );
        mi.Menu_Item_Style__c =(ti.menuItemStyle != null ? ti.menuItemStyle : null );
        mi.Menu_Item_Marketing_Image__c = (ti.menuItemMarketingImage != null ? ti.menuItemMarketingImage : null );
        return mi;
    }

    private static Menu_Item__c createMenuItem6(treeItem6 ti, String menuId, String parentMenuItemExtId)
    {
        Menu_Item__c parentMenuItem = (parentMenuItemExtId != null) ? new Menu_Item__c(External_Id__c=parentMenuItemExtId) : null;

        Menu_Item__c mi = new Menu_Item__c();
        mi.Name = ti.label;
        mi.Menu__c = menuId;
        mi.URL__c = (ti.href != null) ? ti.href : 'javascript:void(0);';
        mi.SLDS_Icon__c = ti.icon;
        mi.SLDS_Icon_Position__c = (ti.iconPosition != null) ? ti.iconPosition : 'left';
        mi.Position__c = ti.position;
        mi.Menu_Item__r = (parentMenuItem != null) ? parentMenuItem: null ;
        mi.Open_in_New_Window__c = ti.openInNewWindow != null && ti.openInNewWindow == 'Yes';
        mi.Public__c = ti.isPublic != null && ti.isPublic == 'Yes';
        mi.Language__c = ti.language;
        mi.External_Id__c = (ti.id != null ) ? ti.id : null;
        mi.Menu_Item_Type__c =(ti.menuItemType != null ? ti.menuItemType : null );
        mi.Menu_Item_Style__c =(ti.menuItemStyle != null ? ti.menuItemStyle : null );
        mi.Menu_Item_Marketing_Image__c = (ti.menuItemMarketingImage != null ? ti.menuItemMarketingImage : null );
        return mi;
    }

    private static treeItem createTreeItem(Menu_Item__c toc, Boolean expanded)
    {
        treeItem ti = new treeItem();
        ti.id = toc.Id;
        ti.label = toc.Name;
        ti.name = toc.URL__c;
        ti.level = 1;
        ti.icon = toc.SLDS_Icon__c;
        ti.iconPosition = toc.SLDS_Icon_Position__c;
        ti.href = toc.URL__c;
        ti.position = toc.Position__c;
        ti.miId = toc.Menu_Item__c;
        ti.openInNewWindow = (toc.Open_in_New_Window__c) ? 'Yes' : 'No';
        ti.isPublic = (toc.Public__c) ? 'Yes' : 'No' ;
        ti.expanded = expanded;
        ti.items = new List<treeItem2>();
        ti.itemsMap = new Map<String, treeItem2>();
        ti.language = toc.Language__c;
        ti.menuItemType = toc.Menu_Item_Type__c;
        ti.menuItemStyle = toc.Menu_Item_Style__c;
        ti.menuItemMarketingImage = toc.Menu_Item_Marketing_Image__c;
        
        return ti;
    }

    private static treeItem2 createTreeItem2(Menu_Item__c toc, Boolean expanded)
    {
        treeItem2 ti = new treeItem2();
        ti.id = toc.Id;
        ti.label = toc.Name;
        ti.name = toc.URL__c;
        ti.level = 2;
        ti.icon = toc.SLDS_Icon__c;
        ti.iconPosition = toc.SLDS_Icon_Position__c;
        ti.href = toc.URL__c;
        ti.position = toc.Position__c;
        ti.miId = toc.Menu_Item__c;
        ti.openInNewWindow = (toc.Open_in_New_Window__c) ? 'Yes' : 'No';
        ti.isPublic = (toc.Public__c) ? 'Yes' : 'No' ;
        ti.expanded = expanded;
        ti.items = new List<treeItem3>();
        ti.itemsMap = new Map<String, treeItem3>();
        ti.language = toc.Language__c;
        ti.menuItemType = toc.Menu_Item_Type__c;
        ti.menuItemStyle = toc.Menu_Item_Style__c;
        ti.menuItemMarketingImage = toc.Menu_Item_Marketing_Image__c;
        
        return ti;
    }

    private static treeItem3 createTreeItem3(Menu_Item__c toc, Boolean expanded)
    {
        treeItem3 ti = new treeItem3();
        ti.id = toc.Id;
        ti.label = toc.Name;
        ti.name = toc.URL__c;
        ti.level = 3;
        ti.icon = toc.SLDS_Icon__c;
        ti.iconPosition = toc.SLDS_Icon_Position__c;
        ti.href = toc.URL__c;
        ti.position = toc.Position__c;
        ti.miId = toc.Menu_Item__c;
        ti.openInNewWindow = (toc.Open_in_New_Window__c) ? 'Yes' : 'No';
        ti.isPublic = (toc.Public__c) ? 'Yes' : 'No' ;
        ti.expanded = expanded;
        ti.items = new List<treeItem4>();
        ti.itemsMap = new Map<String, treeItem4>();
        ti.language = toc.Language__c;
        ti.menuItemType = toc.Menu_Item_Type__c;
        ti.menuItemStyle = toc.Menu_Item_Style__c;
        ti.menuItemMarketingImage = toc.Menu_Item_Marketing_Image__c;
        
        return ti;
    }

    private static treeItem4 createTreeItem4(Menu_Item__c toc, Boolean expanded)
    {
        treeItem4 ti = new treeItem4();
        ti.id = toc.Id;
        ti.label = toc.Name;
        ti.name = toc.URL__c;
        ti.level = 4;
        ti.icon = toc.SLDS_Icon__c;
        ti.iconPosition = toc.SLDS_Icon_Position__c;
        ti.href = toc.URL__c;
        ti.position = toc.Position__c;
        ti.miId = toc.Menu_Item__c;
        ti.openInNewWindow = (toc.Open_in_New_Window__c) ? 'Yes' : 'No';
        ti.isPublic = (toc.Public__c) ? 'Yes' : 'No' ;
        ti.expanded = expanded;
        ti.items = new List<treeItem5>();
        ti.itemsMap = new Map<String, treeItem5>();
        ti.language = toc.Language__c;
        ti.menuItemType = toc.Menu_Item_Type__c;
        ti.menuItemStyle = toc.Menu_Item_Style__c;
        ti.menuItemMarketingImage = toc.Menu_Item_Marketing_Image__c;
        
        return ti;
    }

    private static treeItem5 createTreeItem5(Menu_Item__c toc, Boolean expanded)
    {
        treeItem5 ti = new treeItem5();
        ti.id = toc.Id;
        ti.label = toc.Name;
        ti.name = toc.URL__c;
        ti.level = 5;
        ti.icon = toc.SLDS_Icon__c;
        ti.iconPosition = toc.SLDS_Icon_Position__c;
        ti.href = toc.URL__c;
        ti.position = toc.Position__c;
        ti.miId = toc.Menu_Item__c;
        ti.openInNewWindow = (toc.Open_in_New_Window__c) ? 'Yes' : 'No';
        ti.isPublic = (toc.Public__c) ? 'Yes' : 'No' ;
        ti.expanded = expanded;
        ti.items = new List<treeItem6>();
        ti.itemsMap = new Map<String, treeItem6>();
        ti.language = toc.Language__c;
        ti.menuItemType = toc.Menu_Item_Type__c;
        ti.menuItemStyle = toc.Menu_Item_Style__c;
        ti.menuItemMarketingImage = toc.Menu_Item_Marketing_Image__c;
        
        return ti;
    }

    private static treeItem6 createTreeItem6(Menu_Item__c toc, Boolean expanded)
    {
        treeItem6 ti = new treeItem6();
        ti.id = toc.Id;
        ti.label = toc.Name;
        ti.name = toc.URL__c;
        ti.level = 6;
        ti.icon = toc.SLDS_Icon__c;
        ti.iconPosition = toc.SLDS_Icon_Position__c;
        ti.href = toc.URL__c;
        ti.position = toc.Position__c;
        ti.miId = toc.Menu_Item__c;
        ti.openInNewWindow = (toc.Open_in_New_Window__c) ? 'Yes' : 'No';
        ti.isPublic = (toc.Public__c) ? 'Yes' : 'No' ;
        ti.expanded = expanded;
        ti.language = toc.Language__c;
        ti.menuItemType = toc.Menu_Item_Type__c;
        ti.menuItemStyle = toc.Menu_Item_Style__c;
        ti.menuItemMarketingImage = toc.Menu_Item_Marketing_Image__c;
        return ti;
    }

    private static Boolean checkMenuItemsFLSisCreateable()
    {
        return (
            Schema.sObjectType.Menu_Item__c.fields.Name.isCreateable()
            && Schema.sObjectType.Menu_Item__c.fields.Menu__c.isCreateable()
            && Schema.sObjectType.Menu_Item__c.fields.URL__c.isCreateable()
            && Schema.sObjectType.Menu_Item__c.fields.SLDS_Icon__c.isCreateable()
            && Schema.sObjectType.Menu_Item__c.fields.SLDS_Icon_Position__c.isCreateable()
            && Schema.sObjectType.Menu_Item__c.fields.Position__c.isCreateable()
            && Schema.sObjectType.Menu_Item__c.fields.Menu_Item__c.isCreateable()
            && Schema.sObjectType.Menu_Item__c.fields.Open_in_New_Window__c.isCreateable()
            && Schema.sObjectType.Menu_Item__c.fields.Public__c.isCreateable()
            && Schema.sObjectType.Menu_Item__c.fields.Language__c.isCreateable()
            && Schema.sObjectType.Menu_Item__c.fields.External_Id__c.isCreateable()
        );
    }

    private static Boolean checkMenuItemsFLSisAccessible()
    {
        return (
            Schema.sObjectType.Menu_Item__c.fields.Name.isAccessible()
            && Schema.sObjectType.Menu_Item__c.fields.Menu__c.isAccessible()
            && Schema.sObjectType.Menu_Item__c.fields.URL__c.isAccessible()
            && Schema.sObjectType.Menu_Item__c.fields.SLDS_Icon__c.isAccessible()
            && Schema.sObjectType.Menu_Item__c.fields.SLDS_Icon_Position__c.isAccessible()
            && Schema.sObjectType.Menu_Item__c.fields.Position__c.isAccessible()
            && Schema.sObjectType.Menu_Item__c.fields.Menu_Item__c.isAccessible()
            && Schema.sObjectType.Menu_Item__c.fields.Open_in_New_Window__c.isAccessible()
            && Schema.sObjectType.Menu_Item__c.fields.Public__c.isAccessible()
            && Schema.sObjectType.Menu_Item__c.fields.Language__c.isAccessible()
            && Schema.sObjectType.Menu_Item__c.fields.External_Id__c.isAccessible()
        );
    }

    private static Boolean checkMenuItemsFLSisUpdateable()
    {
        return (
            Schema.sObjectType.Menu_Item__c.fields.Name.isUpdateable()
            && Schema.sObjectType.Menu_Item__c.fields.Menu__c.isUpdateable()
            && Schema.sObjectType.Menu_Item__c.fields.URL__c.isUpdateable()
            && Schema.sObjectType.Menu_Item__c.fields.SLDS_Icon__c.isUpdateable()
            && Schema.sObjectType.Menu_Item__c.fields.SLDS_Icon_Position__c.isUpdateable()
            && Schema.sObjectType.Menu_Item__c.fields.Position__c.isUpdateable()
            && Schema.sObjectType.Menu_Item__c.fields.Menu_Item__c.isUpdateable()
            && Schema.sObjectType.Menu_Item__c.fields.Open_in_New_Window__c.isUpdateable()
            && Schema.sObjectType.Menu_Item__c.fields.Public__c.isUpdateable()
            && Schema.sObjectType.Menu_Item__c.fields.Language__c.isUpdateable()
            && Schema.sObjectType.Menu_Item__c.fields.External_Id__c.isUpdateable()
        );
    }


public class treeItem
{
    public string id;
    
    public string label;

    public string name;

    public Integer level;

    public string icon;

    public string iconPosition;

    public string href;

    public string position;

    public string miId;

    public string openInNewWindow;

    public string isPublic;

    public boolean expanded;

    public List<treeItem2> items;

    public Map<String, treeItem2> itemsMap;

    public string language;

    public string menuItemType;

    public string menuItemStyle;

    public string menuItemMarketingImage;

}

public class treeItem2
{
    public string id;
    
    public string label;

    public string name;

    public Integer level;

    public string icon;

    public string iconPosition;

    public string href;

    public string position;

    public string miId;

    public string openInNewWindow;

    public string isPublic;

    public boolean expanded;

    public List<treeItem3> items;

    public Map<String, treeItem3> itemsMap;

    public string language;

    public string menuItemType;

    public string menuItemStyle;

    public string menuItemMarketingImage;

}

public class treeItem3
{
    public string id;
    
    public string label;

    public string name;

    public Integer level;

    public string icon;

    public string iconPosition;

    public string href;

    public string position;

    public string miId;

    public string openInNewWindow;

    public string isPublic;

    public boolean expanded;

    public List<treeItem4> items;

    public Map<String, treeItem4> itemsMap;

    public string language;

    public string menuItemType;

    public string menuItemStyle;

    public string menuItemMarketingImage;

}

public class treeItem4
{
    public string id;
    
    public string label;

    public string name;

    public Integer level;

    public string icon;

    public string iconPosition;

    public string href;

    public string position;

    public string miId;

    public string openInNewWindow;

    public string isPublic;

    public boolean expanded;

    public List<treeItem5> items;

    public Map<String, treeItem5> itemsMap;

    public string language;

    public string menuItemType;

    public string menuItemStyle;

    public string menuItemMarketingImage;

}

public class treeItem5
{
    public string id;
    
    public string label;

    public string name;

    public Integer level;

    public string icon;

    public string iconPosition;

    public string href;

    public string position;

    public string miId;

    public string openInNewWindow;

    public string isPublic;

    public boolean expanded;

    public List<treeItem6> items;

    public Map<String, treeItem6> itemsMap;

    public string language;

    public string menuItemType;

    public string menuItemStyle;

    public string menuItemMarketingImage;

}

public class treeItem6
{
    public string id;
    
    public string label;

    public string name;

    public Integer level;

    public string icon;

    public string iconPosition;

    public string href;

    public string position;

    public string miId;

    public string openInNewWindow;

    public string isPublic;

    public boolean expanded;

    public string language;

    public string menuItemType;

    public string menuItemStyle;

    public string menuItemMarketingImage;

}


}
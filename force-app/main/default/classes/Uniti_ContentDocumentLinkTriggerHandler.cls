/*************************************************************************************************
 * SITETRACKER, INC. ("Sitetracker") CONFIDENTIAL
 * Unpublished Copyright (c) 2013-2020 SITETRACKER, INC., All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of Sitetracker.
 * The intellectual and technical concepts contained herein are proprietary to Sitetracker and
 * may be covered by U.S. and Foreign Patents, patents in process, and are protected by trade
 * secret or copyright law.
 *
 * Dissemination of this information or reproduction of this material is strictly forbidden unless
 * prior written permission is obtained from Sitetracker. Access to the source code contained
 * herein is hereby forbidden to anyone except current Sitetracker employees, managers or
 * contractors who have executed Confidentiality and Non-disclosure agreements explicitly
 * covering such access.
 *
 * The copyright notice above does not evidence any actual or intended publication or disclosure
 * of this source code, which includes information that is confidential and/or proprietary, and
 * is a trade secret, of Sitetracker.
 *
 * @description Uniti_ContentDocumentLinkTriggerHandler
 *
 * @author <A HREF="mailto:bkocherla@sitetracker.com">Bandhavi Kocherla</A>
 *
 ***************************************************************************************************/

global class Uniti_ContentDocumentLinkTriggerHandler extends strk.StTriggerHandler {
    
    static Map<String,Schema.SObjectType> globalDesribe = Schema.getGlobalDescribe();
    static string siteObjPrefix = globalDesribe.get('strk__Site__c').getDescribe().getKeyPrefix();
    static string formObjPrefix = globalDesribe.get('strk__Checklist__c').getDescribe().getKeyPrefix();
    static string projectObjPrefix = globalDesribe.get('strk__Project__c').getDescribe().getKeyPrefix();
    static Map<Id,ContentDocument> contDocMapToUpdate = new Map<Id,ContentDocument>();
    static Map<Id,strk__Attachment__c> attMapToUpdate = new Map<Id,strk__Attachment__c>();
    
    global override void initializeExtended(String sObjectName){}
    
    global override void bulkBeforeExtended(){}
    
    global override void bulkAfterExtended(){
        if(trigger.isInsert){
            updateFileNameForSiteRecords(trigger.new);
        }
    }
    
    global override void beforeInsertExtended(SObject so){}
    
    global override void afterInsertExtended(SObject so){}
    
    global override void beforeUpdateExtended(SObject oldSo,SObject newSo){}
    
    global override void afterUpdateExtended(SObject oldSo,SObject newSo){}
    
    global override void beforeDeleteExtended(SObject so){}
    
    global override void afterDeleteExtended(SObject so){}
    
    global override void andFinallyExtended(){
        if(!contDocMapToUpdate.isEmpty()) {
            update contDocMapToUpdate.values();
        }
        if(!attMapToUpdate.isEmpty()) {
            update attMapToUpdate.values();
        }
    }
    
    public static void updateFileNameForSiteRecords(list<ContentDocumentLink> contDocList){
        
        Set<Id> contDocIdSet = new Set<Id>();
        Set<Id> siteIdSet = new Set<Id>();
        Set<Id> projectIdSet = new Set<Id>();
        Set<Id> formIdSet = new Set<Id>();
        List<ContentDocumentLink> reqConDocList = new List<ContentDocumentLink>();
        
        for(ContentDocumentLink cdl : contDocList){
            if(cdl.LinkedEntityId != null){
                contDocIdSet.add(cdl.ContentDocumentId);
                
                if(String.valueOf(cdl.LinkedEntityId).subString(0,3) == siteObjPrefix){
                    siteIdSet.add(cdl.LinkedEntityId);
                    reqConDocList.add(cdl);
                }
                else if(String.valueOf(cdl.LinkedEntityId).subString(0,3) == projectObjPrefix){
                    projectIdSet.add(cdl.LinkedEntityId);
                    reqConDocList.add(cdl);
                }
                else if(String.valueOf(cdl.LinkedEntityId).subString(0,3) == formObjPrefix){
                    formIdSet.add(cdl.LinkedEntityId);
                    reqConDocList.add(cdl);
                }
                
            }
        }
        
        if(!contDocIdSet.isEmpty() && (!siteIdSet.isEmpty() ||!projectIdSet.isEmpty() || !formIdSet.isEmpty())){
            
            Map<Id,strk__Site__c> siteRecMap = new Map<Id,strk__Site__c>();
            Map<Id,strk__Project__c> projectMap = new Map<Id,strk__Project__c>();  
            Map<Id,strk__Checklist__c> formMap = new Map<Id,strk__Checklist__c>();  
            Date dToday = Date.today();
            Datetime todayDateTime = Datetime.newInstanceGmt(dToday, Time.newInstance(0,0,0,0));
            
            Map<Id,ContentDocument> contentDocMap = new Map<Id,ContentDocument>([SELECT Id,Title,FileExtension 
                                                                                 FROM ContentDocument 
                                                                                 WHERE Id IN :contDocIdSet]);
            if(!siteIdSet.isEmpty())
                siteRecMap = new Map<Id,strk__Site__c>([SELECT Id,Name,Site_ID__c
                                                        FROM strk__Site__c 
                                                        WHERE Id IN :siteIdSet]);
            if(!projectIdSet.isEmpty())
                projectMap = new Map<Id,strk__Project__c>([SELECT Id,Name,strk__Site__c,strk__Site__r.Name,strk__Site__r.Site_ID__c
                                                           FROM strk__Project__c 
                                                           WHERE Id IN :projectIdSet]);
            
            if(!formIdSet.isEmpty())
                formMap = new Map<Id,strk__Checklist__c>([SELECT Id,Name,strk__Site__c,strk__Site__r.Name,strk__Site__r.Site_ID__c
                                                          FROM strk__Checklist__c 
                                                          WHERE Id IN :formIdSet]);
            
            List<strk__Attachment__c> attachments = [SELECT Id,Name,strk__ContentDocumentRecord__c 
                                                     FROM strk__Attachment__c 
                                                     WHERE strk__ContentDocumentRecord__c IN:contDocIdSet];
            
            Map<Id,strk__Attachment__c> attachmentMap = new Map<Id,strk__Attachment__c>();
            for(strk__Attachment__c att:attachments){
                attachmentMap.put(att.strk__ContentDocumentRecord__c,att);
            }
            
            for(ContentDocumentLink cdl : reqConDocList) {
                if(cdl.LinkedEntityId != null){
                    String siteDetails = '';
                    if(siteRecMap.containsKey(cdl.LinkedEntityId)){
                        strk__Site__c siteRec = siteRecMap.get(cdl.LinkedEntityId);
                        siteDetails = siteRec.Site_ID__c + '_' + siteRec.Name + '_';
                    }
                    else if(projectMap.containsKey(cdl.LinkedEntityId)){
                        strk__Project__c projRec = projectMap.get(cdl.LinkedEntityId);
                        siteDetails = projRec.strk__Site__r.Site_ID__c + '_' + projRec.strk__Site__r.Name + '_';
                    }
                    else if(formMap.containsKey(cdl.LinkedEntityId)){
                        strk__Checklist__c formRec = formMap.get(cdl.LinkedEntityId);
                        siteDetails = formRec.strk__Site__r.Site_ID__c + '_' + formRec.strk__Site__r.Name + '_';
                    }
                    if(contentDocMap.containsKey(cdl.ContentDocumentId)){
                        ContentDocument contDoc = contentDocMap.get(cdl.ContentDocumentId);
                        if(!contDoc.Title.startsWith(siteDetails)){
                            ContentDocument contDocToUpdate = new ContentDocument();
                            contDocToUpdate.Id = contDoc.Id;
                            contDocToUpdate.Title =  siteDetails + contDoc.Title + '_' + todayDateTime.format('yyyy-MM-dd');
                            if(contDocToUpdate.Title != null && contDocToUpdate.Title.length() > 80){
                                contDocToUpdate.Title = contDocToUpdate.Title.subString(0,80);
                            }
                            contDocMapToUpdate.put(contDocToUpdate.Id,contDocToUpdate);
                        }
                        if(attachmentMap.containsKey(cdl.ContentDocumentId)){
                            strk__Attachment__c attRec = attachmentMap.get(cdl.ContentDocumentId);
                            if(!attRec.Name.startsWith(siteDetails)){
                                strk__Attachment__c att = new strk__Attachment__c();
                                att.Id = attRec.Id;
                                if(String.valueOf(cdl.LinkedEntityId).subString(0,3) == projectObjPrefix)
                                    att.Name = contDoc.Title;
                                else
                                    att.Name = siteDetails + contDoc.Title + '_' + todayDateTime.format('yyyy-MM-dd');
                                if(att.Name != null && att.Name.length() > 80){
                                    att.Name = att.Name.subString(0,80);
                                }
                                attMapToUpdate.put(att.Id,att);
                            }
                        }
                    }
                }
            }
        }
    }
}
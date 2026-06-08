public without sharing class EDSContentDocumentLinkTriggerHandler implements strk.StITrigger {

    //Setup the class variables that are needed
    public String Project = strk__Project__c.sObjectType.getDescribe().getName();
    public String Activity = strk__Activity__c.sObjectType.getDescribe().getName();
    List<ContentDocumentLink> documentLinksToInsert = new List<ContentDocumentLink>();

    public void initialize(String obj){}
    public void bulkBefore() {}
    public void bulkAfter() {}

    public void beforeInsert(SObject newObject) {}
    public void afterInsert(SObject newObject) {
        linkToProject(newObject);
    }

    public void beforeUpdate(SObject oldObject, SObject newObject) {}
    public void afterUpdate(SObject oldObject, SObject newObject) {}

    public void beforeDelete(SObject so) {}
    public void afterDelete(SObject so) {}

    public void andFinally() {
        try{
            if (documentLinksToInsert.size() > 0) {
                System.debug('About to insert!');
                System.debug('DocumentLinks to Insert: '+documentLinksToInsert);
                insert documentLinksToInsert;
                //Database.SaveResult[] documentInsert = Database.insert(documentLinksToInsert, false);
            }
        } catch (Exception e) {
            System.debug('Error in Custom ContentDocumentLinkTrigger: '+e);
        }
    }
    
    
    //What type of document is this we currently check for GP Project 2 / Project (strk) / GP Attachments
    private Boolean isMasterProject(ContentDocumentLink contentDocumentLink) {
        String linkedEntityId = contentDocumentLink.LinkedEntityId;
        return String.isNotBlank(linkedEntityId) && strk.StUtils.getObjectNameFromId(linkedEntityId) == Project;
    }
    
    private void linkToProject(SObject newObject) {
        
        ContentDocumentLink cdl = (ContentDocumentLink)newObject;
        
        System.debug('Is this a strk Attachment: '+isMasterProject((cdl)));
        
        if(isMasterProject(cdl)) {
            strk__Project__c theAttachment = [SELECT Id, strk__Site__c, strk__ProjectTemplate__c FROM strk__Project__c WHERE Id =: cdl.LinkedEntityId LIMIT 1];
            Map<Id, strk__Activity__c> theActivityOfAttachement = new Map<Id, strk__Activity__c>([SELECT Id, strk__Activity_Template__c, strk__Activity_Template__r.strk__Project_Template__c FROM strk__Activity__c WHERE strk__Project__c =: theAttachment.Id]);

            System.debug('TheAttachment(Project): '+theAttachment);
            if(theAttachment != null) {
                Id siteId = (Id)theAttachment.strk__Site__c;
                //Link to Site
                
                
                List<ContentDocumentLink> cdl2 = [SELECT Id, LinkedEntityId, ContentDocumentId, ShareType FROM ContentDocumentLink WHERE ContentDocumentId =: cdl.ContentDocumentId];
                
                List<Id> documentLinkId = new List<Id>();
                for(ContentDocumentLink c : cdl2) {
                    if(theActivityofAttachement.containsKey(c.LinkedEntityId)) {
                        //documentLinkId.add(c.LinkedEntityId);

                        strk__Activity__c act = theActivityofAttachement.get(c.LinkedEntityId);
                        System.debug('act.strk__Activity_Template__c: '+act.strk__Activity_Template__c);
                        documentLinkId.add(act.strk__Activity_Template__c);
                        
                    }
                }
                
                List<File_Linking__c> link_list = [SELECT Id, Activity_Template__c, Project_Template__c 
                                                    FROM File_Linking__c 
                                                    WHERE Project_Template__c =: theAttachment.strk__ProjectTemplate__c AND Activity_Template__c IN :documentLinkId];
                System.debug('Project Template Id: '+theAttachment.strk__ProjectTemplate__c);
                System.debug('List of DocumentLinks: '+documentLinkId);
                
                
                System.debug('theActivityOfAttachement(Activity): '+theActivityOfAttachement);
                System.debug('cdl2(List of ContentDocumentLinks): '+cdl2);
                System.debug('link_list(List of linking Activity Templates): '+link_list);
                
                if(link_list != null && link_list.size() > 0) {
                    ContentDocumentLink newLink1 = new ContentDocumentLink();
                    newLink1.LinkedEntityId = siteId;
                    newLink1.ContentDocumentId = cdl.ContentDocumentId;
                    newLink1.ShareType = 'V';
                    documentLinksToInsert.add(newLink1);
                    System.debug('Links to insert: '+documentLinksToInsert);
                }
                
            }
        }
        
    }
}
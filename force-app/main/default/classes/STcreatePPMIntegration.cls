public class STcreatePPMIntegration implements Queueable, Database.AllowsCallouts {
    @TestVisible
    private static String EMPTY = '[]';

    private Map<String, String> intSettingsMap{
        get{
            if (intSettingsMap == null){
                intSettingsMap = new Map<String, String>();
                List<Oracle_PPM_Integration_Settings__mdt> intSettings = [SELECT MasterLabel, Value__c FROM Oracle_PPM_Integration_Settings__mdt];
                for(Oracle_PPM_Integration_Settings__mdt intSetting: intSettings){
                    intSettingsMap.put(intSetting.MasterLabel, intSetting.Value__c);
                }
            }
            return intSettingsMap;
        } private set;
    }

    @TestVisible
    private String json2Send {get;set;}
    private boolean isUpdate {get;set;}

    private List<Oracle_PPM_Mapping__mdt> mappings{
        get{
            if (mappings == null){
                String query =
                   'SELECT DeveloperName,Active__c,Is_Update__c,Field_API_Name__c,Object_API_Name__c,Is_Key__c FROM Oracle_PPM_Mapping__mdt ' +
                    'WHERE Active__c = true AND Field_API_Name__c != null';
                if (isUpdate){
                    query += ' AND Is_Update__c = true';
                }
                mappings = Database.query(query);
            }
            return mappings;
        } private set;
    }

    private Set<String> siteFieldMappings{
        get{
            if (siteFieldMappings == null){
                siteFieldMappings = new Set<String>();
                List<Oracle_PPM_Mapping__mdt> siteMappings =
                   [SELECT Field_API_Name__c FROM Oracle_PPM_Mapping__mdt
                     WHERE Active__c = true AND Field_API_Name__c LIKE '%__r.%'];
                for (Oracle_PPM_Mapping__mdt mapping: siteMappings){
                    String fieldName = mapping.Field_API_Name__c.split('\\.')[1];
                    if (!fieldName.equalsIgnoreCase('id')){
                        siteFieldMappings.add(fieldName);
                    }
                }
            }
            return siteFieldMappings;
        } private set;
    }

    /**
     * This method will be called on update of an existing project
     *
     * @param1: Trigger.New context, @param2: Trigger.oldMap context, @param3: Object
     *
     * @return: nothing
     */
    public STcreatePPMIntegration(List<sObject> TriggerNew, Map<Id,sObject> TriggerOldMap, sObject obj){
        isUpdate = true;
        initiateCallout(triggerNew, TriggerOldMap, obj);
    }

    /**
     * This method will be called on creation of a new project
     *
     * @param1: Trigger.New context, @param2: Object
     *
     * @return: nothing
     */
    public STcreatePPMIntegration( List<sObject> TriggerNew, sObject obj){
        isUpdate = false;
        initiateCallout(triggerNew, new Map<Id, sObject>(), obj);
    }

    private void initiateCallout(List<sObject> triggerNew, Map<Id,sObject> triggerOldMap, sObject obj){
        if(intSettingsMap.get('Integration Status') == 'ON'){
            if(mappings.size() == 0){
                throw new PPMIntegrationException( 'ERROR: Oracle PPM Mapping not defined in Update. Please check your Custom Meta Data Types.' );
            }
            String objName = obj.getSObjectType().getDescribe().getName();
            json2Send = createRecordJSON(triggerNew, triggerOldMap, objName);
        }
    }

    public void execute(QueueableContext context){
        if(String.isNotBlank(json2Send) && json2Send != EMPTY){
            // make a callout to Oracle PPM
            String resp = sendcreatePPMRequest(json2Send);
        }
    }

     /**
     * This method makes a call to Oracle PPM.
     *
     * @param1: JSON string
     *
     * @return: String
     */
    private String sendcreatePPMRequest(String body) {
        String PPM_ENDPOINT_CREATE = intSettingsMap.get('PPM ENDPOINT CREATE');
        String PPM_ENDPOINT_UPDATE = intSettingsMap.get('PPM ENDPOINT UPDATE');
        String responseBody = '';
        try{
            HttpRequest request = new HttpRequest();
            if(isUpdate){
                request.setMethod('PUT');
                request.setEndPoint(PPM_ENDPOINT_UPDATE);
            }
            else{
                request.setMethod('POST');
                request.setEndPoint(PPM_ENDPOINT_CREATE);
            }

            body = body.replace('\n', '\\n');
            body = body.replace('\r', '\\r');
            request.setBody(body);
            request.setCompressed(false);
            request.setHeader('Content-Type','application/json');
            Http http = new Http();
            HttpResponse response = http.send(request);
            responseBody = response.getBody();

            System.debug('request = ' + request);
            System.debug('requestbody = ' + body);
            System.debug('response = ' + responseBody);
        }
        catch(Exception e){
            throw new PPMIntegrationException('Line Num: ' + e.getLineNumber() + ' - Exception Occured in HTTP call: '+e.getMessage());
        }

        return responseBody;
    }

    //For some reason my code wouldn't print out the normal JSON gen.
    public class JSONGen{
        private String json;
        private Boolean isLastField;
        private Boolean hasStartObject;

        public JSONGen(){
            json = '';
            isLastField = false;
            hasStartObject = false;
        }

        public void writeStartArray(){
            json += '[';
        }

        public void writeStartObject(){
            if (hasStartObject){
                json += ',';
            }
            hasStartObject = true;
            json += '{';
        }

        public void writeStringField(String name, String value){
            if (isLastField){
                json += ',';
            }
            isLastField = true;
            json += '"' + name + '":"' + value + '"';
        }

        public void writeEndObject(){
            json += '}';
            isLastField = false;
        }

        //Writes to end of array
        public void writeEndArray(){
            json += ']';
        }

        //Returns JSON as a string
        public String getAsString(){
            return json;
        }
    }

    private Map<Id, strk__Site__c> fetchSiteMap(List<strk__Project__c> projects) {
        Map <Id, strk__Site__c> siteMap;
        if (projects != null && !projects.isEmpty()) {
            Set<Id> siteIds = new Set<Id>();

            for (strk__Project__c project: projects){
                siteIds.add(project.strk__Site__c);
            }

            String query = 'SELECT Id';
            for (String field: siteFieldMappings){
                query += ',' + field;
            }
            query += ' FROM strk__Site__c WHERE Id IN :siteIds';

            List<strk__Site__c> sites = Database.query(query);
            siteMap = new Map<Id, strk__Site__c>(sites);
        }
        return siteMap;
    }

    /*
        Creates JSON data for webservice.  Only pulls in fields that have been changed
        @param triggerNew-data from project or sites Trigger.new value
        @param triggerNew-data from project or sites Trigger.oldMap value
        @param objName-Object API Name of the records being parsed
        @return String-JSON result of the changed fields
    */
    private String createRecordJSON(List<sObject> triggerNew, Map<Id,sObject> triggerOldMap, String objName){
        JSONGen gen = new JSONGen();//JSON.createGenerator(true);
        gen.writeStartArray();


        //Based off of Project data
        if (objName == 'strk__Project__c'){
            Map<Id, strk__Project__c> projectMap;
            if (!isUpdate) {
                projectMap = new Map<Id, strk__Project__c>([SELECT Id, Name FROM strk__Project__c WHERE Id IN :triggerNew]);
            }

            List<strk__Project__c> projects = (List<strk__Project__c>) triggerNew;
            Map<Id, strk__Site__c> siteMap = fetchSiteMap(projects);

            Set<String> ignoredFields = new Set<String> {
                'Name',
                'Id',
                'Integration_Project_Name__c'
            };
            
            for (sObject obj: TriggerNew){
                SObject old = triggerOldMap.get(obj.Id);
                Boolean hasChange = false;
                for (Oracle_PPM_Mapping__mdt cmt: mappings) {
                    SObject curr = obj;
                    String fieldName = cmt.Field_API_Name__c;
                    String value;

                    //Skip the Ignored field. They are added at the end
                    if (isUpdate && 
                        ignoredFields.contains(fieldName) ) {

                        continue;
                    }

                    //Add site info on Project Insert
                    if(fieldName.contains('__r')){
                        if (!isUpdate){
                            curr = siteMap.get((Id)curr.get('strk__Site__c'));
                            fieldName = fieldName.split('\\.')[1];
                        } else{
                            continue;
                        }
                    }

                    if (!isUpdate && cmt.Field_API_Name__c.equalsIgnoreCase('Name')){
                        value = projectMap.get(obj.Id).Name;
                    }else{
                        value = String.ValueOf(curr.get(fieldName));
                    }
                    System.debug('mapping = ' + cmt);
                    System.debug('value = ' + value);

                    //Only add value pair if a field has changed.
                    if (old == null || value != String.ValueOf(old.get(fieldName))){
                        if (!hasChange) {
                            hasChange = true;
                            gen.writeStartObject();
                        }

                        String subStr = String.isNotBlank(value) ? value : '';
                        if (String.isBlank(subStr) && (cmt.Is_Key__c || Test.isRunningTest() && fieldName.equalsIgnoreCase('Integration_Template_Key__c'))){
                            throw new PPMIntegrationException('Key value is blank on insert: ' + fieldName);
                        }
                        gen.writeStringField(cmt.DeveloperName, subStr);
                    }
                }

                //Add in the required fields that were ignored in above loop.
                if (hasChange && isUpdate){
                    for (Oracle_PPM_Mapping__mdt cmt: mappings){
                        //Only add value pair if a field has changed.
                        if (cmt.Field_API_Name__c.equalsIgnoreCase('Name') || 
                            cmt.Field_API_Name__c.equalsIgnoreCase('Id') ||
                            cmt.Field_API_Name__c.equalsIgnoreCase('Integration_Project_Name__c') ) {

                            String subStr = String.ValueOf(obj.get(cmt.Field_API_Name__c)) != null ? String.ValueOf(obj.get(cmt.Field_API_Name__c)) : '';
                            gen.writeStringField(cmt.DeveloperName, subStr);
                        }
                    }
                }
                if (hasChange){
                    gen.writeEndObject();
                }
            }
        } else {//Being run from Site data
            //Get child Projects.  Data from Projects are used for Keys even on Sites
            Map<Id, List<strk__Project__c>> siteToProjectsMap = new Map<Id, List<strk__Project__c>>();
            Set<Id> siteIds = new Set<Id>();
            for (SObject site: triggerNew){
                siteIds.add(site.Id);
            }
            for (strk__Project__c project: [SELECT strk__Site__c, Name, Integration_Project_Name__c FROM strk__Project__c WHERE strk__Site__c IN :triggerNew]){
                List<strk__Project__c> projects = siteToProjectsMap.get(project.strk__Site__c);
                if (projects == null){
                    projects = new List<strk__Project__c>();
                    siteToProjectsMap.put(project.strk__Site__c, projects);
                }
                projects.add(project);
            }

            String query = 'SELECT Id';
            for (String field: siteFieldMappings){
                query += ',' + field;
            }
            query += ' FROM strk__Site__c WHERE Id IN :siteIds';

            List<strk__Site__c> sites = Database.query(query);

            for (sObject obj: sites){
                sObject old = triggerOldMap.get(obj.Id);
                List<strk__Project__c> projects = siteToProjectsMap.get(obj.Id);
                if (projects != null){
                    for (strk__Project__c project: projects){
                        Boolean hasChange = false;
                        for (Oracle_PPM_Mapping__mdt cmt: mappings){
                            if(!cmt.Field_API_Name__c.contains('__r')){
                                continue;
                            }

                            String fieldName = cmt.Field_API_Name__c.split('\\.')[1];
                            if(old == null || String.ValueOf(obj.get(fieldName)) != String.ValueOf(old.get(fieldName))){
                                if (!hasChange){
                                    hasChange = true;
                                    gen.writeStartObject();
                                }
                                String subStr = String.ValueOf(obj.get(fieldName)) != null ? String.ValueOf(obj.get(fieldName)) : '';
                                gen.writeStringField(cmt.DeveloperName, subStr);
                            }
                        }

                        if (hasChange){
                            for (Oracle_PPM_Mapping__mdt cmt: mappings){
                                if (cmt.Field_API_Name__c.equalsIgnoreCase('Name') || 
                                    cmt.Field_API_Name__c.equalsIgnoreCase('Id') ||
                                    cmt.Field_API_Name__c.equalsIgnoreCase('Integration_Project_Name__c') ) {

                                    String subStr = String.ValueOf(project.get(cmt.Field_API_Name__c)) != null ? String.ValueOf(project.get(cmt.Field_API_Name__c)) : '';
                                    gen.writeStringField(cmt.DeveloperName, subStr);
                                }
                            }
                            gen.writeEndObject();
                        }
                    }
                }
            }
        }
        gen.writeEndArray();
        String result = gen.getAsString();
        System.debug('result = ' + result);
        System.debug('objName = ' + objName);
        System.debug('isUpdate = ' + isUpdate);
        return result;
    }

    class PPMIntegrationException extends Exception {}
}
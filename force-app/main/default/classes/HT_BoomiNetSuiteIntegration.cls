public class HT_BoomiNetSuiteIntegration {
    public static List<Oracle_PPM_Mapping__mdt> oracleFieldMappings =  Oracle_PPM_Mapping__mdt.getAll().values();
    
    public static Map<string,string> customerMap = new Map<string,string>{
        '3' => 'Harmoni Towers, LLC',  '4' => 'Harmoni Network Services LLC', '6' => 'Parallel Towers LLC',
             '8' => 'PI Tower Services LLC'            
    };

    
    public static void syncProjects(List<strk__project__c> projectRecs,Map<Id,strk__project__c> oldMap){
        List<strk__project__c> updateNetSuiteStatusList = new List<strk__project__c>();
        try{
            for(strk__project__c prj:projectRecs){
                if(prj.Netsuite_Status__c != 'Sent'){
                    Boolean shouldSync = false;
                    if(oldMap==null){
                        shouldSync = true;
                    }else{
                        for(Oracle_PPM_Mapping__mdt opm : oracleFieldMappings){
                            Boolean shouldInvoke = false;
                            if(opm.Active__c && opm.Is_Update__c && opm.Field_API_Name__c!=null && !opm.Field_API_Name__c.contains('__r')){
                                if(prj.get(opm.Field_API_Name__c)!=oldMap.get(prj.Id).get(opm.Field_API_Name__c)){
                                    shouldSync = true;
                                    break;
                                }
                            }
                        }
                    }
                    if (shouldSync) {
                        strk__project__c proj = new strk__project__c();
                        proj.Id = prj.Id;
                        proj.Netsuite_Status__c = 'Sent';
                        proj.Latest_Integration_Response__c='';
                        if(oldMap==null){
                            proj.Oracle_ID__c = prj.Id;
                        }
                        updateNetSuiteStatusList.add(proj);
                    }
                }
            }
            if(!updateNetSuiteStatusList.isEmpty()){
                update updateNetSuiteStatusList;
                for(strk__project__c pr:updateNetSuiteStatusList){
                    sendToBoomiFuture(pr.Id);
                }
            }
        }catch(Exception e){
            throw new AuraHandledException('Line Num: ' + e.getLineNumber() + ' - Exception Occured: '+e.getMessage());
        }
    }
    
    public static String prepareReqJson(strk__project__c projectRec){
        try{
            Integer nullvalueCounter = 0;
            Map<String,Object> jsonMap;
            jsonMap = new Map<String,Object>();
            System.debug('oracleFieldMappings'+Oracle_PPM_Mapping__mdt.getAll().values());
            for(Oracle_PPM_Mapping__mdt opm : Oracle_PPM_Mapping__mdt.getAll().values()){
                if(opm.Active__c && opm.Is_Update__c && opm.Field_API_Name__c!=null && !opm.Field_API_Name__c.contains('__r')){
                    if(projectRec.get(opm.Field_API_Name__c)!=null && String.isNotBlank(String.valueOf(projectRec.get(opm.Field_API_Name__c)))){
                        jsonMap.put(opm.DeveloperName,projectRec.get(opm.Field_API_Name__c));
                    }else{
                        //nullvaluefieldsList.add(opm.DeveloperName);
                        jsonMap.put(opm.DeveloperName,' ');  
                        if(opm.Netsuite_Field_Id__c != null) {
                            jsonMap.put('nullvalue'+nullvalueCounter,opm.Netsuite_Field_Id__c);
                            nullvalueCounter ++;
                        }
                    }
                }else if(opm.Active__c && opm.Is_Update__c && opm.Field_API_Name__c!=null && opm.Field_API_Name__c!='strk__Project_Manager__r.Name' && opm.Field_API_Name__c.contains('__r')){
                    SObject siteObj = projectRec.getSObject('strk__Site__r');
                    String fieldName = opm.Field_API_Name__c.split('\\.')[1];
                    system.debug(String.valueOf(siteObj.get(fieldName)));
                    if(siteObj.get(fieldName)!=null && String.isNotBlank(String.valueOf(siteObj.get(fieldName)))){
                        jsonMap.put(opm.DeveloperName,siteObj.get(fieldName));
                    }else{
                        jsonMap.put(opm.DeveloperName,' '); 
                        if(opm.Netsuite_Field_Id__c != null) {
                            jsonMap.put('nullvalue'+nullvalueCounter,opm.Netsuite_Field_Id__c);
                            nullvalueCounter ++;
                        }
                    }
                    jsonMap.put(opm.DeveloperName,siteObj.get(fieldName));
                }
                jsonMap.put('projectmanager',projectRec.strk__Project_Manager__r.Name);
                jsonMap.put('externalId',projectRec.Oracle_ID__c);
                jsonMap.put('subsidiaryId',projectRec.Subsidiary_Updated__c);
                String parentName = '';
                if(projectRec.strk__Site__r.Company_Name_Updated__c=='Galaxi'){
                    parentName = 'Galaxi';
                }else{
                    parentName = customerMap.get(''+projectRec.Subsidiary_Updated__c);
                }
                jsonMap.put('ParentName',parentName);

        }
            String jsonBody = JSON.serializePretty(jsonMap);
            System.debug('jsonBodyjsonBody'+jsonBody);
            return jsonBody;
        }catch(Exception e){
            projectRec.Netsuite_Status__c = 'Error';
            projectRec.Latest_Integration_Response__c = 'Failed at salesforce: records not been sent to netgain due to '+ e.getLineNumber() + ' - Exception Occured: '+e.getMessage();
            update projectRec;
            throw new AuraHandledException('Line Num: ' + e.getLineNumber() + ' - Exception Occured: '+e.getMessage());
        }
    }
    
    public static  List<strk__project__c> getProject(String projectId){
        List<String> fieldNames = new List<String>();
        fieldNames.add('strk__Site__c');
        fieldNames.add('Latest_Integration_Response__c');
        for (Oracle_PPM_Mapping__mdt m : Oracle_PPM_Mapping__mdt.getAll().values()) {
            if (m.Active__c && m.Field_API_Name__c != null) {
                fieldNames.add(m.Field_API_Name__c);
            }
        }        
        String soql = 'SELECT Oracle_ID__c, Subsidiary__c, Subsidiary_Updated__c, strk__Site__r.Company_Name_Updated__c,Netsuite_Status__c, ' + String.join(fieldNames, ', ') + ' FROM strk__project__c WHERE Id = :projectId';
        System.debug('soqlsoql'+soql);
        List<strk__project__c> projects = Database.query(soql); 
        return projects;
    }
    

    @future(callout=true)
    public static void sendToBoomiFuture(String projectId){
        sendToBoomi(projectId);
    }
    
    public static void sendToBoomi(String projectId){
        List<strk__project__c> proj = getProject(projectId);
        String jsonBody = prepareReqJson(proj[0]);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:HT_NetGain_Boomi/ws/simple/getUpsertProject');
        req.setMethod('POST');
        req.setBody(jsonBody);
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        strk__Project__c prj = new strk__Project__c();
        prj.Id = projectId;
        if(res.getStatusCode()==200)
        {
            if(!Test.isRunningTest()){
            prj.Netsuite_Status__c = 'Sent';
            }
            prj.Latest_Integration_Response__c='Record has been processing for sending to netgain';
        }else{
            prj.Netsuite_Status__c = 'Error';
            prj.Latest_Integration_Response__c = 'Failed at salesforce: records not been sent to netgain due to '+res.getStatus();
        }
        update prj;
    }
}
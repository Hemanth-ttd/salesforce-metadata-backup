global class UnitEconomicsScheduler implements schedulable {
    global void execute(schedulableContext sc){
        //Query today's created/modified records
        List<Unit_Economics__c> ueList = [
            SELECT Id,Project__c,Hard_Capex__c,Latest_Approved__c
            FROM Unit_Economics__c
            WHERE(CreatedDate = TODAY OR LastModifiedDate = TODAY)
            AND Latest_Approved__c = TRUE
        ];
        //Prepare Map (ProjectId → Cost)
        Map<Id,Decimal>projectCostMap = new Map<Id, Decimal>();
         
        for(Unit_Economics__c ue : ueList){
            if(ue.Project__c !=null){
                projectCostMap.put(ue.Project__c, ue.Hard_Capex__c);
            }  
        }
        //	Query Projects With Extension
        List<strk__Project__c>projects = [
            SELECT Id, Budget_Cost__c,Project_Extension__c
            FROM strk__Project__c
            WHERE Id IN :projectCostMap.KeySet()
        ];
        //Map Extension → Unit Economics
        Map<Id,Id>ExtensionToUEMap =new Map<Id,Id>();
         for(strk__Project__c project : projects){
            if(project.Project_Extension__c != null){
                ExtensionToUEMap.put(
                    project.Project_Extension__c,
                    ExtensionToUEMap.get(project.Id)
                );
            }
        }
        //Get Extensions
        List<Project_Extension__c> ExtensionsToUpdate = [
            SELECT Id, Unit_Economics_Id__c
            FROM Project_Extension__c
            WHERE Id IN :ExtensionToUEMap.keySet()
        ];

        // Update Extension with Unit Economics
        for(Project_Extension__c extension : ExtensionsToUpdate){
            Extension.Unit_Economics_Id__c = ExtensionToUEMap.get(extension.Id);
        }
        //Update Records
        if(!ExtensionsToUpdate.isEmpty()){
            update ExtensionsToUpdate;
        }
    }
}
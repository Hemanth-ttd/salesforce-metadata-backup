global class HT_BatchCSVEmailSender implements Database.Batchable<SObject>, Database.Stateful {
    
    private String projectCSV = '';
    private String projectExtensionCSV = '';
    private String query;  // To hold the dynamic query string
    private Map<Id, SObject> projectReturnmap = new Map<Id, SObject>();
    private Map<Id, SObject> projectExtensionReturnmap = new Map<Id, SObject>();
    
 // Constructor to pass the query string
    public HT_BatchCSVEmailSender(String queryString) {
        this.query = queryString;
    }

    // Step 1: Query records to process (using dynamic query)
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    // Step 1: Query records to process
   /* global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, strk__Field__c, strk__Project__c, strk__Project__r.Project_Extension__c,  
            strk__API_Field__c, strk__Old_Value__c, strk__New_Value__c  
            FROM strk__Project_History__c 
            WHERE strk__Project__r.strk__Project_Template__c = 'US Development - AT&T' 
            AND CreatedBy.Name = 'Masthan Andela' 
            AND strk__Field__c LIKE '%(A)'
        ]);
    }
*/
    // Step 2: Process records and convert them to CSV format
    global void execute(Database.BatchableContext bc, List<strk__Project_History__c> records) {
        
        for (strk__Project_History__c singleRecord : records) {
            Boolean isProjectExtension = singleRecord.strk__API_Field__c.contains('Project_Extension__r');
            if(singleRecord.strk__Old_Value__c != null){
                Date formattedOldValue = Date.parse(convertToDate(singleRecord.strk__Old_Value__c));
                
                if (!isProjectExtension) {  
                    if (!projectReturnmap.containsKey(singleRecord.strk__Project__c)) {
                        projectReturnmap.put(singleRecord.strk__Project__c, new strk__Project__c(Id = singleRecord.strk__Project__c));
                    }
                    projectReturnmap.get(singleRecord.strk__Project__c).put(singleRecord.strk__API_Field__c, formattedOldValue);
                } else {
                    Id projectExtensionId = singleRecord.strk__Project__r.Project_Extension__c;
                    if (projectExtensionId != null) {
                        if (!projectExtensionReturnmap.containsKey(projectExtensionId)) {
                            projectExtensionReturnmap.put(projectExtensionId, new Project_Extension__c(Id = projectExtensionId));
                        }
                        projectExtensionReturnmap.get(projectExtensionId).put(singleRecord.strk__API_Field__c.replace('Project_Extension__r.', ''), formattedOldValue);
                    }
                }
            }
        }
        
    }

    // Step 3: After batch completes, send CSV via email
    global void finish(Database.BatchableContext bc) {
        
        // Convert Maps to CSV format
        projectCSV += convertSObjectListToCSV(projectReturnmap.values());
        projectExtensionCSV += convertSObjectListToCSV(projectExtensionReturnmap.values());
        
        if (!String.isEmpty(projectCSV) || !String.isEmpty(projectExtensionCSV)) {
            sendEmailWithAttachments(projectCSV, 'ProjectData.csv', projectExtensionCSV, 'ProjectExtensionData.csv');
        } else {
            System.debug('No records found, no email sent.');
        }
    }

    // Method to safely convert Old_Value__c to a formatted Date string
    public static String convertToDate(Object value) {
        if (value == null) {
            return '';
        }
        try {
            if (value instanceof Date) {
                return ((Date)value).format();
            } else if (value instanceof String) {
                String dateStr = String.valueOf(value);
                if (Pattern.matches('\\d{4}-\\d{2}-\\d{2}', dateStr)) {
                    return dateStr;
                }
                return Date.parse(dateStr).format();
            }
            return String.valueOf(value);  // Return as is if it's not a date or string
        } catch (Exception e) {
            return String.valueOf(value); // Return original value if conversion fails
        }
    }

    // Method to convert List<SObject> to CSV format
    public static String convertSObjectListToCSV(List<SObject> records) {
        if (records.isEmpty()) {
            return '';
        }
        
        // Get field names dynamically from first record
        List<String> fieldNames = new List<String>(records[0].getPopulatedFieldsAsMap().keySet());
        String csvHeader = String.join(fieldNames, ',');  // Create CSV header
        
        List<String> csvRows = new List<String>();
        csvRows.add(csvHeader);
        
        // Iterate over records and extract field values
        for (SObject record : records) {
            List<String> fieldValues = new List<String>();
            for (String field : fieldNames) {
                Object value = record.get(field);
                fieldValues.add(value != null ? '"' + String.valueOf(value).replace('"', '""') + '"' : '');  // Handle null & escape quotes
            }
            csvRows.add(String.join(fieldValues, ','));
        }
        
        return String.join(csvRows, '\n');
    }

    // Method to send email with CSV attachments
    public static void sendEmailWithAttachments(String csvData1, String fileName1, String csvData2, String fileName2) {
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] {'masthan.andela@harmonitowers.com'}); // Change to recipient email
        mail.setSubject('Project & Project Extension Data');
        mail.setPlainTextBody('Please find attached the CSV reports.');
        
        // Create attachments
        Messaging.EmailFileAttachment attachment1 = new Messaging.EmailFileAttachment();
        attachment1.setFileName(fileName1);
        attachment1.setBody(Blob.valueOf(csvData1));
        
        Messaging.EmailFileAttachment attachment2 = new Messaging.EmailFileAttachment();
        attachment2.setFileName(fileName2);
        attachment2.setBody(Blob.valueOf(csvData2));
        
        mail.setFileAttachments(new Messaging.EmailFileAttachment[] {attachment1, attachment2});
        // Send email
        if(!Test.isRunningTest())
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
    }
}
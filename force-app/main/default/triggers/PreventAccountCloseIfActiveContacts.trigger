trigger PreventAccountCloseIfActiveContacts on Account (before Update) {
    for(Account acc : Trigger.new){

        if(acc.Account_Status__c == 'Closed'){

            List<Contact> conList = [
                SELECT Id, Contact_Status__c, AccountId
                FROM Contact
                WHERE AccountId = :acc.Id
            ];

            for(Contact con : conList){

                if(con.Contact_Status__c == 'Active'){
                    acc.addError('Cannot close account because related contact is Active');
                }

            }
        }
    }
}
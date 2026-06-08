@istest
global without sharing class relatedSobjectTest {
    final static integer NUMBER_OF_ACCOUNTS_USER_ONE = 5;
    final static integer NUMBER_OF_ACCOUNTS_USER_TWO = 2;
    @TestSetup
    static void makeData(){
        Profile[] profiles = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        user[] users = new user[]{};
        users.add(
            new user(
                lastname='one',
                Username= math.random()+'one@example.com', 
                Email = 'one@example.com', 
                Alias = 'one', 
                profileid = profiles[0].id,
                TimeZoneSidKey= 'GMT', 
                LocaleSidKey ='en_US', 
                EmailEncodingKey='UTF-8', 
                LanguageLocaleKey='en_US'
            )
        );
        users.add(
            new user(
                lastname='two',
                Username=math.random()+ 'two@example.com', 
                Email = 'two@example.com', 
                Alias = 'two', 
                profileid = profiles[0].id,
                TimeZoneSidKey= 'GMT', 
                LocaleSidKey ='en_US', 
                EmailEncodingKey='UTF-8', 
                LanguageLocaleKey='en_US'
            )
        );
        users.add(
            new user(
                lastname='three',
                Username= math.random()+'three@example.com', 
                Email = 'three@example.com', 
                Alias = 'three', 
                profileid = profiles[0].id,
                TimeZoneSidKey= 'GMT', 
                LocaleSidKey ='en_US', 
                EmailEncodingKey='UTF-8', 
                LanguageLocaleKey='en_US'
            )
        );
        insert users;
        //OwnerId is a user id
        for(integer i = 0;i<relatedSobjectTest.NUMBER_OF_ACCOUNTS_USER_ONE; i++){
            insert new account(
                name='one ' + string.valueof(i),
                ownerid = users[0].id
            );
        }
        for(integer i = 0;i<relatedSobjectTest.NUMBER_OF_ACCOUNTS_USER_TWO; i++){
            insert new account(
                name='two ' + string.valueof(i),
                ownerid = users[1].id
            );
        }
    }
    @isTest
    static void getCorrectChildrenTest(){
        user[] users = [SELECT id FROM user];
        user userOne = [SELECT id FROM user where lastname = 'one'];
        user userTwo = [SELECT id FROM user where lastname = 'two'];
        user userThree = [SELECT id FROM user where lastname = 'three'];
        relatedSObject accounts = new relatedSObject(
            users,
            'account',
            Schema.account.ownerid
        );
        System.assertEquals(NUMBER_OF_ACCOUNTS_USER_ONE,accounts.getSpecificSobject(userOne).size());
        System.assertEquals(NUMBER_OF_ACCOUNTS_USER_TWO,accounts.getSpecificSobject(userTwo).size());
        System.assertEquals(0,accounts.getSpecificSobject(userThree).size());

    }
    @isTest
    static void getCorrectParentsTest(){
        account[] accounts = [select name,id,ownerId from account];
        relatedSObject users = new relatedSObject(
            accounts,
            'account',
            Schema.account.ownerid
        );
        for(account acc : accounts){
            if(acc.name.contains('one')){
                System.assertEquals('one',users.getSpecificSobject(acc)[0].get(Schema.user.lastname));
            }else if(acc.name.contains('two')){
                System.assertEquals('two',users.getSpecificSobject(acc)[0].get(Schema.user.lastname));
            }else{
                System.assert(false);
            }
        }
        

    }
    @istest
    static void getAllMapTest(){
        account[] accounts = [select name,id,ownerId from account];
        user[] users = [SELECT id FROM user];
        relatedSObject relatedUsers = new relatedSObject(
            accounts,
            'account',
            Schema.account.ownerid
        );
        relatedSObject relatedAccounts = new relatedSObject(
            users,
            'account',
            Schema.account.ownerid
        );
        System.assertEquals(2,relatedUsers.getAllRelatedSobjects().values().size());
        System.assertEquals(NUMBER_OF_ACCOUNTS_USER_ONE + NUMBER_OF_ACCOUNTS_USER_TWO,relatedAccounts.getAllRelatedSobjects().values().size());
    }
    @istest
    static void updateParent(){
        account[] accounts = [select name,id,ownerId from account];
        relatedSObject relatedUsers = new relatedSObject(
            accounts,
            'account',
            Schema.account.ownerid
        );
        user parentObject = ((list<user>)relatedUsers.getSpecificSobject(accounts[0]))[0];

        relatedUsers.updateObjects(
            accounts[0], 
            Schema.account.name, 
            Schema.user.firstname
        );
        relatedUsers.saveChangesToDB();
        parentObject = [SELECT id,firstname from user where id = :parentObject.id];
        System.assertEquals(
            accounts[0].name,
            ParentObject.firstname
        );
        relatedUsers.updateObjects(
            accounts[0], 
            'hi', 
            Schema.user.firstname
        );
        relatedUsers.saveChangesToDB();
        parentObject = [SELECT id,firstname from user where id = :parentObject.id];
        System.assertEquals(
            'hi',
            ParentObject.firstname
        );
        parentObject = ((list<user>)relatedUsers.getSpecificSobject(accounts[1]))[0];

        relatedUsers.updateObjects(
            accounts[1], 
            Schema.account.name, 
            Schema.user.firstname
        );
        relatedUsers.saveChangesToDB();
        parentObject = [SELECT id,firstname from user where id = :parentObject.id];
        System.assertEquals(
            accounts[1].name,
            ParentObject.firstname
        );
        relatedUsers.updateObjects(
            accounts[1], 
            'hi', 
            Schema.user.firstname
        );
        relatedUsers.saveChangesToDB();
        parentObject = [SELECT id,firstname from user where id = :parentObject.id];
        System.assertEquals(
            'hi',
            ParentObject.firstname
        );



    }
    @istest
    static void updateChildren(){
        user[] users = [SELECT id,LastName FROM user where lastname='one' or lastname='two'];
        relatedSObject relatedAccounts = new relatedSObject(
            users,
            'account',
            Schema.account.ownerid
        );
        account[] childrenObjects = ((list<account>)relatedAccounts.getSpecificSobject(users[0]));
        system.debug(users);
        system.debug(childrenObjects);
        relatedAccounts.updateObjects(
            users[0], 
            Schema.user.lastname,
            Schema.account.description
        );
        relatedAccounts.saveChangesToDB();
        childrenObjects = [SELECT id,description from account where id IN :relatedSobjectTest.getIdsFromSobject(childrenObjects)];
        System.assert(childrenObjects.size()>0);
        for(account acc : childrenObjects){
            System.assertEquals(
                users[0].lastname,
                acc.description
            );

        }
        relatedAccounts.updateObjects(
            users[0], 
            'hi', 
            Schema.account.description
        );
        relatedAccounts.saveChangesToDB();
        childrenObjects = [SELECT id,description from account where id IN :relatedSobjectTest.getIdsFromSobject(childrenObjects)];
        System.assert(childrenObjects.size()>0);
        for(account acc : childrenObjects){
            System.assertEquals(
                'hi',
                acc.description
            );
        }

    }
   static private set<id> getIdsFromSobject(sobject[] objList){
        set<id> ids = new set<id>();
        for(sobject obj : objList){
            ids.add((id)obj.get('id'));
        }
        system.debug('idididid ' + ids);
        return ids;
    }
}
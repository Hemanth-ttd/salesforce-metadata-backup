@isTest
public class HT_CloneUserFromExistingTest {

    @TestSetup
    static void setupData() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User existingUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            Email = 'testuser@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            ProfileId = p.Id
        );
        insert existingUser;

        PermissionSet ps = new PermissionSet(Name = 'TestPermissionSet',label='TestPermissionSet');
        insert ps;

        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = existingUser.Id,
            PermissionSetId = ps.Id
        );
        insert psa;

        

        UserPackageLicense upl = new UserPackageLicense(
            PackageLicenseId = '0501I000000Gp4fQAC',
            UserId = existingUser.Id
        );
        insert upl;
    }

    @isTest
    static void testCloneUser() {
        User existingUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        
        HT_CloneUserFromExisting.InputWrapper input = new HT_CloneUserFromExisting.InputWrapper();
        input.existingUserId = existingUser.Id;
        input.firstName = 'Cloned';
        input.lastName = 'User';
        input.alias = 'cuser';
        input.username = 'cloneduser' + DateTime.now().getTime() + '@example.com';
        input.email = 'cloneduser@example.com';
        input.packageLicenseId = '0501I000000Gp4fQAC';

        List<HT_CloneUserFromExisting.InputWrapper> inputList = new List<HT_CloneUserFromExisting.InputWrapper>{input};

        Test.startTest();
        List<HT_CloneUserFromExisting.OutputWrapper> results = HT_CloneUserFromExisting.cloneUser(inputList);
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertNotEquals(null, results[0].newUserId);
        System.assertEquals('User created and configured successfully.', results[0].statusMessage);
    }

    @isTest
    static void testCloneUserWithException() {
        HT_CloneUserFromExisting.InputWrapper input = new HT_CloneUserFromExisting.InputWrapper();
        input.existingUserId = null; // Invalid ID to trigger exception
        input.firstName = 'Error';
        input.lastName = 'User';
        input.alias = 'euser';
        input.username = 'erroruser' + DateTime.now().getTime() + '@example.com';
        input.email = 'erroruser@example.com';
        input.packageLicenseId = '00h000000000000'; // Dummy ID
        List<HT_CloneUserFromExisting.InputWrapper> inputList = new List<HT_CloneUserFromExisting.InputWrapper>{input};

        Test.startTest();
        List<HT_CloneUserFromExisting.OutputWrapper> results = HT_CloneUserFromExisting.cloneUser(inputList);
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assert(results[0].statusMessage.startsWith('Error:'));
    }
}
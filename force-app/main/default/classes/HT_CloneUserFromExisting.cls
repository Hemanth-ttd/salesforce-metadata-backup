public class HT_CloneUserFromExisting {
    
    public class InputWrapper {
        @InvocableVariable(required=true)
        public Id existingUserId;

        @InvocableVariable(required=true)
        public String firstName;

        @InvocableVariable(required=true)
        public String lastName;

        @InvocableVariable(required=true)
        public String alias;

        @InvocableVariable(required=true)
        public String username;

        @InvocableVariable(required=true)
        public String email;

        @InvocableVariable(required=true)
        public String packageLicenseId;
    }

    public class OutputWrapper {
        @InvocableVariable
        public Id newUserId;

        @InvocableVariable
        public String statusMessage;
    }

    @InvocableMethod(label='Clone User and Assign Permissions' description='Clones an existing user, assigns same permission sets and package license.')
    public static List<OutputWrapper> cloneUser(List<InputWrapper> inputList) {
        List<OutputWrapper> results = new List<OutputWrapper>();

        for (InputWrapper input : inputList) {
            OutputWrapper output = new OutputWrapper();
            try {
                User existingUser = [
                    SELECT FirstName, LastName, Email, Username, ProfileId, 
                           UserRoleId, TimeZoneSidKey, LocaleSidKey, 
                           EmailEncodingKey, LanguageLocaleKey 
                    FROM User 
                    WHERE Id = :input.existingUserId
                    LIMIT 1
                ];

                User newUser = existingUser.clone(false, true);
                newUser.FirstName = input.firstName;
                newUser.LastName = input.lastName;
                newUser.Alias = input.alias;
                newUser.Username = input.username;
                newUser.Email = input.email;
                newUser.IsActive = true;
                insert newUser;

                List<PermissionSetAssignment> oldPermissions = [
                    SELECT PermissionSetId 
                    FROM PermissionSetAssignment 
                    WHERE AssigneeId = :input.existingUserId 
                    AND PermissionSet.ProfileId = null
                ];

                List<PermissionSetAssignment> newPermissions = new List<PermissionSetAssignment>();
                for (PermissionSetAssignment perm : oldPermissions) {
                    newPermissions.add(new PermissionSetAssignment(
                        AssigneeId = newUser.Id,
                        PermissionSetId = perm.PermissionSetId
                    ));
                }

                if (!newPermissions.isEmpty()) {
                    insert newPermissions;
                }

                UserPackageLicense license = new UserPackageLicense();
                license.PackageLicenseId = input.packageLicenseId;
                license.UserId = newUser.Id;
                insert license;

                System.resetPassword(newUser.Id, true);

                output.newUserId = newUser.Id;
                output.statusMessage = 'User created and configured successfully.';
            } catch (Exception e) {
                output.statusMessage = 'Error: ' + e.getMessage();
            }
            results.add(output);
        }
        return results;
    }
}
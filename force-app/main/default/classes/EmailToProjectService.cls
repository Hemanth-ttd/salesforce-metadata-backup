global class EmailToProjectService implements Messaging.InboundEmailHandler {

	global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
	  	Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
	  	
		String[] ccAddresses = email.ccAddresses;
		String[] toAddresses = email.toAddresses;
		String[] emailThreadIds = email.references;

		String sender = email.fromAddress;
		String inReplyTo = email.inReplyTo;
		String htmlBody = email.htmlBody;
		String subject = email.subject;

		String recipients = '';

		recipients += ( toAddresses != null ? String.join( toAddresses, ';' ) : '' );
		recipients += ( ccAddresses != null ? String.join( ccAddresses, ';' ) : '' );

		Messaging.InboundEmail.BinaryAttachment[] binaryAttachments = email.binaryAttachments;
		Messaging.InboundEmail.TextAttachment[] textAttachments = email.textAttachments;

		Integer attachmentSize = ( binaryAttachments != null 
										? binaryAttachments.size() 
										: 0 );
		attachmentSize += ( textAttachments != null 
								? textAttachments.size()
								: 0 );

		// get the settings config 
		List<Email_To_Object_Setting__mdt> settings = getActiveSetting();

		if( settings != null ){

			// get the project ID
			String objectName = getObjectId( settings[ 0 ], email );

			if( objectName != null ){
				sObject record = getRecordValue( settings[ 0 ], objectName );

				if( record != null ){
					Id recordId = ( Id )record.get( 'id' );
					System.debug( 'Record Id: ' + recordId );

					Project_Email_Thread__c emailThread = getRelatedEmailThread( email, recordId );

					if( emailThread.Thread_Id__c == null && emailThreadIds != null && emailThreadIds.size() > 0  ){
						emailThread.Thread_Id__c = emailThreadIds[ 0 ];

						try{
							Database.update( emailThread );
						}
						catch( Exception ex ){
							System.debug( 'Error updating thread with Thread Id: ' + ex.getMessage() );
						}
					}

					if( emailThread != null ){
						Project_Email__c pEmail = createEmail( emailThread, email );

						// create any attachments 
						if( pEmail != null && pEmail.of_Attachments__c > 0 ){

							if( binaryAttachments != null && binaryAttachments.size() > 0 ){

								for( Messaging.InboundEmail.BinaryAttachment attachment : binaryAttachments ){

									ContentVersion file = CreateFileFromAttachment( attachment );
									CreateFileLinks( file, pEmail.Id, emailThread.Id );
								}
							}

							if( textAttachments != null && textAttachments.size() > 0 ){
								for( Messaging.InboundEmail.TextAttachment attachment : textAttachments ){

									ContentVersion file = CreateFileFromAttachment( attachment );
									CreateFileLinks( file, pEmail.Id, emailThread.Id );
								}
							}
						}
					}

					// update the attachment count on the thread
					emailThread.of_Attachments__c = ( emailThread.of_Attachments__c == null ?  attachmentSize : emailThread.of_Attachments__c + attachmentSize );

					try{
						Database.update( emailThread );
					}
					catch( Exception ex ){
						System.debug( 'Error updating number of attachments: ' + ex.getMessage() );
					}
				}
			}
		}
		return result;
	}

	// create an email entry on this thread
	public Project_Email__c createEmail( Project_Email_Thread__c thread, Messaging.InboundEmail email ){
		String recipients = '';
		recipients += ( email.toAddresses != null ? String.join( email.toAddresses, ';' ) : '' );
		recipients += ( email.ccAddresses != null ? String.join( email.ccAddresses, ';' ) : '' );

		Integer attachmentSize = 0;
		attachmentSize += ( email.binaryAttachments != null ? email.binaryAttachments.size() : 0 );
		attachmentSize += ( email.textAttachments != null ? email.textAttachments.size() : 0 );

		Project_Email__c pEmail = new Project_Email__c(
			Project_Email_Thread__c = thread.Id,
			Email_Thread_Id__c = thread.Thread_Id__c,
			Subject__c = email.subject, 
			Recipients__c = recipients,
			of_Attachments__c = attachmentSize,
			Project__c = thread.Project__c,
			Message__c = ( email.htmlBody != null ? email.htmlBody : ( email.plainTextBody != null ? email.plainTextBody : '' ) ),
			Sender__c = email.fromAddress
		);

		try{
			Database.insert( pEmail );
		}
		catch( Exception ex ){
			System.debug( 'Error inserting email into thread - ' + thread.Id + ': ' + ex.getMessage() );
			pEmail = null;
		}

		return pEmail;
	}

	// gets the Related Email thread that may be active already - if no thread is found - a new thread will be started 
	public Project_Email_Thread__c getRelatedEmailThread( Messaging.InboundEmail email, Id projectRecordId ){

		Project_Email_Thread__c result = null;
		String references = ( email.references != null ? email.references[ 0 ] : '' );
		String subjectText = email.subject;

		if( subjectText.contains( 'RE:')){
			subjectText = subjectText.Remove( 'RE:' ).trim();
		}

		if( subjectText.contains( 'FW:' )){
			subjectText = subjectText.Remove( 'FW:' ).trim();
		}

		System.debug( 'SubjectText: ' + subjectText );

		String subjectLike = ( !String.isBlank( subjectText ) ? ( '%' + subjectText + '%' ) : '' );

		String threadQuery = 'SELECT Id, Thread_Subject__c, Thread_Id__c, Project__c, of_Attachments__c '
							+ ' FROM Project_Email_Thread__c '
							+ ' WHERE Thread_Subject__c = \'' +  subjectText + '\' '
							+ ' AND Project__c = \'' + projectRecordId + '\' LIMIT 1';

		System.debug( 'Thread Query: ' + threadQuery );

		List<Project_Email_Thread__c> resultList;

		try{
			resultList = Database.query( threadQuery );
		}
		catch( Exception ex ){
			System.debug( 'Error fetching Project Email Threads: ' + ex.getMessage() );
		}

		System.debug( 'Result List: ' + resultList );

		if( resultList != null && resultList.size() > 0 ){
			result = resultList[ 0 ];
		}
		else{
			result = new Project_Email_Thread__c(
				Thread_Subject__c = subjectText,
				Project__c = projectRecordId
			);

			try{
				Database.insert( result );
			}
			catch( Exception ex ){
				System.debug( 'Error inserting New Project Email Thread: ' + ex.getMessage() );

				result = null;
			}
		}

		System.debug( 'Thread Result: ' + result );

		return result;
	}

	// get the project that matches the Id found as long as the status configured meets the criteria 
	public sObject getRecordValue( Email_To_Object_Setting__mdt settings, String objectIdValue ){
		SObject result = null;

		String objectType = ( settings != null 
								? settings.Object_Type__c 
								: '' );
		String projectObject = ( settings != null 
									? settings.Project_Object__c 
									: '' );
		String siteObject = ( settings != null 
								? settings.Site_Object__c 
								: '' );
		String statusField = ( settings != null && settings.Use_Site_Status_Field__c 
									? settings.Site_Status_Field__c 
									: settings.Project_Status_Field__c );


		Set<String> notStatuses = new Set<String>();

		if( settings != null 
			&& settings.Statuses_To_Ignore__c.contains( ';' )){

			notStatuses.addAll( settings.Statuses_To_Ignore__c.split( ';' ) );
		}
		else if( settings != null
				 && !String.isBlank( settings.Statuses_To_Ignore__c ) 
				 && !settings.Statuses_To_Ignore__c.contains( ';' )){

			notStatuses.add( settings.Statuses_To_Ignore__c );
		}

		String query = 'SELECT Id FROM ';

		if( settings != null && !settings.Use_Site_Status_Field__c ){
			// add in the project values into the query 
			query += settings.Project_Object__c 
					+ ' WHERE Name LIKE \'%' + objectIdValue.substring( 2, objectIdValue.length() ) + '\''
					+ ' AND ( NOT( ' 
					+ settings.Project_Status_Field__c 
					+ ' IN ( ' ;
			for( String status : notStatuses ){
				query += '\'' + status.trim() + '\',';
			}

			query = query.removeEnd( ',' ) + ' )) )';

		}
		else if( settings != null && settings.Use_Site_Status_Field__c ){
			// Add in the Site values into the query 
			query += settings.Project_Object__c
					+ ' WHERE Name LIKE \'%' + objectIdValue.substring( 2, objectIdValue.length() ) + '\''
					+ ' AND ( NOT( '
					+ settings.Site_Status_Field__c
					+ ' IN ( ';

			for( String status : notStatuses ){
				query += '\'' + status.trim() + '\',';
			}

			query = query.removeEnd( ',' ) + ' )) )';
		}

		query += ' LIMIT 1';

		System.debug( 'Query: ' + query );

		try{
			List<sObject> resultsList = Database.query( query );

			if( resultsList != null && resultsList.size() > 0 ){
				result = resultsList[ 0 ];
			}
		}
		catch( Exception ex ){
			System.debug( 'Error happened when fetching the object to email: ' + ex.getMessage() );
			result = null;
		}

		System.debug( 'Project Record Result: ' + result );
		return result;
	}

	// get the config settings from the meta 
	public List<Email_To_Object_Setting__mdt> getActiveSetting(){
		return  [ 	SELECT Id, DeveloperName, MasterLabel, Active__c, Object_Type__c, Project_Object__c, Project_Status_Field__c, Alt_Search_Field__c, Search_Field__c, Site_Object__c, Site_Status_Field__c, Statuses_To_Ignore__c, Use_Site_Status_Field__c
					FROM Email_To_Object_Setting__mdt
					WHERE Active__c =: true
					LIMIT 1 
				];
	}

	public void CreateFileLinks( ContentVersion file, Id projectEmailId, Id projectEmailThreadId ){

		List<ContentDocumentLink> links = new List<ContentDocumentLink>();
		links.add( new ContentDocumentLink(
			LinkedEntityId = projectEmailId,
			ShareType = 'V',
			ContentdocumentId = file.ContentdocumentId
		));
		links.add( new ContentDocumentLink(
			LinkedEntityId = projectEmailThreadId,
			ShareType = 'V',
			ContentdocumentId = file.ContentdocumentId
		));

		try{
			Database.insert( links );
		}
		catch( Exception ex ){
			System.debug( 'Error inserting file links: ' + ex.getMessage() );
		}
	}

	// Creates a Salesforce File from an email attachment
	public ContentVersion CreateFileFromAttachment( Messaging.InboundEmail.BinaryAttachment attachment ){

		String fileName = attachment.FileName; 

		String path =  attachment.FileName; 

		Blob content = attachment.Body; 

		ContentVersion file = new ContentVersion(
			VersionData = content,
			Title = fileName,
			PathOnClient = path
		);

		try{
			Database.insert( file );
		}
		catch( Exception ex ){
			System.debug( 'Error inserting File from attachment: ' + ex.getMessage() );
		}

		file = [ SELECT Id, ContentdocumentId, VersionData, Title, PathOnClient FROM ContentVersion WHERE Id =: file.Id LIMIT 1 ];

		return file;
	}

	// Creates a Salesforce File from an email attachment
	public ContentVersion CreateFileFromAttachment( Messaging.InboundEmail.TextAttachment attachment ){

		String fileName = attachment.FileName;

		String path = attachment.FileName;

		Blob content = Blob.valueOf( attachment.Body );

		ContentVersion file = new ContentVersion(
			VersionData = content,
			Title = fileName,
			PathOnClient = path
		);

		try{
			Database.insert( file );
		}
		catch( Exception ex ){
			System.debug( 'Error inserting File from attachment: ' + ex.getMessage() );
		}

		file = [ SELECT Id, ContentdocumentId, VersionData, Title, PathOnClient FROM ContentVersion WHERE Id =: file.Id LIMIT 1 ];

		return file;
	}

	// use the config to extract the project Id from specified field(s)
	public String getObjectId( Email_To_Object_Setting__mdt settings, Messaging.InboundEmail email ){

		String searchField = ( settings != null ? settings.Search_Field__c : '' );
		String altSearchField = ( settings != null ? settings.Alt_Search_Field__c : '' );
		Boolean searchSubject = false;
		Boolean searchRecipients = false;
		String result = '';

		if( !String.isBlank( searchField ) && searchField.toLowerCase().trim().Equals( 'toaddresses' )){
			searchRecipients = true;
		}
		else if( !String.isBlank( searchField ) && searchField.toLowerCase().trim().Equals( 'subject' )){
			searchSubject = true;
		}

		if( !String.isBlank( altSearchField ) && altSearchField.toLowerCase().trim().Equals( 'toaddresses' )){
			searchRecipients = true;
		}
		else if( !String.isBlank( altSearchField ) && altSearchField.toLowerCase().trim().Equals( 'subject' )){
			searchSubject = true;
		}

		// try to return the project number from the recipients 
		if( searchRecipients ){
			Integer startIndex = -1;
			String recipients = '';
			String holder = '';

			recipients += ( email.toAddresses != null 
								? String.join( email.toAddresses, ';' )
								:'');
			recipients += ( email.ccAddresses != null 
								? String.join( email.ccAddresses, ';' )
								: '' );


			try{
				if( !String.isblank( recipients ) && recipients.toLowerCase().indexOf( 'p-' ) != -1 ){
					startIndex = recipients.toLowerCase().indexOf( 'p-' );
				}

				if( startIndex != -1 ){
					holder = recipients.substring( startIndex, recipients.length() );
				}

				if( !String.isBlank( holder )){
					Integer endIndex = holder.toLowerCase().indexOf( '@' );

					if( endIndex != -1 ){
						result = holder.substring( 0, endIndex );
					}
					else{
						result = holder.substring( 0, holder.length() );
					}
				}
			}
			catch( Exception ex ){
				System.debug( 'Error happened while parsing value from recipients: ' + ex.getMessage() );
				result = '';
			}

		}
		// try to return the project from the subject if it was not found previously
		if( searchSubject && String.isBlank( result )){

			try{
			Integer startIndex = -1;
			String subjectText = email.subject;
			String holder = '';

				if( !String.isBlank( subjectText ) && subjectText.toLowerCase().indexOf( 'p-' ) != -1 ){
					startIndex = subjectText.toLowerCase().indexOf( 'p-' );
				}

				if( startIndex != -1 ){
					holder = subjectText.substring( startIndex, subjectText.length() );
				}

				if( !String.isBlank( holder )){
					Integer endIndex = holder.toLowerCase().indexOf( ' ' );

					if( endIndex != -1 ){
						result = holder.substring( 0, endIndex );
					}
					else{
						result = holder.substring( 0, holder.length() );
					}
				}
			}
			catch( Exception ex ){
				System.debug( 'Error appened while parsing value from subject Text: ' + ex.getMessage() );
				result = '';
			}
		}

		System.debug( 'Project Id Result: ' + result );

		return result;
	}
}
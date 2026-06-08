global class ProjectEmailService implements Messaging.InboundEmailHandler{

 	global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
	  	Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
	  	

	  	String[] ccAddresses = email.ccAddresses;
	  	String[] toAddresses = email.toAddresses;
	  	String[] emailThreadId = email.references;

	  	String fromAddress = email.fromAddress;
	  	String inReplyTo = email.inReplyTo;
	  	String htmlBody = email.htmlBody;
	  	String subject = email.subject;


	  	String recipients = '';

	  	recipients += ( toAddresses != null ? String.join( toAddresses, ';' ) : '' );
	  	recipients += ( ccAddresses != null ? String.join( ccAddresses, ';' ) : '' );

	  	Messaging.InboundEmail.BinaryAttachment[] attachments = email.binaryAttachments;
	  	Messaging.InboundEmail.TextAttachment[] textAttachments = email.textAttachments;

	  	Integer attachmentsSize = ( attachments != null ? attachments.Size() : ( textAttachments != null ? textAttachments.Size() : 0 ) );

	  	System.debug( 'Attachments: ' + attachments );
	  	System.debug( 'ccAddresses: ' + ccAddresses );
	  	System.debug( 'toAddresses: ' + toAddresses );
	  	System.debug( 'From Address: ' + fromAddress );
	  	System.debug( 'Html Body: ' + htmlBody );
	  	System.debug( 'inReplyTo: ' + inReplyTo );
	  	System.debug( 'emailThreadId: ' + emailThreadId );
	  	System.debug( 'Subject: ' + subject );
	  	System.debug( 'Recipients: ' + recipients );

	  	String projectId = getProjectIdFromToField( recipients ); //getProjectIdFromSubject( subject );
      System.debug( 'Project Id: ' + projectId );

	  	String threadId = ( emailThreadId != null ? emailThreadId[ 0 ] : null );

	  	List<strk__Project__c> projects = getRelatedProjects( projectId );

      System.debug( 'Projects: ' + projects );

	  	if( projects != null && projects.size() > 0 ){
	  		System.debug( 'Project Found...' );
	  		System.debug( 'Project: ' + projects[ 0 ] );

	  		Project_Email_Thread__c thread = getRelatedEmailThread( threadId, subject, projects[ 0 ].Id );

	  		System.debug( 'Thread: ' + thread );

	  		//  if we have an email thread - let's add to it 
	  		if( thread != null && thread.Id != null ){

	  			if( thread.Thread_Id__c == null && !String.isBlank( threadId )){
	  				thread.Thread_Id__c = threadId;

	  				try{
	  					Database.update( thread );
	  				}
	  				catch( Exception ex ){
	  					System.debug( 'Error updating thread Id: ' + ex.getMessage() );
	  				}
	  			}
	  			// create the entry associated to this tthread and save the entry
	  			Project_Email__c mEmail = new Project_Email__c(
	  				Project_Email_Thread__c = thread.Id,
	  				Email_Thread_Id__c = threadId,
	  				Subject__c = subject,
	  				Recipients__c = recipients,
	  				of_Attachments__c = attachmentsSize,
	  				Project__c = projects[ 0 ].Id,
	  				Message__c = htmlBody,
	  				Sender__c = fromAddress
  				);

  				try{
  					Database.insert( mEmail );
  				}
  				catch( Exception ex ){
  					System.debug( 'Error inserting email to project email thread: ' + ex.getMessage() );
  				}

  				System.debug( 'Email: ' + mEmail );
  				// evaluate attachments if any were found and create a link to the email thread for the attachments 

  				if( attachmentsSize != null && attachmentsSize > 0 ){

  					// if binary attachments 
  					if( attachments != null ){

  						for( Messaging.InboundEmail.BinaryAttachment attachment : attachments ){
  							// create a file and link to the email thread and the email
  							ContentVersion file = new ContentVersion();
  							file.VersionData = attachment.Body;
  							file.Title = attachment.FileName;
  							file.PathOnClient = attachment.FileName;

  							try{
  								Database.insert( file );
  							}
  							catch( Exception ex ){
  								System.debug( 'Error inserting attachment as file: ' + ex.getMessage() );
  							}

  							if( file.Id != null ){
	  							file = [ SELECT ContentDocumentId FROM ContentVersion WHERE Id =: file.Id LIMIT 1 ];

	  							CreateFileLinks( file, mEmail.Id, thread.Id );
	  						}

  						}
  					}
  					// if text attachments 
  					if( textAttachments != null ){

  						for( Messaging.InboundEmail.TextAttachment attachment : textAttachments ){
  							// create a file and link to the email thread and the email
  							ContentVersion file = new ContentVersion();
  							file.VersionData = Blob.ValueOf( attachment.Body );
  							file.Title = attachment.FileName;
  							file.PathOnClient = attachment.FileName;

  							try{
  								Database.insert( file );
  							}
  							catch( Exception ex ){
  								System.debug( 'Error inserting attachment as file: ' + ex.getMessage() );
  							}

  							if( file.Id != null ){
	  							file = [ SELECT ContentDocumentId FROM ContentVersion WHERE Id =: file.Id LIMIT 1 ];

	  							CreateFileLinks( file, mEmail.Id, thread.Id );
	  						}
  						}
  					}
  				}
  				// update the number of attachments for the thread
				thread.of_Attachments__c = [ SELECT Count() FROM ContentDocumentLink WHERE LinkedEntityId =: thread.Id ];

				try{
					Database.update( thread );
				}
				catch( Exception ex ){
					System.debug( 'Error updating Thread attachment Count: ' + ex.getMessage() );
				}
	  		}
	  	}


	  	System.debug( 'Handler Executed');
	  	
      	return result;
  	}
  	
  	global static void CreateFileLinks( ContentVersion cv, Id emailId, Id threadId ){
  		List<ContentDocumentLink> links = new List<ContentDocumentLink>();
  		links.add( new ContentDocumentLink(
  			LinkedEntityId = emailId,
  			ShareType = 'V',
  			ContentDocumentId = cv.ContentDocumentId
		  ));
  		links.add( new ContentDocumentLink(
  			LinkedEntityId = threadId,
  			ShareType = 'V',
  			ContentDocumentId = cv.ContentDocumentId
  		));

  		try{
  			Database.insert( links, false );
  		}
  		catch( Exception ex ){
  			System.debug( 'Error inserting file Links: ' + ex.getMessage() );
  		}
  	}
  	// get the priject name from the subject text line
  	global static String getProjectIdFromSubject( String subjectText ){

  		String result;
  		Integer startIndex;
  		String subjectTemp;

      // if no dice - find in the subject 
      startIndex = subjectText.toLowerCase().indexOf( 'p-' );

  		if( startIndex != -1 ){
  			subjectTemp = subjectText.substring( startIndex, subjectText.length() );
  		}

  		if( !String.isBlank( subjectTemp )){
  			Integer endIndex = subjectTemp.toLowerCase().indexOf( ' ' );
  			if( endIndex != -1 ){
  				result = subjectTemp.substring( 0, endIndex );
  			}
  			else{
  				result = subjectTemp.substring( 0, subjectTemp.length() );
  			}
  		}

  		return result;
  	}

    // get the priject name from the subject text line
    global static String getProjectIdFromToField( String recipients ){

      String result;
      Integer startIndex;
      String receiptTemp;

      // if no dice - find in the subject 
      startIndex = recipients.toLowerCase().indexOf( 'p-' );

      if( startIndex != -1 ){
        receiptTemp = recipients.substring( startIndex, recipients.length() );
      }

      if( !String.isBlank( receiptTemp )){
        Integer endIndex = receiptTemp.toLowerCase().indexOf( '@' );
        if( endIndex != -1 ){
          result = receiptTemp.substring( 0, endIndex );
        }
        else{
          result = receiptTemp.substring( 0, receiptTemp.length() );
        }
      }

      System.debug( 'Result: ' + result );

      return result;
    }

  	// get the project that is associated to this email
  	global static List<strk__Project__c> getRelatedProjects( String projectName ){
  		List<strk__Project__c> results;

  		if( !String.isBlank( projectName )){
  			results = [ SELECT Id, Name FROM strk__Project__c WHERE Name =: projectName LIMIT 1 ];
  		}

  		return results;
  	}

  	// get the related thread or make a new one 
  	global static Project_Email_Thread__c getRelatedEmailThread( String threadId, String subjectText, Id projectId ){
  		Project_Email_Thread__c result;

  		if( !String.isBlank( subjectText ) && subjectText.Contains( 'RE:')){
  			subjectText = subjectText.Remove( 'RE:' ).trim();
  		}
  		String subjectLike = '%' + subjectText + '%';

  		List<Project_Email_Thread__c> threads = [ SELECT Id, Thread_Subject__c, Thread_Id__c, Project__c FROM Project_Email_Thread__c WHERE  ( Thread_Id__c =: threadId OR Thread_Subject__c LIKE: subjectLike ) AND Project__c =: projectId LIMIT 1 ];

  		if( threads != null && threads.size() > 0 ){
  			
  			result = threads[ 0 ];

  			System.debug( 'Result: ' + result );
  		}
  		else{
  			// make a new Thread instance
  			result = new Project_Email_Thread__c(
  				Thread_Subject__c = subjectText,
  				Project__c = projectId
			);

			try{
				Database.insert( result );
			}
			catch( Exception ex ){
				System.debug( 'Error inserting new Project Email Thread: ' + ex.getMessage() );
			}

  			System.debug( 'Result: ' + result );
  		}

  		return result;
  	}	
}
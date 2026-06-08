/*************************************************************************************************
 * SITETRACKER, INC. (“Sitetracker”) CONFIDENTIAL
 * Unpublished Copyright (c) 2013-2023 SITETRACKER, INC., All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of Sitetracker.
 * The intellectual and technical concepts contained herein are proprietary to Sitetracker and
 * may be covered by U.S. and Foreign Patents, patents in process, and are protected by trade
 * secret or copyright law.
 *
 * Dissemination of this information or reproduction of this material is strictly forbidden unless
 * prior written permission is obtained from Sitetracker. Access to the source code contained
 * herein is hereby forbidden to anyone except current Sitetracker employees, managers or
 * contractors who have executed Confidentiality and Non-disclosure agreements explicitly
 * covering such access.
 *
 * The copyright notice above does not evidence any actual or intended publication or disclosure
 * of this source code, which includes information that is confidential and/or proprietary, and
 * is a trade secret, of Sitetracker.
 *
 * @description UpdateCommentField
 * @author <A HREF="mailto:rmohr@sitetracker.com">Ryan Mohr</A>
 *
***************************************************************************************************/
public with sharing class UpdateCommentField {
	//Updates the Comments History Field with the Comments field of the same name
    public static void updateCommentField( SObject oldObj, SObject newObj, String objectAPI ) {
        Map<String, Schema.SObjectType> objTypeMap = Schema.getGlobalDescribe();
        Schema.SObjectType sobj = objTypeMap.get( objectAPI );
        Map<String, Schema.SObjectField> fieldMap = sobj.getDescribe().fields.getMap();
        
        for ( String historyField : fieldMap.keySet() ) {

            if ( historyField.contains( '_history__c' ) ) {
               
                String commentField = historyField.replace( '_history__c', '__c' );
            	                

                if ( fieldMap.containsKey( commentField ) ) {
                    //System.debug( 'Comment Field Found: ' + commentField );
                    if ( oldObj.get( commentField ) != newObj.get( commentField )) {

                        String updatedComments = String.valueOf( newObj.get( commentField ) );
                        
                        if ( !String.isBlank( updatedComments ) ) {
                            String fname = '';
                            String lname = '';

                            if (UserInfo.getFirstName() != null) {
                                fname = UserInfo.getFirstName().substring( 0, 1 );
                            }
                            if (UserInfo.getLastName() != null) {
                                lname = UserInfo.getLastName().substring( 0, 1 );
                            }

                            String newValue = fname + lname + ' ' + date.today().format() + ' - ' + updatedComments;

                            try{

	                            if ( !String.isBlank( newValue ) ) {
	                                String currentHistoryValue = String.valueOf( oldObj.get( historyField ) );

                                
	                                //set comment history field for first time
		                                if ( String.isBlank( currentHistoryValue ) ) {
		                                    newObj.put( historyField, newValue );
		                                }
		                                //append new value to comment history
		                                else {
                                            
		                                    newObj.put( historyField, newValue + ' | \r\n' + currentHistoryValue );

		                                }
		                                newObj.put(commentField, '');
	                            }
                    		}
                    		catch( Exception ex ){
                    			System.debug( 'Error setting Comments History Field on ' + objectAPI + ': ' + ex.getMessage() );
                    		}// end try catch                        	
                        		
                        }// end if comment field is not blank 
                    }// end if omment field has changed
                }// end if field map contains comment field 
            }// end if history map contains comment field history 
        }// end for loop
    } // end updateComments()
}
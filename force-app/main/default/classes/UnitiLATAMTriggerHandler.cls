/***********************************************************************************************
 *  Copyright (c) 2025 SiteTraker
 *   This code is the sole property of SiteTraker and may not be distributed
 *   or modified without prior written consent from an authorized representative
 *   from SiteTraker.
 *   All rights reserved.
 *
 *   This is the LATM PRoject  Project Extension Trigger Handler class
 *   This Triggerhandler will be used to enable project extension object (sub)
 *
 *  @author <A HREF="mailto:rkim@sitetraker.com"Rachel</A>
 *  @version $Revision: 1.0 $ $Date: 20250430 $
 *  Revision History
 *  Version 1.0  Initial Version
 *
 ************************************************************************************************/ 
global with sharing class UnitiLATAMTriggerHandler extends strk.StSubprojectExtendableTriggerHandler {
    global override void initializeExtended( String sObjectName ){}
    global override void bulkBeforeExtended(){}
    global override void bulkAfterExtended(){}
    global override void beforeInsertExtended( SObject so ){}
    global override void afterInsertExtended( SObject so ){}
    global override void beforeUpdateExtended( SObject oldSo, SObject newSo ){}
    global override void afterUpdateExtended( SObject oldSo, SObject newSo ){}
    global override void beforeDeleteExtended( SObject so ){}
    global override void afterDeleteExtended( SObject so ){}
    global override void andFinallyExtended(){}
}
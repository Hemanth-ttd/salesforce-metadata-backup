import { LightningElement, api, wire, track } from 'lwc';
import getApprovalRecordId from '@salesforce/apex/HT_UnitEconomicsController.getApprovalRecordId';
import getFieldSet from '@salesforce/apex/HT_RelatedParentUpdateController.getFieldSet';
export default class Ht_approvalsubmission extends LightningElement {
    @api recordId;
    @track approvalRecordId;
    @track fieldsList;
    @api fieldName
    @wire(getApprovalRecordId, { recordId: '$recordId', fieldName: '$fieldName' })
    wiredData({ error, data }) {
        if (data) {
            console.log(data);
            this.approvalRecordId = data;
        } else if (error) {
            this.showToastMessage('Error!', 'error', 'Something went wrong. Please check with Admin');
        }
    }

    @wire(getFieldSet, {
        fieldSetName: 'Approval_Submission_Page',
        objectName: 'strk__Approval_Process__c'
    }) responseFieldsList({ error, data }) {
        if (data) {
            this.fieldsList = data;
        }
        if (error) {
            this.showToastMessage('Error!', 'error', 'Something went wrong. Please check with Admin');
        }
    }

    showToastMessage(title, variant, message) {
        const e = new ShowToastEvent({
            title: title, //'Success!',
            message: message,// 'Button 1 Clicked - Success',
            variant: variant, //'success',
        });
        this.dispatchEvent(e);
    }

}
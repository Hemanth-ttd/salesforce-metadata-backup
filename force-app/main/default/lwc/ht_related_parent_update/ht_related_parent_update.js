import { LightningElement, wire, api, track } from 'lwc';
import getChildRecords from '@salesforce/apex/HT_RelatedParentUpdateController.getChildRecords';
import getFieldSet from '@salesforce/apex/HT_RelatedParentUpdateController.getFieldSet';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
export default class Ht_related_parent_update extends NavigationMixin(LightningElement) {

  @api recordId;
  @api childObjectName;
  @api childFieldSetName;
  @api relationFieldName;
  @api secondaryParentFeildName;
  @api secondaryParentObjectdName;
  @api secondaryParentFieldSetName;
  @api sectionHeading;
  @track fieldsList;
  @track childRecordsList;
  @track isDisableEdit = true;
  @track successRecordsCount = 0;
  @track errorRecordsCount = 0;

  @wire(getChildRecords, {
    parentRecordId: '$recordId',
    childObjectName: '$childObjectName',
    childFieldSetName: '$childFieldSetName',
    relationFieldName: '$relationFieldName',
    secondaryParentFeildName: '$secondaryParentFeildName'
  }) responseChildRecords({ error, data }) {
    if (data) {
      this.childRecordsList = data;
    }
    if (error) {
      this.showToastMessage('Error!', 'error', 'Something went wrong. Please check with Admin');
    }
  }

  @wire(getFieldSet, {
    fieldSetName: '$secondaryParentFieldSetName',
    objectName: '$secondaryParentObjectdName'
  }) responseFieldsList({ error, data }) {
    if (data) {
      this.fieldsList = data;
    }
    if (error) {
      this.showToastMessage('Error!', 'error', 'Something went wrong. Please check with Admin');
    }
  }
connectedCallback() {
    // This doesn't work
    this.template.querySelector("[name='Total_Commenced__c']");
  }
  renderedCallback() {
    this.template.querySelector("[name='Total_Commenced__c']");
  }

  handleButtonClick(event) {
    let buttonName = event.currentTarget.dataset.name;
    if (buttonName == 'edit') {
      this.isDisableEdit = false;
    } else if (buttonName == 'cancel') {
      const inputFields = this.template.querySelectorAll('lightning-input-field');
    if (inputFields) {
        inputFields.forEach((field) => {
            field.reset();
        });
    }
      this.isDisableEdit = true;
    } else if (buttonName == 'save') {
      this.handleSave();
    } else if (buttonName == 'navigateRecord') {
      this.navigateToRecord(event.currentTarget.dataset.id);
    } else if (buttonName == 'toggleButton') {
      this.toggleSection();
    }
  }

  handleSave() {
    this.successRecordsCount =0;
    this.errorRecordsCount =0;
    let isVal = true;
    this.template.querySelectorAll('lightning-input-field').forEach(element => {
      isVal = isVal && element.reportValidity();
    });
    if (isVal) {
      this.template.querySelectorAll('lightning-record-edit-form').forEach(element => {
        element.submit();
      });
      // this.showToastMessage('Success!', 'success', 'Records updated successfully');

    } else {
      this.showToastMessage('Error!', 'error', 'Something went wrong. Please check with Admin');
    }
  }

  handleSuccess(event) {
    this.successRecordsCount = this.successRecordsCount + 1;
    this.showFinalMessage();
  }

  handleError(event) {
    this.errorRecordsCount = this.errorRecordsCount + 1;
    this.showFinalMessage();

  }

  showFinalMessage() {
    if (this.successRecordsCount + this.errorRecordsCount == this.childRecordsList.length) {
      if (this.successRecordsCount > 0) {
        this.showToastMessage('Success!', 'success', this.successRecordsCount+' Records updated successfully');
      }
      if (this.errorRecordsCount > 0) {
        this.showToastMessage('Error!', 'error',this.errorRecordsCount+' Something went wrong. Please check with Admin');
      }
      if (this.errorRecordsCount == 0) {
        this.isDisableEdit = true;
      }


    }
  }

  navigateToRecord(recordId) {
    this[NavigationMixin.GenerateUrl]({
      type: 'standard__recordPage',
      attributes: {
        recordId: recordId,
        actionName: 'view'
      }
    }).then(url => { window.open(url) });
  }

  toggleSection() {
    let currentsection = this.template.querySelector('[data-id="sectionId"]');
    if (currentsection.className.search('slds-is-open') == -1) {
      currentsection.className = 'slds-section slds-is-open';
    } else {
      currentsection.className = 'slds-section slds-is-close';
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
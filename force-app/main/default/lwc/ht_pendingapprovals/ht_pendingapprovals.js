import { LightningElement, wire, track, api } from 'lwc';
import getPendingApprovals from '@salesforce/apex/HT_ApprovalController.getPendingApprovals';
import approveOrReject from '@salesforce/apex/HT_ApprovalController.approveOrReject';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Ht_pendingapprovals extends LightningElement {
    @api recordId;
    @track approvals = [];
    @track filteredApprovals = [];
    @track value = 'My Pending Approvals';

    get options() {
        return [
            { label: 'All Pending Approvals', value: 'All Pending Approvals' },
            { label: 'My Pending Approvals', value: 'My Pending Approvals' },
            { label: 'Overdue Approvals', value: 'Overdue Approvals' },
            { label: 'Unit Economics Approvals', value: 'Unit Economics Approvals' },
            { label: 'Project Acceptance Approvals', value: 'Project Acceptance Approvals' }
        ];
    }
 @track isLoading = false;
    columns = [
        { label: 'Name', fieldName: 'recordLink', type: 'url', typeAttributes: { label: { fieldName: 'recordName' }, target: '_blank' } },
        { label: 'Approver(s)', fieldName: 'approverName' },
        { label: 'Due Date', fieldName: 'dueDate', type: 'date' },
        { label: 'Days in Approval', fieldName: 'daysInApproval', type: 'number' },
        { label: 'Days with Approver', fieldName: 'daysWithApprover', type: 'number' },
        {
            label: 'Approval Action',
            type: 'button',
            typeAttributes: {
                label: 'Pending',
                variant: 'brand',
                iconName: 'utility:clock',
                iconPosition: 'left',
                name: 'approve_reject'
            }
        }
    ];
    connectedCallback() {
        if(!this.recordId){
            this.recordId = '';
        }
    }
   
    @wire(getPendingApprovals, {recordId:'$recordId',approvalType:'$value'})
    wiredApprovals({ data, error }) {
        if (data) {
            console.log(data);
            this.approvals = data.map(item => ({
                Id: item.Id,
                recordLink: '/' + item.Id,
                recordName: item.Name,
                strk__Record_Id_Formula__c: item.strk__Record_Id_Formula__c,
                isUE: item.strk__Object_API__c === 'Unit_Economics__c',
                isPA: item.strk__Object_API__c === 'Project_Acceptance__c',
                comments: ''
            }));
            this.filteredApprovals = [...this.approvals];
            console.log(this.filteredApprovals);
        } else if (error) {
            this.showToast('Error', 'Error loading approvals', 'error');
        }
    }

    handleChange(event) {
        this.value = event.detail.value;
        console.log('value',this.value);
    }


    // Handle comment change
    handleCommentChange(event) {
        let recordId = event.target.dataset.id;
        let newComment = event.target.value;
console.log(recordId);
console.log(newComment);
       this.filteredApprovals = this.filteredApprovals.map(item =>
        item.Id === recordId ? { ...item, comments: newComment } : item
    );
    }

    handleAction(event) {
        
        this.isLoading = true;
        let recordId= event.target.dataset.id;
        let submitAction = event.target.dataset.action;
        let selected = this.filteredApprovals.find(item => item.Id === recordId);
console.log(recordId);
        let comment = selected?.comments || '';
console.log(comment);
        if (comment === '') {
            this.showToast('Error', 'Comment is required.', 'error');
            return;
        }
        approveOrReject({
            workItemId: recordId,
            submitAction: submitAction,
            comment: comment
        })
            .then((data) => {
                this.showToast('Success', `Successfully ${submitAction}ed`, 'success');
console.log(comment);
                 console.log(data);
            this.approvals = data.map(item => ({
                Id: item.Id,
                recordLink: '/' + item.Id,
                recordName: item.Name,
                strk__Record_Id_Formula__c: item.strk__Record_Id_Formula__c,
                isUE: item.strk__Object_API__c === 'Unit_Economics__c',
                isPA: item.strk__Object_API__c === 'Project_Acceptance__c',
                comments: ''
            }));
            this.filteredApprovals = [...this.approvals];
            })
            .catch(error => {
console.log(error);
                this.showToast('Error', 'Action failed', 'error');
                console.error(error);
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
         this.isLoading = false;
    }


}
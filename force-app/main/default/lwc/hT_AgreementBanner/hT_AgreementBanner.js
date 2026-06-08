import { LightningElement, wire, api, track } from 'lwc';
import getBannerMessage from '@salesforce/apex/HT_AgreementBannerController.getBannerMessage';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class HT_AgreementBanner extends LightningElement {
    
  @api recordId;
       message=''
       displayBanner = false;

    @wire(getBannerMessage, {
    recordId: '$recordId',
  }) responsBannerMessage({ error, data }) {
    if (data) {
      this.message = data;
      if(this.message.length > 0){
        this.displayBanner = true;
      }
    }
    if (error) {
      this.showToastMessage('Error!', 'error', 'Something went wrong. Please check with Admin');
    }
  }

   connectedCallback() {
    // This doesn't work
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
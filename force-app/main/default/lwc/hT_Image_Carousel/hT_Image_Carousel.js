import { LightningElement, wire, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getImages from "@salesforce/apex/HT_ImageCarouselController.getImages";
import { refreshApex } from "@salesforce/apex";

export default class ImageCarousel extends NavigationMixin(LightningElement) {
  @api fileUploadOption;
  @api recordId = "a0v1F000000eb7tQAA";

  @wire(getImages, { recordId: "$recordId" })
  images;

  get hasResults() {
    return this.images.data && this.images.data.length > 0;
  }

  get showFileUploadOption() {
    return this.fileUploadOption;
  }

  onUploadFinish() {
    refreshApex(this.images);
  }

  imageClicked(event) {
    const selectedId = event.target.dataset.contentid;
    const allImageIds = this.images.data.map(a => a.id).join();
    this[NavigationMixin.Navigate]({
      type: "standard__namedPage",
      attributes: {
        pageName: "filePreview"
      },
      state: {
        recordIds: allImageIds,
        selectedRecordId: selectedId
      }
    });
  }
}
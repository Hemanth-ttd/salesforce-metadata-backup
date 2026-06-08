public class HT_ImageCarouselController {
 public static final String SALESFORCE_FILES_DOWNLOAD_URL = '/sfc/servlet.shepherd/version/download/';
    public static final String SALESFORCE_FILES_THUMBNAIL_URL = '/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB720BY480&versionId=';

    @AuraEnabled(cacheable=true)
    public static List<ImageWrapper> getImages(Id recordId) {

        try {
            List<ImageWrapper> images = new List<ImageWrapper>();
            List<ContentDocumentLink> cdls = [SELECT ContentDocumentId, ContentDocument.FileType, ContentDocument.Title,
                                              	ContentDocument.Description, ContentDocument.LatestPublishedVersionId
                                              	FROM ContentDocumentLink WHERE LinkedEntityId =: recordId
                                             	AND ContentDocument.FileExtension IN ('png','jpg','gif','jpeg')
                                            	ORDER BY ContentDocument.LatestPublishedVersion.CreatedDate DESC];
            for(ContentDocumentLink cdl : cdls) {
				images.add(new ImageWrapper(cdl));
            }
            return images;
        }
        catch(Exception e) {
            System.debug('Exception:' + e.getMessage());
        }
        return null;
	}

    public class ImageWrapper {

    	@AuraEnabled public String name {get; set;}
    	@AuraEnabled public String description {get; set;}
    	@AuraEnabled public String extension {get; set;}
    	@AuraEnabled public String id {get; set;}
    	@AuraEnabled public String thumbnail {get; set;}
    	@AuraEnabled public String url {get; set;}
    	@AuraEnabled public String altText {get; set;}
    	@AuraEnabled public String versionId {get; set;}

        public ImageWrapper(ContentDocumentLink cdl){
            this.name = cdl.ContentDocument.Title;
            this.extension = cdl.ContentDocument.FileType;
            this.description = cdl.ContentDocument.Description;
            this.id = cdl.ContentDocumentId;
            this.versionId = cdl.ContentDocument.LatestPublishedVersionId;
            this.url = SALESFORCE_FILES_DOWNLOAD_URL + versionId;
            this.thumbnail = SALESFORCE_FILES_THUMBNAIL_URL + versionId;
            this.altText = cdl.ContentDocumentId;
        }
    }
}
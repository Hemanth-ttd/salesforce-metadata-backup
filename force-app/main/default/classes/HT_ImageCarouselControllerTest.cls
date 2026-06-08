@isTest
public class HT_ImageCarouselControllerTest {
  /* Tests fetching images */
    static testMethod void testWithImages() {

        strk__Site__c site = new strk__Site__c ( Name = 'Casterly Rock' );
        insert site;
        site = [SELECT Id, Name FROM strk__Site__c LIMIT 1];

        ContentVersion doc1 = new ContentVersion(
            Title = 'Document 1',
            PathOnClient = 'SitePicture.png',
            VersionData = Blob.valueOf('Site Picture'),
            origin = 'H'
        );
        insert doc1;
        doc1 = [SELECT Id, ContentDocumentId, Title from ContentVersion LIMIT 1];

        ContentDocumentLink contentlink = new ContentDocumentLink(
            LinkedEntityId = site.Id,
            ShareType = 'I',
            ContentDocumentId = doc1.ContentDocumentId,
            Visibility = 'AllUsers'
        );
        insert contentlink;

        Test.startTest();
        List<HT_ImageCarouselController.ImageWrapper> images = HT_ImageCarouselController.getImages(site.Id);
        HT_ImageCarouselController.ImageWrapper image = images.get(0);
        Test.stopTest();

        System.assertEquals( images.size(), 1 );
        System.assertEquals( image.id, doc1.ContentDocumentId );
    }
}
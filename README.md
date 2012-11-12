CityWatch
=============
Kinvey iOS Sample App to show off Facebook Open Graph integration with deep-linking.

## Setup 
See [Kinvey's Open Graph Tutorial](http://docs.kinvey.com/how-to-use-facebook-open-graph-native-ios-android-apps.html) how to set up your in Facebook's app system and configure the backend.

## Open Graph Collection
In order to post to Facebook Open Graph, you'll need to add a Social Data Integration collection for Open Graph. In this sample's case we've named the collection `FBOG` (FaceBook Open Graph). When you POST to this collection by saving a dictionary, it will create an open graph post that is linked to the specified object in the backend's data store. 

    //create a dictionary for the info to be posted to Open Graph
    NSDictionary* obj = @{
    @"entityId" : report.objectId, //the related object's id
    @"entityCollection" : @"Reports", //the data store collecion name
    @"actionType" : @"report", //defined as an app action in Facebook
    @"objectType" : report.category, //defined as a type in Facebook
    @"ref": report.category}; //also a special FB value


## Deep Linking
When a user clicks the activity link in their Facebook app, it will open City Watch with a URL specifying the `_id` of the story. The `application:openURL:sourceApplication:annotation:` method will be called with the deep-link URL. The url is parsed for the `target_url` parameter; which is then further broken down for the specific id. 

To show the linked story, the list of stories is searched for the particular id, and then that detail controller is pushed onto the stack. 

## System Requirements
* Xcode 4.5+
* iPhone/iPod Touch
* iOS 6+
* KinveyKit 1.10.6+
* Facebook SDK for iOS 1.3+

## Contact
Website: [www.kinvey.com](http://www.kinvey.com)

Support: [support@kinvey.com](http://docs.kinvey.com/mailto:support@kinvey.com)
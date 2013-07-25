CityWatch
=============
Kinvey iOS Sample App to show off Facebook Open Graph integration with deep-linking and multiple objectTypes associated with an action. This application allows users to report hazardous conditions around their town, such as traffic obstructions, fires, floods, dangerous animals, etc.

## Tutorial 
See [Kinvey's Open Graph Tutorial](http://docs.kinvey.com/how-to-use-facebook-open-graph-native-ios-android-apps.html) how to set up your in Facebook's app system and configure the backend. The tutorial covers the process of configuring the app to work with Kinvey and Facebook. 

## Using the Sample
The sample repository comes with the KinveyKit and Fracebook frameworks that it was developed against. In production code, you should update to the latest versions of these libraries.

* [Download KinveyKit](http://devcenter.kinvey.com/ios/downloads)
* [Download Facebook SDK](http://developers.facebook.com/ios/downloads/)

### Set-up the Backend
1. Create your City App on Facebook.
    * CityWatch sample uses `cwappns` as its namespace. 
    * Set up the `report` action.
    * Set up the following objects:`Emergency`, `Fire`, `Flood`, `Health`, `Infrastructure`, `Obstruction`, `Other`, `Weather`, `Wildlife`.
    	* These inherit from `Object` and have the following Optional fields:
    	     * `cwappns_location` (GeoPoint)
    	     * `cwappns_severity` (String)
    	     * `cwappns_risk` (String)
    	     * `cwappns_repeate` (String)
    	     
2. Create a new App on [Kinvey](https://console.kinvey.com/).
    1. Create a "Reports" collection to store the data for each meal uploaded by the users.
    2. Set up mappings in the "Data Links" -> "Facebook Open Graph" settings. Follow the steps in [this tutorial](http://devcenter.kinvey.com/ios/tutorials/facebook-opengraph-tutorial) set up the mappings between the Kinvey object and the Facebook object.
         * You'll need to paste the "get code" for the each of the object types. This will set up some of the fields and settings for a `cwappns:XXX` object type.
         * Map the following fields:
         	* `og:title` -> `title`
         	* `og:image` -> `image`
         	* `cwappns:cwappns_location:latitude` -> `latitude`
         	* `cwappns:cwappns_location:longitude` -> `longitude`
         	* `cwappns:cwappns_risk` -> `risk`
         	* `cwappns:cwappns_severity` -> `severity`
         	* `cwappns:cwappns_repeat` -> `repeat
         * You will need to add additional mappings for these fields:
            * `og:description` -> `description`

    3. Add a new action `cwappns:report` to represent the reporting action.

### Set-up the App
1. In `AppDelegate application:didFinishLaunchingWithOptions:` enter your Kinvey app __App ID__ and __App Secret__.
2. In CityWatch-Info.plist, enter your __Facebook App ID__ in the `FacebookAppID` and `URL Schemes` values.


## Open Graph Story Publishing
In order to post to Facebook Open Graph, you'll need to send the mapped entity to a special endpoint in Kinvey's service. This can be done with the `KCSFacebookHelper` class. 

    [KCSFacebookHelper publishToOpenGraph:report.objectId
                                   action:@"cwappns:report"
                               objectType:[@"cwappns:" stringByAppendingString:report.category]
                           optionalParams:nil
                               completion:^(NSString *actionId, NSError *errorOrNil) {
        //silently fail -- If Open Graph integration is essential, you would have to retry this action again later
        NSLog(@"Finished publishing story. ID: %@, error (if any) = %@", actionId, errorOrNil);
    }];


## Deep Linking
When a user clicks the activity link in their Facebook app, it will open City Watch with a URL specifying the `_id` of the story. The `application:openURL:sourceApplication:annotation:` method will be called with the deep-link URL. The url is parsed for the `target_url` parameter; which is then further broken down for the specific id. The id can be retrieved with a special `KCSFacebookHelper` method.

To show the linked story, the list of stories is searched for the particular id, and then that detail controller is pushed onto the stack. 

See `AppDelegate.m`'s `application:openURL:sourceApplication:annotation:` method

    NSDictionary* items = [KCSFacebookHelper parseDeepLink:url];
    if (items != nil) {
        NSString* entityId = items[KCSFacebookOGEntityId];
        if (entityId != nil) {
            NSArray* reports = [ReportService sharedInstance].reports;
            __block NSUInteger reportIdx = -1;
            __block ReportModel* report = nil;
            [reports enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                ReportModel* rm = obj;
                if ([rm.kinveyObjectId isEqualToString:entityId]) {
                    reportIdx = idx;
                    report = rm;
                    *stop = YES;
                }
            }];
            if (report) {
                //found an already loaded report - show it
                [_rvc showDetailViewForReport:report];
            } else {
                //download more reports and refresh the list
                [[ReportService sharedInstance] pullReports];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(done) name:NOTIFY_FetchComplete object:nil];
                _deepLink = entityId;
            }
            
        }
    }

## System Requirements
* Xcode 4.5+
* iPhone/iPod Touch
* iOS 6+
* KinveyKit 1.17.2+
* Facebook SDK for iOS 1.3+

## Contact
Website: [www.kinvey.com](http://www.kinvey.com)

Support: [support@kinvey.com](http://docs.kinvey.com/mailto:support@kinvey.com)

## License

Copyright (c) 2013 Kinvey, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
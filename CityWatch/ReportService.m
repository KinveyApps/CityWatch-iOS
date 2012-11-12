//
//  ApplicationData.m
//  CityWatch
//
//  Copyright 2012 Intrepid Pursuits & Kinvey, Inc
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "ReportService.h"

#import <KinveyKit/KinveyKit.h>

#import "ReportUploader.h"

@interface ReportService()
@property(strong, nonatomic) NSMutableArray *managedReports;
@property(strong, nonatomic) NSMutableDictionary *imageDownloaders;
@property(strong, nonatomic) NSMutableDictionary *reportUploaders;
@property(strong, nonatomic) KCSAppdataStore* store;
@end

@implementation ReportService

- (id) init {
    if (self = [super init]) {
        _managedReports = [[NSMutableArray alloc] init];
        _imageDownloaders = [[NSMutableDictionary alloc] init];
        
        //Create a caching store that loads from the Reports collection
        KCSCollection* collection = [KCSCollection collectionFromString:@"Reports" ofClass:[ReportModel class]];
        _store = [KCSCachedStore storeWithCollection:collection options:@{ KCSStoreKeyCachePolicy : @(KCSCachePolicyNetworkFirst)}];
    }
    
    return self;
}

+ (id) sharedInstance 
{
    static dispatch_once_t p = 0;
    __strong static id _sharedObject = nil;

    dispatch_once(&p, ^{
        _sharedObject = [[self alloc] init];
    });

    return _sharedObject;
}

- (NSArray *) reports
{
    return [self.managedReports copy];
}

- (void) addReport:(ReportModel *)report
{
    [self.managedReports addObject:report];
}

#pragma mark Pushing Data

- (void) pushReport:(ReportModel *)report
{
    if ([self.reportUploaders objectForKey:report.objectId] == nil) {
        ReportUploader *uploader = [[ReportUploader alloc] initWithReport:report];
        uploader.delegate = self;
        [self.reportUploaders setObject:uploader forKey:report.objectId];
        [uploader upload];
    }
}

- (void) uploadToFacebook:(ReportModel *)report
{
    if ([self.reportUploaders objectForKey:report.objectId] == nil) { //finished uploading        
        //Upload a new Open Graph action to Facebook through the special `FBOG` Data Integration collection
        //This has collection and the data structure has to be defined ahead of time in Kinvey's console
        //See the Open Graph tutorial in Kinvey documentation for instructions on how to port this feature
        //to your own apps.
        
        //create a dictionary for the info to be posted to Open Graph
        NSDictionary* obj = @{
        @"entityId" : report.objectId, //the related object's id
        @"entityCollection" : @"Reports", //the data store collecion name
        @"actionType" : @"report", //defined as an app action in Facebook
        @"objectType" : report.category, //defined as a type in Facebook
        @"ref": report.category}; //also a special FB value

        KCSCollection* fbCollection = [[KCSClient sharedClient] collectionFromString:@"FBOG" withClass:[NSDictionary class]];
        KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:fbCollection options:nil];
        [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
            //silently fail -- If Open Graph integration is essential, you would have to retry this action again later
            NSLog(@"Finished with error = %@", errorOrNil);
        } withProgressBlock:nil];
    }
}

- (void) reportUploaderDidFinish:(ReportUploader *)uploader;
{
    [self.reportUploaders removeObjectForKey:uploader.report.objectId];
    [self uploadToFacebook:uploader.report];
}

#pragma mark Pulling Data

- (void) pullReports 
{
    //load all the reports from Kinvey, by querying the store
    KCSQuery* allItems = [KCSQuery query];
    [_store queryWithQuery:allItems withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        if (errorOrNil != nil) {
            NSLog(@"Fetch all did fail: %@", errorOrNil);
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_FetchComplete object:nil];
        } else {
            for (ReportModel *report in objectsOrNil) {
                
                // Check if we already have this report
                NSUInteger index = [self.managedReports indexOfObjectPassingTest:
                                    ^(id obj, NSUInteger idx, BOOL *stop) {
                                        return [[obj objectId] isEqualToString:report.objectId];
                                    }];
                
                // Add report if necessary.
                if (index == NSNotFound) {
                    [self.managedReports addObject:report];
                    report.isUploaded = true;
                }
                else {
                    ((ReportModel *)[self.managedReports objectAtIndex:index]).isUploaded = true;
                }
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_FetchComplete object:nil];

        }
    } withProgressBlock:nil];
}


- (void) downloadImageForReport:(ReportModel *)report
{
    if ([self.imageDownloaders objectForKey:report.objectId] == nil) {
        ImageDownloader *downloader = [[ImageDownloader alloc] initWithReport:report];
        downloader.delegate = self;
        [self.imageDownloaders setObject:downloader forKey:report.objectId];
        [downloader download];
    }
}

- (void) imageDownloaderDidFinish:(ImageDownloader *)downloader
{
    if (downloader.report && downloader.report.objectId) {
        [self.imageDownloaders removeObjectForKey:downloader.report.objectId];
    }
}

- (void) saveReportsToDisk 
{
    NSData *encodedReports = [NSKeyedArchiver archivedDataWithRootObject:self.reports];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:encodedReports forKey:@"reportsArray"];
    [defaults synchronize];
}

- (void) readReportsFromDisk 
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *reportsData = [defaults objectForKey:@"reportsArray"];
    if (reportsData) {
        NSArray *reportsArray = (NSArray *)[NSKeyedUnarchiver unarchiveObjectWithData:reportsData];
        self.managedReports = [reportsArray mutableCopy];
    }
}

@end

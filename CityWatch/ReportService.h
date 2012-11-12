//
//  ApplicationData.h
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

#import <Foundation/Foundation.h>

#import "ReportModel.h"
#import "ImageDownloader.h"
#import "ReportUploader.h"

#define NOTIFY_FetchComplete @"NOTIFY_FetchComplete"
#define NOTIFY_ImageDownloaded @"NOTIFY_ImageDownloaded"

@interface ReportService : NSObject <ReportUploaderDelegate, ImageDownloaderDelegate>
- (void) pullReports;
- (void) pushReport:(ReportModel *) report;
- (void) downloadImageForReport:(ReportModel *)report;
- (void) addReport:(ReportModel *)report;
- (void) saveReportsToDisk;
- (void) readReportsFromDisk;

+ (ReportService *) sharedInstance;

@property (strong, readonly) NSArray *reports;

- (void) uploadToFacebook:(ReportModel *)report;
@end

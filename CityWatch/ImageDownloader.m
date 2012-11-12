//
//  ImageDownloader.m
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

#import "ImageDownloader.h"
#import <KinveyKit/KinveyKit.h>

#import "ReportService.h"

@interface ImageDownloader()
- (NSString *) documentsDirectoryPath;
@end

@implementation ImageDownloader

- (id) initWithReport:(ReportModel *)report
{
    if (self = [super init]) {
        self.report = report;
    }
    
    return self;
}

-(NSString *)documentsDirectoryPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectoryPath = paths[0];
    return documentsDirectoryPath;
} 

- (void) download
{
    NSString *path = [[self documentsDirectoryPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", self.report.objectId]];
    
    //use Kinvey's resource service to download the given resource name (jpeg's named with the report id) to a local file
    
    [KCSResourceService downloadResource:self.report.objectId toFile:path completionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        if (errorOrNil == nil && [objectsOrNil count] > 0) {
            NSLog(@"resourceService completed.");
            KCSResourceResponse* result = objectsOrNil[0];
            self.report.imagePath = result.localFileName;
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_ImageDownloaded object:self.report];
        } else {
            NSLog(@"resourceService failed with error %@", errorOrNil);
        }
        [self.delegate imageDownloaderDidFinish:self];
    } progressBlock:nil];
}

@end

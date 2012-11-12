//
//  ReportModel.m
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
#import "ReportModel.h"
#import <KinveyKit/KinveyKit.h>

@implementation ReportModel

@synthesize identifier;

- (void) encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.objectId forKey:@"objectId"];
    [encoder encodeObject:self.category forKey:@"category"];
    [encoder encodeObject:self.locationString forKey:@"locationString"];
    [encoder encodeObject:self.locationDescription forKey:@"locationDescription"];
    [encoder encodeObject:self.description forKey:@"description"];
    [encoder encodeObject:self.timestamp forKey:@"timestamp"];
    [encoder encodeObject:[NSNumber numberWithBool:self.reportIsClosed] forKey:@"reportIsClosed"];
    [encoder encodeObject:[NSNumber numberWithBool:self.isUploaded] forKey:@"isUploaded"];
    [encoder encodeObject:self.imagePath forKey:@"imagePath"];
}

- (id) initWithCoder:(NSCoder *)decoder
{
    if (self = [super init]) {
        self.objectId = [decoder decodeObjectForKey:@"objectId"];
        self.category = [decoder decodeObjectForKey:@"category"];
        self.locationString = [decoder decodeObjectForKey:@"locationString"];
        self.locationDescription = [decoder decodeObjectForKey:@"locationDescription"];
        self.description = [decoder decodeObjectForKey:@"description"];
        self.timestamp = [decoder decodeObjectForKey:@"timestamp"];
        self.reportIsClosed = [(NSNumber *)[decoder decodeObjectForKey:@"category"] boolValue]; 
        self.isUploaded = [(NSNumber *)[decoder decodeObjectForKey:@"category"] boolValue];
        self.imagePath = [decoder decodeObjectForKey:@"imagePath"];
    }
    return self;
}

- (id) init
{
    self = [super init];
    if (self) {
        self.risk = @"no";
        self.repeat = @"low";
        self.severity = @"high";
    }
    return self;
}

- (NSString *) locationString
{
    return [NSString stringWithFormat:@"%f,%f", _lat, _lon];
}

- (void) setLocationString:(NSString *)locationString
{
    NSArray *coordinates = [locationString componentsSeparatedByString:@","];
    _lon = [[coordinates objectAtIndex:0] floatValue];
    _lat = [[coordinates objectAtIndex:1] floatValue];
}

+ (NSString *)generateUuidString
{
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidString = [(__bridge_transfer NSString *)CFUUIDCreateString(NULL, uuid) copy];
    CFRelease(uuid);
    
    return uuidString;
}

+ (ReportModel *) newReportModel {
    ReportModel *report = [[ReportModel alloc] init];
    report.objectId = [self generateUuidString];
    return report;
}

- (NSDictionary*) hostToKinveyPropertyMapping {    
    return  @{
    @"description" : @"description",
    @"lat" : @"latitude",
    @"lon" : @"longitude",
    @"alt" : @"altitude",
    @"locationDescription" : @"locationDescription",
    @"category" : @"type",
    @"timestamp" : @"updated_time",
    @"objectId" : KCSEntityKeyId,
    @"summary" : @"title",
    @"imageName" : @"image",
    @"severity" : @"severity",
    @"risk" : @"risk",
    @"repeat" : @"repeat"
    };
}

- (NSArray *)validCategories {
    return @[@"infrastructure",@"wildlife",@"weather",@"obstruction",@"health",
            @"emergency",@"fire",@"flood",@"other"];
}

- (BOOL) isImageDownloaded
{
    return self.imagePath != nil;
}

@end

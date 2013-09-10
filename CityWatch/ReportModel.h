//
//  ReportModel.h
//  CityWatch
//
//  Copyright 2012-2013 Kinvey, Inc
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

@interface ReportModel : NSObject <NSCoding>

@property (nonatomic) NSInteger identifier;
@property (strong, nonatomic) NSString *objectId;
@property (strong, nonatomic) NSString *category;
@property (strong, nonatomic) NSString* summary;
@property (nonatomic) float lat;
@property (nonatomic) float lon;
@property (nonatomic) float alt;
@property (strong, nonatomic) NSString *locationString;
@property (strong, nonatomic) NSString *locationDescription;
@property (strong, nonatomic) NSString *description;
@property (strong, nonatomic) NSDate *timestamp;
@property (nonatomic) BOOL reportIsClosed;
@property (readonly) NSArray *validCategories;
@property (nonatomic) BOOL isUploaded;
@property (strong, nonatomic) UIImage *image;
@property (nonatomic, copy) NSString* severity;
@property (nonatomic, copy) NSString* risk;
@property (nonatomic, copy) NSString* repeat;

+ (ReportModel *) newReportModel;

@end

//
//  MapAnnotation.h
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
#import <MapKit/MapKit.h>
#import "ReportModel.h"

@protocol MapAnnotationDelegate;

@interface MapAnnotation : NSObject <MKAnnotation>

@property (readonly, nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *subtitle;
@property (nonatomic) NSInteger identifier;
@property (strong, nonatomic) CLGeocoder *reverseGeo;
@property (strong, nonatomic) NSString *streetNumber;
@property (strong, nonatomic) NSString *streetName;
@property (strong, nonatomic) NSString *city;
@property (weak, nonatomic) id <MapAnnotationDelegate> delegate;
@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) ReportModel *reportModel;

- (id)initWithCoordinate:(CLLocationCoordinate2D)myCoord title:(NSString *)myTitle;
- (id)initWithReport:(ReportModel *)aReport;
- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate NS_AVAILABLE(NA, 4_0);
- (void)setAddressFields:(CLLocation *)loc;

@end

@protocol MapAnnotationDelegate

- (void)mapAnnotationFinishedReverseGeocoding:(MapAnnotation *)annotation;

@end

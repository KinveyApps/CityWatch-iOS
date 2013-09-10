//
//  MapAnnotation.m
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

#import "MapAnnotation.h"
#import "UIImage+Resize.h"

@implementation MapAnnotation
@synthesize subtitle=_subtitle;

- (id)initWithCoordinate:(CLLocationCoordinate2D)myCoord title:(NSString *)myTitle {
    self = [super init];
    if (self) {
        _coordinate = myCoord;
        _title = myTitle;
        [self setAddressFields:[[CLLocation alloc] initWithLatitude:myCoord.latitude longitude:myCoord.longitude]];
    }
    return self;
}

- (id)initWithReport:(ReportModel *)report {
    self = [super init];
    if (self) {
        _reportModel = report;
        _coordinate = CLLocationCoordinate2DMake(report.lat, report.lon);
        _title = report.category;
        //identifier = aReport.identifier;
        // MB create image from imagePath
        //image = [aReport.image copy];
        UIImage *thumbnail = report.image;
        thumbnail = [thumbnail thumbnailImage:100 transparentBorder:0 cornerRadius:7 interpolationQuality:kCGInterpolationDefault];
        dispatch_queue_t mainThreadQueue = dispatch_get_main_queue();
        dispatch_async(mainThreadQueue, ^{
            _image = thumbnail;
        });
        [self setAddressFields:[[CLLocation alloc] initWithLatitude:_coordinate.latitude longitude:_coordinate.longitude]];
    }
    return self;
}

- (NSString *) subtitle {
    if (_subtitle == nil) {
        return [NSString stringWithFormat:@"(%f , %f)",_coordinate.latitude,_coordinate.longitude];
    }
    return _subtitle;
}

- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate {
    _coordinate = newCoordinate;
}

- (void)setAddressFields:(CLLocation *)loc {
    
    if (!self.reverseGeo) {
        self.reverseGeo = [[CLGeocoder alloc] init];
    }
    
    [self.reverseGeo reverseGeocodeLocation:loc
                          completionHandler:^(NSArray *placemarks, NSError *error) {
                              for (CLPlacemark *placemark in placemarks) {
                                  self.streetNumber = placemark.subThoroughfare;
                                  self.streetName = placemark.thoroughfare;
                                  self.city = placemark.locality;
                                  
                                  NSString *locationString;
                                  if (!self.streetNumber)
                                      locationString = [NSString stringWithFormat:@"%@, %@",self.streetName,self.city];
                                  else
                                      locationString = [NSString stringWithFormat:@"%@ %@, %@",self.streetNumber,self.streetName,self.city];
                                  
                                  _subtitle = locationString;
                              }
                              [_delegate mapAnnotationFinishedReverseGeocoding:self];
                          }
     ];
}

@end

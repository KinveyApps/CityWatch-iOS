//
//  MapViewController.m
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

#import "MapViewController.h"

@implementation MapViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = YES;
}

- (IBAction)doneButtonPressed:(id)sender {
    [_delegate mapViewControllerDoneButtonPressedWithAnnotation:self.reportAnnotation];
}

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)aMapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    else if ([annotation isKindOfClass:[MapAnnotation class]]) {
        static NSString *MapAnnotationIdentifier = @"mapAnnotationIdentifier";
        MKPinAnnotationView *pinView = (MKPinAnnotationView *)[aMapView dequeueReusableAnnotationViewWithIdentifier:MapAnnotationIdentifier];
        
        if (pinView == nil) {
            pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation 
                                                      reuseIdentifier:MapAnnotationIdentifier];
        }
        else {
            pinView.annotation = annotation;
        }
        pinView.pinColor = MKPinAnnotationColorRed;
        pinView.animatesDrop = YES;
        pinView.canShowCallout = YES;
        pinView.draggable = YES;
        
        return pinView;
    }
    return nil;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState {
    if ([view.annotation isKindOfClass:[MapAnnotation class]]) {
        if (newState == MKAnnotationViewDragStateEnding) {
            [((MapAnnotation *)view.annotation) setAddressFields:[[CLLocation alloc] initWithLatitude:[view.annotation coordinate].latitude 
                                                                                            longitude:[view.annotation coordinate].longitude]];
        }
    }
}

- (void)mapView:(MKMapView *)aMapView didAddAnnotationViews:(NSArray *)views {
    for (MKAnnotationView *annotationView in views) {
        // when user location annotation is added, zoom in to location
        if (annotationView.annotation == aMapView.userLocation) {
            MKCoordinateRegion region;
            MKCoordinateSpan span;
            
            span.latitudeDelta = 0.01;
            span.longitudeDelta = 0.01;
            
            CLLocationCoordinate2D location = aMapView.userLocation.location.coordinate;
            
            region.span = span;
            region.center = location;
            
            [aMapView setRegion:region animated:TRUE];
            [aMapView regionThatFits:region];
            
            // add pin after zoom animation
            [self.mapView addAnnotation:(id <MKAnnotation>)self.reportAnnotation];
        }
    }
}

- (void)viewDidUnload
{
    [self setMapView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end

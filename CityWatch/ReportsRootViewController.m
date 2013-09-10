//
//  ReportsRootViewController.m
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

#import "ReportsRootViewController.h"
#import "ReportModel.h"
#import "ReportService.h"
#import "MapAnnotation.h"
#import "ReportDetailViewController.h"
#import "UIImage+Resize.h"

#import <KinveyKit/KinveyKit.h>
#import <FacebookSDK/FacebookSDK.h>
#import "AppDelegate.h"

#define MILES_PER_METER     0.000621371192

@interface ReportsRootViewController () <CLLocationManagerDelegate>
@property (nonatomic, retain) CLLocationManager* locationManager;
- (void) setThumbnailForCell:(CustomReportTableViewCell *)cell withReport:(ReportModel *)report;
@end

@implementation ReportsRootViewController

- (UITableView *)reportsTableView {
    if (!_reportsTableView) {
        _reportsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 372) 
                                                        style:UITableViewStylePlain];
        _reportsTableView.delegate = self;
        _reportsTableView.dataSource = self;
        _reportsTableView.backgroundColor = [UIColor whiteColor];
        _reportsTableView.rowHeight = 124.0f;
    }
    return _reportsTableView;
}

- (MKMapView *)reportsMapView {
    if (!_reportsMapView) {
        _reportsMapView = [[MKMapView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 372)];
        _reportsMapView.delegate = self;
        _reportsMapView.showsUserLocation = YES;
    }
    return _reportsMapView;
}


- (float)reportDistanceFromCurrentLocation:(ReportModel *)report
{
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized) {
        CLLocationCoordinate2D userCoordinate = [self.locationManager location].coordinate;
        CLLocation *userLocation = [[CLLocation alloc] initWithCoordinate:userCoordinate
                                                                 altitude:1
                                                       horizontalAccuracy:1
                                                         verticalAccuracy:1
                                                                timestamp:nil];
        CLLocation *reportLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(report.lat, report.lon)
                                                                   altitude:1
                                                         horizontalAccuracy:1
                                                           verticalAccuracy:1
                                                                  timestamp:nil];
        
        return [reportLocation distanceFromLocation:userLocation];  // meters
    } else {
        return INFINITY;
    }
}

- (void)sortReportsData:(NSArray *)data {
    NSArray *sortedArray;
    
    if (currentTableSortOption == SortOptionRecent) {
        // sort array based on time submitted
        sortedArray = [data sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSDate *first = [(ReportModel *)obj1 timestamp];
            NSDate *second = [(ReportModel *)obj2 timestamp];
            return [second compare:first];
        }];
    }
    else if (currentTableSortOption == SortOptionDistance) {
        // sort array based on distance from current location
        sortedArray = [data sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            if ([self reportDistanceFromCurrentLocation:obj1] > [self reportDistanceFromCurrentLocation:obj2]) 
                return NSOrderedDescending;
            else if ([self reportDistanceFromCurrentLocation:obj1] < [self reportDistanceFromCurrentLocation:obj2]) 
                return NSOrderedAscending;
            return NSOrderedSame;
        }];
    }
    self.reportsData = sortedArray;
}

- (void)dataLoaded:(NSNotification *) notification 
{
    [pullView finishedLoading];
    [self.activityIndicator stopAnimating];
    [self.activityIndicator removeFromSuperview];
    self.reportsData = [[ReportService sharedInstance] reports];
    [self sortReportsData:self.reportsData];
    [self.reportsTableView reloadData];
}

- (void)imageDownloaded:(NSNotification *) notification 
{
    ReportModel *report = notification.object;
    int index = [self.reportsData indexOfObject:report];
    if (index >= 0) {
        CustomReportTableViewCell *cell = (CustomReportTableViewCell *)[self.reportsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
        if (cell) {
            [self setThumbnailForCell:cell withReport:report];
        }
                
    }
}

- (void)refreshData 
{
    [[ReportService sharedInstance] pullReports];
}

- (void)showDetailViewForReport:(ReportModel *)report
{
    if (self.navigationController.topViewController != self) {
        //if the there is a subview showing, go back to the beginning, in order to preserve the stack behavior
        //if this is called via deplinking, 
        [self.navigationController popToViewController:self animated:NO];
    }
    [self performSegueWithIdentifier:@"kSegueIdentifierPushReportDetails" sender:report];
}

- (IBAction)logout:(id)sender
{
    [[KCSUser activeUser] logout];
    [[FBSession activeSession] closeAndClearTokenInformation];
    
    dispatch_async(dispatch_get_current_queue(), ^{
        [(AppDelegate*)[[UIApplication sharedApplication] delegate] showFacebookLogin];
    });
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"kSegueIdentifierPushReportDetails"]) {
        if ([sender isKindOfClass:[ReportModel class]]) {
            ((ReportDetailViewController *)segue.destinationViewController).report = sender;
        }
    }
    else if ([segue.identifier isEqualToString:@"kSegueIdentifierReportFilter"]) {
        ((ReportsFilterViewController *)segue.destinationViewController).delegate = self;
        ((ReportsFilterViewController *)segue.destinationViewController).selectedFilterOption = currentFilterOption;
        ((ReportsFilterViewController *)segue.destinationViewController).selectedSortOption = currentTableSortOption;
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" 
                                                                             style:UIBarButtonItemStyleBordered 
                                                                            target:nil 
                                                                            action:nil];
    tableViewIsVisible = YES;
    [self.mainContentView addSubview:self.reportsTableView];
    
    currentFilterOption = FilterOptionAll;
    currentTableSortOption = SortOptionRecent;
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(dataLoaded:) 
                                                 name:NOTIFY_FetchComplete 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(imageDownloaded:) 
                                                 name:NOTIFY_ImageDownloaded 
                                               object:nil];
    
    
  //  [self.activityIndicator startAnimating];
  //  [self refreshData];
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.delegate = self;
    [self.locationManager startUpdatingLocation];
    
    pullView = [[PullToRefreshView alloc] initWithScrollView:self.reportsTableView];
    [pullView setDelegate:self];
    [self.reportsTableView addSubview:pullView];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.reportsData = [ReportService sharedInstance].reports;
    [self sortReportsData:self.reportsData];
    [self.reportsTableView reloadData];
    
}

- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view
{
    [self refreshData];
}

- (IBAction)toggleViewButtonValueChanged:(id)sender {
    self.reportsTableView.userInteractionEnabled = NO;
    self.reportsMapView.userInteractionEnabled = NO;
    
    if (tableViewIsVisible) {
        [UIView animateWithDuration:0.5
                         animations:^{
                             [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight 
                                                    forView:self.mainContentView 
                                                      cache:YES];
                             [self.reportsTableView removeFromSuperview];
                             [self.mainContentView addSubview:self.reportsMapView];
                         }
                         completion:^(BOOL finished) {
                             NSMutableArray *reportAnnotations = [[NSMutableArray alloc] init];
                             for (ReportModel *report in self.reportsData) {
                                 MapAnnotation *annotation = [[MapAnnotation alloc] initWithReport:report];
                                 [reportAnnotations addObject:annotation];
                             }
                             [self.reportsMapView addAnnotations:[reportAnnotations copy]];
                             reportAnnotations = nil;
                         }
         ];
    }
    else {
        [UIView animateWithDuration:0.5 
                         animations:^{
                             [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft 
                                                    forView:self.mainContentView 
                                                      cache:NO];
                             [self.reportsMapView removeFromSuperview];
                             [self.mainContentView addSubview:self.reportsTableView];
                         } 
                         completion:^(BOOL finished) {
                             for (id <MKAnnotation> annotation in self.reportsMapView.annotations) {
                                 if ([annotation isKindOfClass:[MapAnnotation class]]) {
                                     [self.reportsMapView removeAnnotation:annotation];
                                 }
                             }
                         }
         ];
        
    }
    self.reportsTableView.userInteractionEnabled = YES;
    self.reportsMapView.userInteractionEnabled = YES;
    tableViewIsVisible = !tableViewIsVisible;

}

- (IBAction)newReportButtonPressed:(id)sender {
    // animate button
    [UIView animateWithDuration:0.25 
                     animations:^{
                         ((UIButton *)sender).transform = CGAffineTransformMakeRotation(M_PI - 0.01);
                     }
                     completion:^(BOOL finished) {
                         [self performSegueWithIdentifier:@"kSegueIdentifierNewReport" sender:sender];
                         ((UIButton *)sender).transform = CGAffineTransformIdentity;
                     }
     ];
}

#pragma mark - ReportsFilterViewControllerDelegate

- (void)reportFilterEditingFinishedWithOptions:(NSDictionary *)options {
    currentFilterOption = [[options objectForKey:kFilterOptionKey] intValue];
    currentTableSortOption = [[options objectForKey:kSortOptionKey] intValue];
    [self refreshData];
    [self.reportsTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationBottom];
}

- (void)reportFilterEditingFinishedWithFilterOption:(NSInteger)filterRow sortOption:(NSInteger)sortRow {
    currentFilterOption = filterRow;
    currentTableSortOption = sortRow;
    [self refreshData];
    [self.reportsTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationBottom];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.reportsData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *Identifier = @"CustomReportTableViewCell";
    
    CustomReportTableViewCell *cell = (CustomReportTableViewCell *)[tableView dequeueReusableCellWithIdentifier:Identifier];
    
    if (cell == nil) {
        [[NSBundle mainBundle] loadNibNamed:Identifier owner:self options:nil];
        cell = self.cellFromNib;
        self.cellFromNib = nil;
    }
    
    ReportModel *report = [self.reportsData objectAtIndex:indexPath.row];
    
    // populate image and labels of cell
    cell.reportLocation.text = report.locationDescription;
    cell.reportCategory.text = report.category;
    cell.reportDescription.text = report.description;
    cell.reportDistance.text = [NSString stringWithFormat:@"%.1f miles",[self reportDistanceFromCurrentLocation:report]*MILES_PER_METER];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterShortStyle;
    dateFormatter.timeStyle = NSDateFormatterShortStyle;
    cell.reportTime.text = [dateFormatter stringFromDate:report.timestamp];
    
    if (report.image) {
        [self setThumbnailForCell:cell withReport:report];
    } else {
        cell.reportImage.image = nil;
    }
    
    return cell;
}

- (void) setThumbnailForCell:(CustomReportTableViewCell *)cell withReport:(ReportModel *)report
{
    // load the image on a background thread and update the screen on the main thread.
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        UIImage *image = report.image;
        image = [image thumbnailImage:100 transparentBorder:0 cornerRadius:7 interpolationQuality:kCGInterpolationDefault];
        dispatch_queue_t mainThreadQueue = dispatch_get_main_queue();
        dispatch_async(mainThreadQueue, ^{
            cell.reportImage.image = image;
        });
    });
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    ReportModel *selectedReport = [self.reportsData objectAtIndex:indexPath.row];
    [self showDetailViewForReport:selectedReport];
}

#pragma mark - Location Delegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    //reload the data to update locations
    [self.reportsTableView reloadData];
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
        pinView.draggable = NO;
                
        UIImageView *annotationImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
        annotationImageView.contentMode = UIViewContentModeScaleAspectFit; //UIViewContentModeScaleAspectFill;
        annotationImageView.image = ((MapAnnotation *) annotation).image; //[UIImage imageNamed:@"earth.jpg"];
        
        UIButton *detailButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        [detailButton addTarget:self action:@selector(calloutButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        detailButton.frame = CGRectMake(0, 0, 32, 32);
        pinView.leftCalloutAccessoryView = annotationImageView;
        pinView.rightCalloutAccessoryView = detailButton;
        
        return pinView;
    }
    return nil;
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views {
    for (MKAnnotationView *annotationView in views) {
        // when user location annotation is added, zoom in to location
        if (annotationView.annotation == mapView.userLocation) {
            MKCoordinateRegion region;
            MKCoordinateSpan span;
            
            span.latitudeDelta = 0.05;
            span.longitudeDelta = 0.05;
            
            CLLocationCoordinate2D location = mapView.userLocation.location.coordinate;

            region.span = span;
            region.center = location;
            
            [mapView setRegion:region animated:TRUE];
            [mapView regionThatFits:region];
        }
    }
}

- (IBAction)calloutButtonPressed:(UIButton *)sender {
    MKAnnotationView *view = (MKAnnotationView *)sender.superview/*callout view*/.superview/*annotation view*/;
    [self showDetailViewForReport:((MapAnnotation *)view.annotation).reportModel];
}

- (void)viewDidUnload
{
    [self setToggleViewButton:nil];
    [self setMainContentView:nil];
    [self setAddReportButton:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setActivityIndicator:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end

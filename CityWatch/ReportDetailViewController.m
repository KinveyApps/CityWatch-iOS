//
//  ReportDetailViewController.m
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

#import "ReportDetailViewController.h"
#import "ImageScrollViewController.h"
#import <QuartzCore/QuartzCore.h>

#define CELL_HEIGHT_PADDING     14.0
#define MAX_IMAGE_HEIGHT     180.0f
#define LANDSCAPE_SCALE 4/3
#define PORTRAIT_SCALE  3/4

NSString *const kSegueIdentifierPushImageViewer = @"kSegueIdentifierPushImageViewer";

@implementation ReportDetailViewController

#pragma mark - View lifecycle

// in viewWillAppear/Disappear, toggle nav bar hidden for smooth transition with parent vc
- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    self.navigationController.navigationBar.translucent = YES;
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillDisappear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = [self.report.category capitalizedString];
    self.imageCell.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
    self.reportCategoryLabel.text = self.report.category;
    self.reportLocationLabel.text = self.report.locationDescription;
    self.reportDescriptionLabel.text = self.report.description;
    self.reportImageView.image = self.report.image;
}

#pragma mark - segue methods

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:kSegueIdentifierPushImageViewer]) {
        ImageScrollViewController *dest = segue.destinationViewController;
        dest.report = self.report;
        dest.navigationItem.title = self.navigationItem.title;
    }
}

#pragma mark - UITableViewDelegate

// dynamic row height
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    float labelHeight = 0;
    
    if (indexPath.section == 0) {
        return self.reportImageView.frame.size.height + 2*CELL_HEIGHT_PADDING;
    }
    else {
#ifdef __IPHONE_6_0
        NSLineBreakMode lineBreakMode = NSLineBreakByWordWrapping;
#else
        UILineBreakMode lineBreakMode = UILineBreakModeWordWrap;
#endif
        switch (indexPath.row) {
            case 0:
                labelHeight = [self.reportCategoryLabel.text sizeWithFont:[UIFont boldSystemFontOfSize:15.0f] constrainedToSize:CGSizeMake(197.0f, 999.0f) lineBreakMode:lineBreakMode].height;
                break;
            case 1:
                labelHeight = [self.reportLocationLabel.text sizeWithFont:[UIFont boldSystemFontOfSize:15.0f] constrainedToSize:CGSizeMake(197.0f, 999.0f) lineBreakMode:lineBreakMode].height;
                break;
            case 2:
                labelHeight = [self.reportDescriptionLabel.text sizeWithFont:[UIFont boldSystemFontOfSize:15.0f] constrainedToSize:CGSizeMake(197.0f, 999.0f) lineBreakMode:lineBreakMode].height;
                break;
                
            default:
                break;
        }
    }
    return labelHeight + 2*CELL_HEIGHT_PADDING;
}

- (void)viewDidUnload
{
    [self setReportImageView:nil];
    [self setReportCategoryLabel:nil];
    [self setReportLocationLabel:nil];
    [self setReportDescriptionLabel:nil];
    [self setImageCell:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end

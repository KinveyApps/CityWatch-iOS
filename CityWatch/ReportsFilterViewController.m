//
//  ReportsFilterViewController.m
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

#import "ReportsFilterViewController.h"

NSString *const kFilterOptionKey = @"filterOption";
NSString *const kSortOptionKey = @"sortOption";

@implementation ReportsFilterViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (self.selectedFilterOption == FilterOptionAll) self.allReportsCell.accessoryType = UITableViewCellAccessoryCheckmark;
    else if (self.selectedFilterOption == FilterOptionMine) self.myReportsCell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    if (self.selectedSortOption == SortOptionRecent) self.datePostedCell.accessoryType = UITableViewCellAccessoryCheckmark;
    else if (self.selectedSortOption == SortOptionDistance) self.distanceCell.accessoryType = UITableViewCellAccessoryCheckmark;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [[tableView cellForRowAtIndexPath:indexPath] setSelected:NO];
    
    switch (indexPath.section) {
        case 0:     // filter
            self.selectedFilterOption = indexPath.row;
            if (indexPath.row == 0) {
                self.allReportsCell.accessoryType = UITableViewCellAccessoryCheckmark;
                self.myReportsCell.accessoryType = UITableViewCellAccessoryNone;
            }
            else if (indexPath.row == 1) {
                self.myReportsCell.accessoryType = UITableViewCellAccessoryCheckmark;
                self.allReportsCell.accessoryType = UITableViewCellAccessoryNone;
            }

            break;
            
        case 1:     // sort
            self.selectedSortOption = indexPath.row;
            self.datePostedCell.accessoryType = UITableViewCellAccessoryNone;
            self.distanceCell.accessoryType = UITableViewCellAccessoryNone;
            if (indexPath.row == 0) {
                self.datePostedCell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            else if (indexPath.row == 1) {
                self.distanceCell.accessoryType = UITableViewCellAccessoryCheckmark;
            }

            break;
        default:
            break;
    }
}

- (IBAction)doneButtonPressed:(id)sender {
    NSDictionary *options = @{@"filterOption" : @(self.selectedFilterOption), @"sortOption" : @(self.selectedSortOption)};
    [self.delegate reportFilterEditingFinishedWithOptions:options];
    // animate button
    [UIView animateWithDuration:0.25 
                     animations:^{
                         ((UIView *)sender).transform = CGAffineTransformMakeRotation(M_PI - 0.01);
                     }
                     completion:^(BOOL finished) {
                         [self dismissModalViewControllerAnimated:YES];
                     }
     ];
}

- (void)viewDidUnload
{
    [self setAllReportsCell:nil];
    [self setMyReportsCell:nil];
    [self setDatePostedCell:nil];
    [self setDistanceCell:nil];
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

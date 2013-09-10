//
//  ReportsFilterViewController.h
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

#import <UIKit/UIKit.h>

typedef enum : NSUInteger { 
    FilterOptionAll = 0,
    FilterOptionMine
} FilterOption;

typedef enum : NSUInteger {
    SortOptionRecent = 0,
    SortOptionDistance
} SortOption;

extern NSString *const kFilterOptionKey;
extern NSString *const kSortOptionKey;

@protocol ReportsFilterViewControllerDelegate

- (void)reportFilterEditingFinishedWithOptions:(NSDictionary *)options;
- (void)reportFilterEditingFinishedWithFilterOption:(NSInteger)filterRow sortOption:(NSInteger)sortRow;

@end

@interface ReportsFilterViewController : UITableViewController

@property FilterOption selectedFilterOption;
@property SortOption selectedSortOption;
@property (weak, nonatomic) id <ReportsFilterViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UITableViewCell *allReportsCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *myReportsCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *datePostedCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *distanceCell;

@end

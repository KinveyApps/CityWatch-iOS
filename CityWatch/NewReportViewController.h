//
//  NewReportViewController.h
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
#import "ReportModel.h"
#import "PickerTableViewController.h"
#import "MapViewController.h"
#import "DescriptionEditorViewController.h"

@interface NewReportViewController : UIViewController <UIActionSheetDelegate, UIImagePickerControllerDelegate, 
PickerTableViewControllerDelegate, MapViewControllerDelegate, DescriptionEditorViewControllerDelegate, 
UITextFieldDelegate, MapAnnotationDelegate>

@property (strong, nonatomic) ReportModel *report;
@property (weak, nonatomic) IBOutlet UIButton *imagePickerButton;
@property (weak, nonatomic) IBOutlet UITextField *reportCategoryTextField;
@property (weak, nonatomic) IBOutlet UITextField *reportLocationTextField;
@property (weak, nonatomic) IBOutlet UITextField *reportDescriptionTextField;
@property (weak, nonatomic) IBOutlet UIButton *submitButton;

@end

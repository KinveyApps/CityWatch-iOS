//
//  NewReportViewController.m
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

#import "NewReportViewController.h"
#import <QuartzCore/QuartzCore.h>

#import "MapAnnotation.h"
#import "ReportService.h"
#import "UIImage+Resize.h"
#import "AppDelegate.h"

#define MAX_IMAGE_BUTTON_WIDTH      280.0f
#define MAX_IMAGE_BUTTON_HEIGHT     160.0f

typedef enum {
    NewReportTextFieldTypeCategory = 0,
    NewReportTextFieldTypeLocation,
    NewReportTextFieldTypeDescription
} NewReportTextFieldType;

@interface NewReportViewController() <CLLocationManagerDelegate>

@property (strong, nonatomic) UIImagePickerController *imagePickerController;
@property (strong, nonatomic) MapAnnotation *reportAnnotation;
@property (weak, nonatomic) UIImage *image;
@property (nonatomic, strong) CLLocationManager* locationManager;

@end

@implementation NewReportViewController

- (UIImagePickerController *)imagePickerController {
    if (!_imagePickerController) {
        _imagePickerController = [[UIImagePickerController alloc] init];
        _imagePickerController.delegate = (id)self;
        _imagePickerController.allowsEditing = NO;
    }
    return _imagePickerController;
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {    
    if ([segue.identifier isEqualToString:@"kSegueIdentifierPushPickerTable"]) {
        ((PickerTableViewController *)segue.destinationViewController).delegate = self;
        ((PickerTableViewController *)segue.destinationViewController).cellTitles = self.report.validCategories;
        if (![self.report.category isEqualToString:@""]) {
            ((PickerTableViewController *)segue.destinationViewController).selectedRow = [self.report.validCategories indexOfObject:self.report.category];
        }
        else ((PickerTableViewController *)segue.destinationViewController).selectedRow = -1;
    }
    else if ([segue.identifier isEqualToString:@"kSegueIdentifierPushMap"]) {
        ((MapViewController *)segue.destinationViewController).delegate = self;
        ((MapViewController *)segue.destinationViewController).reportAnnotation = self.reportAnnotation;
    }
    else if ([segue.identifier isEqualToString:@"kSegueIdentifierPushDescription"]) {
        ((DescriptionEditorViewController *)segue.destinationViewController).delegate = self;
        ((DescriptionEditorViewController *)segue.destinationViewController).description = self.report.description;
    }
}

- (void)checkIfSubmitButtonShouldBeEnabled {
    if (self.reportCategoryTextField.text && self.reportLocationTextField.text) {
        self.submitButton.enabled = YES;
    }
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {  
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self.locationManager stopMonitoringSignificantLocationChanges];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.report = [ReportModel newReportModel];
        
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" 
                                                                             style:UIBarButtonItemStyleBordered 
                                                                            target:nil 
                                                                            action:nil];    
    self.reportCategoryTextField.tag = NewReportTextFieldTypeCategory;
    self.reportLocationTextField.tag = NewReportTextFieldTypeLocation;
    self.reportDescriptionTextField.tag = NewReportTextFieldTypeDescription;
    
    self.reportCategoryTextField.delegate = self;
    self.reportLocationTextField.delegate = self;
    self.reportDescriptionTextField.delegate = self;

    self.submitButton.enabled = NO;
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.delegate = self;
    [self.locationManager startUpdatingLocation];
    
    self.imagePickerButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imagePickerButton.layer.borderColor = [UIColor colorWithHue:0 saturation:0 brightness:0.75 alpha:1].CGColor;
    self.imagePickerButton.layer.borderWidth = 5.0f;
    self.imagePickerButton.layer.cornerRadius = 10.0f;
    self.imagePickerButton.layer.masksToBounds = YES;
}


#pragma mark - UIActionSheetDelegate

- (IBAction)imageSourceSelectionButtonPressed {    
    UIActionSheet *imageSourceSelectorSheet = [[UIActionSheet alloc] initWithTitle:nil 
                                                                          delegate:self 
                                                                 cancelButtonTitle:@"Cancel" 
                                                            destructiveButtonTitle:nil 
                                                                 otherButtonTitles:@"Take Photo", @"Choose Existing Photo", nil];
    [imageSourceSelectorSheet showInView:self.view];
}


- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }
        
    switch (buttonIndex) {
        case 0: // take photo
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
            }
            else {
                NSLog(@"Camera not available");
                return;
            }
            break;
        case 1: // choose existing photo
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
                self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            }
            else {
                NSLog(@"No photos available");
                return;
            }
            break;
    }
    
    [self presentModalViewController:self.imagePickerController animated:YES];
    [self.navigationController setNavigationBarHidden:YES animated:NO]; // override showing of nav bar
}

#pragma mark - PickerTableViewControllerDelegate

- (void)pickerTableViewController:(PickerTableViewController *)picker selectedRow:(NSInteger)row {
    [self.navigationController popViewControllerAnimated:YES];
    self.report.category = self.report.validCategories[row];
    self.reportCategoryTextField.text = self.report.category;
    [self checkIfSubmitButtonShouldBeEnabled];
}

#pragma mark - MapViewControllerDelegate

- (void)mapViewControllerDoneButtonPressedWithAnnotation:(MapAnnotation *)annotation {
    [self.navigationController popViewControllerAnimated:YES];
    self.reportLocationTextField.text = annotation.subtitle;
    self.report.locationDescription = annotation.subtitle;
    self.report.lat = annotation.coordinate.latitude;
    self.report.lon = annotation.coordinate.longitude;
//    self.report.location = annotation.coordinate;
    [self checkIfSubmitButtonShouldBeEnabled];
}

#pragma mark - DescriptionEditorViewControllerDelegate

- (void)descriptionEditorFinishedEditingWithText:(NSString *)description {
    [self.navigationController popViewControllerAnimated:YES];
    self.report.description = description;
//    NSLinguisticTagger* tagger = [[NSLinguisticTagger alloc] initWithTagSchemes:@[] options:0];
//    [tagger setString:description];
//    NSRange r = [tagger sentenceRangeForRange:NSMakeRange(0, 1)];
//    self.report.summary = [description substringWithRange:r];
    self.reportDescriptionTextField.text = description;
}

-(NSString *)documentsDirectoryPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectoryPath = [paths objectAtIndex:0];
    return documentsDirectoryPath;
} 

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self dismissModalViewControllerAnimated:YES];
    
    // reset from default state
    self.imagePickerButton.backgroundColor = [UIColor clearColor];
    [self.imagePickerButton setImage:nil forState:UIControlStateNormal];
    [self.imagePickerButton setTitle:nil forState:UIControlStateNormal];
    // store new image in report
    UIImage *newImage = info[UIImagePickerControllerOriginalImage];
    
    self.image = newImage;
    
    // adjust button size according to new image aspect ratio and max dimensions
    CGSize newImagePickerButtonSize = newImage.size;
    if (newImagePickerButtonSize.height > MAX_IMAGE_BUTTON_HEIGHT) {
        newImagePickerButtonSize.height = MAX_IMAGE_BUTTON_HEIGHT;
        newImagePickerButtonSize.width = (newImage.size.width/newImage.size.height) * newImagePickerButtonSize.height;
    }
    if (newImagePickerButtonSize.width > MAX_IMAGE_BUTTON_WIDTH) {
        newImagePickerButtonSize.width = MAX_IMAGE_BUTTON_WIDTH;
        newImagePickerButtonSize.height = (newImage.size.height/newImage.size.width) * newImagePickerButtonSize.width;
    }
    
    // show new image in button
    [self.imagePickerButton setBackgroundImage:newImage forState:UIControlStateNormal];
    [self.imagePickerButton setBackgroundImage:newImage forState:UIControlStateHighlighted];
    self.imagePickerButton.frame = CGRectMake(0, 0, newImagePickerButtonSize.width, newImagePickerButtonSize.height);
    self.imagePickerButton.center = CGPointMake(160, 96);
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissModalViewControllerAnimated:YES];
}


#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    switch (textField.tag) {
        case NewReportTextFieldTypeCategory: {
            [self performSegueWithIdentifier:@"kSegueIdentifierPushPickerTable" sender:textField];
            break;
        }
        case NewReportTextFieldTypeLocation: {            
            [self performSegueWithIdentifier:@"kSegueIdentifierPushMap" sender:textField];
            break;
        }
        case NewReportTextFieldTypeDescription: {
            [self performSegueWithIdentifier:@"kSegueIdentifierPushDescription" sender:textField];
            break;
        }
        default:
            break;
    }
    return NO;
}

#pragma mark - Location
- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation* location = [locations lastObject];
    
    self.reportAnnotation = [[MapAnnotation alloc] initWithCoordinate:location.coordinate
                                                                title:@"Report Location"];
    self.reportAnnotation.delegate = self;
}

#pragma mark - MapAnnotationDelegate

- (void)mapAnnotationFinishedReverseGeocoding:(MapAnnotation *)annotation {
    // update text field with new location
    if ([self.reportLocationTextField.text isEqualToString:@""]) {
        self.reportLocationTextField.text = annotation.subtitle;
        self.report.locationDescription = annotation.subtitle;
        self.report.lon = annotation.coordinate.longitude;
        self.report.lat = annotation.coordinate.latitude;
        self.report.summary = annotation.subtitle;
    }
}

- (IBAction)cancelButtonPressed:(id)sender {
    [UIView animateWithDuration:0.25 
                     animations:^{
                         ((UIView *)sender).transform = CGAffineTransformMakeRotation(M_PI - 0.01);
                     } 
                     completion:^(BOOL finished) {
                         [self dismissModalViewControllerAnimated:YES];
                     }
     ];
}

- (IBAction)submitButtonPressed:(id)sender {
    self.report.timestamp = [NSDate date];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        UIImage *smallImage = [self.image resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:CGSizeMake(640, 640) interpolationQuality:kCGInterpolationDefault];
        self.report.image = smallImage;
        dispatch_queue_t mainThreadQueue = dispatch_get_main_queue();
        dispatch_async(mainThreadQueue, ^{
            [[ReportService sharedInstance] addReport:self.report];
            [[ReportService sharedInstance] pushReport:self.report];
            [self dismissModalViewControllerAnimated:YES];
        });
    });
    

}

- (void)viewDidUnload
{
    [self setReportCategoryTextField:nil];
    [self setReportLocationTextField:nil];
    [self setReportDescriptionTextField:nil];
    [self setImagePickerButton:nil];
    [self setSubmitButton:nil];
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

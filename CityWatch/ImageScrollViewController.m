//
//  ImageScrollViewController.m
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

#import "ImageScrollViewController.h"

#import "ReportModel.h"

@implementation ImageScrollViewController

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBarHidden = NO;
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlackTranslucent];
}

- (void)viewWillDisappear:(BOOL)animated {
    self.navigationController.navigationBar.alpha = 1;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    _mainScrollView.contentSize = _reportImageView.frame.size;
    _mainScrollView.maximumZoomScale = 4.0;
	_mainScrollView.minimumZoomScale = 1.0;
	_mainScrollView.clipsToBounds = YES;
	_mainScrollView.delegate = self;
    
    _reportImageView.image = self.report.image;
    _reportImageView.center = CGPointMake(_reportImageView.center.x, _reportImageView.center.y - _mainScrollView.frame.origin.y/2);
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapGestureHandler:)];
    doubleTap.numberOfTapsRequired = 2;
    [_mainScrollView addGestureRecognizer:doubleTap];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureHandler:)];
    [tap requireGestureRecognizerToFail:doubleTap];
    [_mainScrollView addGestureRecognizer:tap];
}

- (void)viewDidUnload
{
    [self setMainScrollView:nil];
    [self setReportImageView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _reportImageView;
}

- (CGRect)zoomRectForScale:(float)scale atCenter:(CGPoint)center {
    CGRect baseRect = _mainScrollView.frame;
    baseRect.size.width /= scale;
    baseRect.size.height /= scale;
    baseRect.origin.x = center.x - baseRect.size.width/2;
    baseRect.origin.y = center.y - baseRect.size.height/2;
    return baseRect;
}

#pragma mark - gesture handlers

- (void)doubleTapGestureHandler:(UITapGestureRecognizer *)recognizer {
    // tap to zoom
    float scale = _mainScrollView.zoomScale;
    
    if (scale > _mainScrollView.minimumZoomScale) {
        [_mainScrollView setZoomScale:_mainScrollView.minimumZoomScale animated:YES];        
    }
    else {
        [_mainScrollView zoomToRect:[self zoomRectForScale:_mainScrollView.maximumZoomScale atCenter:[recognizer locationInView:_mainScrollView]] animated:YES];
    }
}

- (void)tapGestureHandler:(UITapGestureRecognizer *)recognizer {
    [[UIApplication sharedApplication] setStatusBarHidden:![[UIApplication sharedApplication] isStatusBarHidden] withAnimation:UIStatusBarAnimationFade];
    
    BOOL navBarHidden = self.navigationController.navigationBarHidden;
    // if nav bar is hidden, unhide it before animation, since alpha is already 0
    if (navBarHidden) {
        [self.navigationController setNavigationBarHidden:NO animated:NO];
        _mainScrollView.frame = CGRectOffset(_mainScrollView.frame, 0, -10);
    }
    
    [UIView animateWithDuration:0.5 
                     animations:^{
                         float alpha = self.navigationController.navigationBar.alpha;
                         self.navigationController.navigationBar.alpha = (alpha == 0) ? 1 : 0;
                     }
                     completion:^(BOOL finished) {
                         // if nav bar is hidden, unhide it before animation, since alpha is already 0
                         if (!navBarHidden) {
                             [self.navigationController setNavigationBarHidden:YES animated:NO];
                             _mainScrollView.frame = CGRectOffset(_mainScrollView.frame, 0, 10);
                         }
                     }
     ];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait ||
            UIInterfaceOrientationIsLandscape(interfaceOrientation));
}

@end

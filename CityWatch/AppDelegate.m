//
//  AppDelegate.m
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

#import "AppDelegate.h"
#import "ReportModel.h"
#import "ReportService.h"
#import "ReportsRootViewController.h"
#import <KinveyKit/KinveyKit.h>
#import <FacebookSDK/FacebookSDK.h>

NSString *const FBSessionStateChangedNotification = @"com.kinvey.CityWatch:FBSessionStateChangedNotification";

@interface AppDelegate () <FBUserSettingsDelegate>
@property (nonatomic, strong) ReportsRootViewController* rvc;
@property (nonatomic, strong) NSString* deepLink;
@property (nonatomic, strong) FBUserSettingsViewController* fbSettings;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#warning supply Kinvey credentials here and Facebook App Id into the info.plist
    (void) [[KCSClient sharedClient] initializeKinveyServiceForAppKey:@"<#APP ID#>"
                                                        withAppSecret:@"<#APP SECRET#>"
                                                         usingOptions:nil];    
    
    // We open the session up front, as long as we have a cached token, otherwise rely on the user
    // to login explicitly with the FBUserSettingsViewController tab
    [FBSession openActiveSessionWithAllowLoginUI:NO];
    
    
    [[ReportService sharedInstance] readReportsFromDisk];
    
    _rvc = (ReportsRootViewController*)[(UINavigationController*)self.window.rootViewController topViewController];
    
    _fbSettings = [[FBUserSettingsViewController alloc] init];
    _fbSettings.publishPermissions = @[@"publish_actions"];
    _fbSettings.defaultAudience = FBSessionDefaultAudienceFriends;
    _fbSettings.delegate = self;
    _fbSettings.view.backgroundColor = [UIColor colorWithRed:214./255. green:78./255 blue:35./255. alpha:1.0];
    dispatch_async(dispatch_get_current_queue(), ^{
        [self showFacebookLogin];
    });
    
    return YES;
}


- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
    [[ReportService sharedInstance] saveReportsToDisk];
}


- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    // We need to properly handle activation of the application with regards to SSO
    // (e.g., returning from iOS 6.0 authorization dialog or from fast app switching).
    [FBSession.activeSession handleDidBecomeActive];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [FBSession.activeSession close];
}



#pragma mark - URL

/**
 * A function for parsing URL parameters.
 */
- (NSDictionary*)parseURLParams:(NSString *)query {
    NSLog(@"query=%@", query);
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSLog(@"pairs=%@", pairs);
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        NSLog(@"pair=%@", kv);
        NSString *val = [kv[1]
                         stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [params setObject:val forKey:kv[0]];
    }
    return params;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    // To check for a deep link, first parse the incoming URL
    // The resulting items dictionary will have the object, action, and id
    NSDictionary* items = [KCSFacebookHelper parseDeepLink:url];
    if (items != nil) {
        NSString* entityId = items[KCSFacebookOGEntityId];
        if (entityId != nil) {
            NSArray* reports = [ReportService sharedInstance].reports;
            __block NSUInteger reportIdx = -1;
            __block ReportModel* report = nil;
            [reports enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                ReportModel* rm = obj;
                if ([rm.kinveyObjectId isEqualToString:entityId]) {
                    reportIdx = idx;
                    report = rm;
                    *stop = YES;
                }
            }];
            if (report) {
                //found an already loaded report - show it
                [_rvc showDetailViewForReport:report];
            } else {
                //download more reports and refresh the list
                [[ReportService sharedInstance] pullReports];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(done) name:NOTIFY_FetchComplete object:nil];
                _deepLink = entityId;
            }
            
        }
    } else {
        //if not a deeplink, it is a fb signin
        dispatch_async(dispatch_get_current_queue(), ^{
            [self facebookSignInWithFBSession];
        });
    }
    return [FBSession.activeSession handleOpenURL:url];
}

- (void) done
{
    if (self.deepLink == nil) {
        return;
    }
    NSArray* reports = [ReportService sharedInstance].reports;
    __block NSUInteger reportIdx = -1;
    __block ReportModel* report = nil;
    [reports enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ReportModel* rm = obj;
        if ([rm.kinveyObjectId isEqualToString:_deepLink]) {
            reportIdx = idx;
            report = rm;
            *stop = YES;
        }
    }];
    if (report) {
        [_rvc showDetailViewForReport:report];
    }
    if (!report) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Report Not Loaded"
                              message:[NSString stringWithFormat:@"Report: %@ has not been loaded. Refresh list first.", _deepLink]
                              delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil,
                              nil];
        [alert show];
        
    }
    self.deepLink = nil;
    
}

#pragma mark - FB Login

- (void)facebookViewControllerDoneWasPressed:(id)sender
{
    [self facebookSignInWithFBSession];
}

- (void)loginViewControllerDidLogUserIn:(id)sender {
    [self facebookSignInWithFBSession];    
}

- (void) facebookSignInWithFBSession
{
    // The access token from the Facebook session and pass that to Kinvey to log in with the backend
    NSString* accessToken = [FBSession activeSession].accessTokenData.accessToken;
    if (!accessToken) {
        return;
    }
    [KCSUser loginWithSocialIdentity:KCSSocialIDFacebook
                        accessDictionary:@{ KCSUserAccessTokenKey : accessToken}
                     withCompletionBlock:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
                         if (errorOrNil == nil) {
                             [(UINavigationController*) self.window.rootViewController popViewControllerAnimated:YES];
                             [[ReportService sharedInstance] pullReports];
                             [[ReportService sharedInstance] readReportsFromDisk];
                             
                             [_rvc refreshData];
                         } else {
                             UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sign in with Facebook failed", @"Sign in with fb failed error title")
                                                                             message:[errorOrNil localizedDescription]
                                                                            delegate:nil
                                                                   cancelButtonTitle:NSLocalizedString(@"OK", @"OK")
                                                                   otherButtonTitles: nil];
                             [alert show];
                         }
                     }];
    
}

- (void) showFacebookLogin
{
    FBSession* s = [FBSession  activeSession];
    BOOL alreadyOpen = s.isOpen;
    
    if (!alreadyOpen) {
        [(UINavigationController*)self.window.rootViewController pushViewController:_fbSettings animated:NO];
    } else {
        [self facebookSignInWithFBSession];
    }

}

@end

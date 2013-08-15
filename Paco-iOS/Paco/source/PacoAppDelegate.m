/* Copyright 2013 Google Inc. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "PacoAppDelegate.h"

#import "GoogleAppEngineAuth.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "PacoClient.h"
#import "PacoColor.h"
#import "PacoMainViewController.h"
#import "PacoQuestionScreenViewController.h"
#import "PacoScheduler.h"
#import "PacoLocation.h"
#import "JCNotificationCenter.h"
#import "JCNotificationBannerPresenterSmokeStyle.h"
#import "PacoEventManager.h"

@implementation PacoAppDelegate

// this method will fire if the App is in UIApplicationStateActive state, not UIApplicationStateBackground
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
  if (notification) {
    // only show the notification if it hasn't fired before!
    // this is necessary for notifications that we fire immediately after launch to fill Notification Center
    NSString* experimentHasFired = [notification.userInfo objectForKey:@"experimentHasFired"];
    if (experimentHasFired && [experimentHasFired caseInsensitiveCompare:@"false"]) {
      [JCNotificationCenter sharedCenter].presenter = [JCNotificationBannerPresenterSmokeStyle new];
      
      [JCNotificationCenter
       enqueueNotificationWithTitle:@""
       message:notification.alertBody
       tapHandler:^{
         NSLog(@"Received tap on notification banner!");
         [[PacoClient sharedInstance].scheduler handleEvent:notification experiments:[[PacoClient sharedInstance].model experimentInstances]];
         NSString *experimentId = [notification.userInfo objectForKey:@"experimentInstanceId"];
         PacoExperiment *experiment = [[PacoClient sharedInstance].model experimentForId:experimentId];
         PacoQuestionScreenViewController *questions = [[PacoQuestionScreenViewController alloc] init];
         questions.experiment = experiment;
         [self.viewController.navigationController pushViewController:questions animated:YES];
       }];
    }
  }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  // Stir!
  arc4random_stir();
  
  // Clear all Application Badges
  application.applicationIconBadgeNumber = 0;
  
  // Override the navigation bar and item tint color globally across the app.
  [[UINavigationBar appearance] setTintColor:[PacoColor pacoBlue]];

  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  // Override point for customization after application launch.
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
    self.viewController = [[PacoMainViewController alloc] initWithNibName:nil bundle:nil];
  } else {
    self.viewController = [[PacoMainViewController alloc] initWithNibName:nil bundle:nil];
  }

  self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:self.viewController];
  [self.window makeKeyAndVisible];
  
  
  //YMZ:TODO: the following piece of code should happen after user is successfully logged in?
  UILocalNotification *notification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
  if (notification) {
    [[PacoClient sharedInstance].scheduler handleEvent:notification experiments:[[PacoClient sharedInstance].model experimentInstances]];
    NSString *experimentId = [notification.userInfo objectForKey:@"experimentInstanceId"];
    PacoExperiment *experiment = [[PacoClient sharedInstance].model experimentForId:experimentId];
    assert(experiment);
    PacoQuestionScreenViewController *questions = [[PacoQuestionScreenViewController alloc] init];
    questions.experiment = experiment;
    [self.viewController presentViewController:questions animated:YES completion:nil];
  }
  return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
  BOOL success = [[PacoClient sharedInstance].model saveToFile];
  success = success && [[PacoClient sharedInstance].scheduler writeEventsToFile];
  if (success) {
    NSLog(@"SUCCESSFULLY SAVED TO FILE");
  } else {
    NSLog(@"FAILED TO SAVE TO FILE");
  }
  [[PacoClient sharedInstance].eventManager saveDataToFile];
}

- (void)applicationWillTerminate:(UIApplication *)application {
  BOOL success = [[PacoClient sharedInstance].model saveToFile];
  if (success) {
    NSLog(@"SUCCESSFULLY SAVED TO FILE");
  } else {
    NSLog(@"FAILED TO SAVE TO FILE");
  }
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  if ([PacoClient sharedInstance].location != nil) {
    [[PacoClient sharedInstance].location enableLocationTimer];
  }
  NSLog(@"Paco is going to enter the background");
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
  if ([PacoClient sharedInstance].location != nil) {
    [[PacoClient sharedInstance].location disableLocationTimer];
  }
  NSLog(@"Paco is going to enter the foreground");
}

@end

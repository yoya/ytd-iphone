/* Copyright (c) 2011 Google Inc.
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

#import "YTDMainController.h"
#import "YouTubeDirectAppDelegate.h"
#import "YouTubeService.h"
#import "GTMOAuth2Authentication.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "UIColor+YouTubeDirect.h"

static NSString *const kOAuth2ClientIDProperty = @"OAuth2ClientID";
static NSString *const kOAuth2ClientSecretProperty = @"OAuth2ClientSecret";
static NSString *const kDevKey = @"Developer Key";
static NSString *const kAppServiceName = @"DAO: YouTube-direct";
static NSString *const kBackgroundImage = @"MainBackground.png";

@interface YTDMainController ()

- (UINavigationController *)navControllerWithViewController:
    (UIViewController *)ctrl;

@end

@implementation YTDMainController

@dynamic ytdAuthNavController;
@dynamic mainViewNavController;
@synthesize window;


#pragma mark -
#pragma mark Controller LifeCycle

- (id)init {
  self = [super init];
  if (self) {
    NSDictionary *plist = [[NSBundle mainBundle] infoDictionary];
    GTMOAuth2Authentication *authToken =
        [GTMOAuth2ViewControllerTouch
            authForGoogleFromKeychainForName:kAppServiceName
                                    clientID:[plist objectForKey:kOAuth2ClientIDProperty]
                                clientSecret:[plist objectForKey:kOAuth2ClientSecretProperty]];

    GDataServiceGoogleYouTube *youtubeService = [YouTubeService sharedInstance];
    [youtubeService setAuthorizer:authToken];
    [youtubeService setYouTubeDeveloperKey:[plist objectForKey:kDevKey]];
  }
  return self;
}

- (void)dealloc {
  [ytdAuthNavController_ release];
  [mainViewNavController_ release];
  [window_ release];

  [super dealloc];
}


#pragma mark -
#pragma mark UINavigationController methods

- (UINavigationController *)ytdAuthNavController {
  if (ytdAuthNavController_) {
    return ytdAuthNavController_;
  }

  SplashViewController *splashViewController =
      [[[SplashViewController alloc] initWithNibName:@"SplashViewController"
                                              bundle:nil] autorelease];
  UIColor *splashBGColor = [UIColor colorWithPatternImage:
      [UIImage imageNamed:kBackgroundImage]];
  [[splashViewController view] setBackgroundColor:splashBGColor];
  [splashViewController setDelegate:self];
  ytdAuthNavController_ =
      [[self navControllerWithViewController:splashViewController] retain];
  [ytdAuthNavController_ setDelegate:splashViewController];
  return ytdAuthNavController_;
}

- (UINavigationController *)mainViewNavController {
  if (mainViewNavController_) {
    return mainViewNavController_;
  }

  AssignmentListTabController *assignmentListController =
      [[[AssignmentListTabController alloc] initWithDelegate:self] autorelease];
  mainViewNavController_ =
      [[self navControllerWithViewController:assignmentListController] retain];
  return mainViewNavController_;
}


#pragma mark -
#pragma mark Getters

- (UIWindow *)window {
  if (window_) {
    return window_;
  }

  window_ = [[(YouTubeDirectAppDelegate *)[[UIApplication sharedApplication]
      delegate] window] retain];
  return window_;
}

- (UIView *)view {
  // Checks whether user is authorized through OAuth & then re-directs user
  // to appropriate controller.
  BOOL isAuthorized =
      [(GTMOAuth2Authentication *)[[YouTubeService sharedInstance] authorizer]
       canAuthorize];
  if (!isAuthorized) {
    return [[self ytdAuthNavController] view];
  } else {
    return [[self mainViewNavController] view];
  }
}


#pragma mark -
#pragma mark SplashViewDelegate

- (void)finishedSplashViewController:(SplashViewController *) viewController
                         withSuccess:(BOOL)success
                           authToken:(GTMOAuth2Authentication *)authToken {
  GDataServiceGoogleYouTube *youtubeService = [YouTubeService sharedInstance];
  if (([viewController class] == [SplashViewController class]) && success) {
    [youtubeService setAuthorizer:authToken];
    [[self window] addSubview:[[self mainViewNavController] view]];
    [[[self ytdAuthNavController] view] removeFromSuperview];
  } else {
    [youtubeService setAuthorizer:nil];
  }
}


#pragma mark -
#pragma mark SignOutDelegate

- (void)performSignOut {
  GDataServiceGoogleYouTube *youtubeService = [YouTubeService sharedInstance];
  [GTMOAuth2ViewControllerTouch revokeTokenForGoogleAuthentication:
      [youtubeService authorizer]];
  [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:kAppServiceName];
  [youtubeService setAuthorizer:nil];

  [[self window] addSubview:[[self ytdAuthNavController] view]];
  [[[self mainViewNavController] view] removeFromSuperview];
}


#pragma mark -
#pragma mark Private

- (UINavigationController *)navControllerWithViewController:
    (UIViewController *)ctrl {
  UINavigationController *navCtrl =
      [[[UINavigationController alloc] initWithRootViewController:ctrl]
      autorelease];
  [[navCtrl navigationBar] setTintColor:[UIColor ytdBlueColor]];
  return navCtrl;
}

@end

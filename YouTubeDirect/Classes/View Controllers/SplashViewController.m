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

#import "SplashViewController.h"
#import "GTMOAuth2Authentication.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "GDataServiceGoogleYouTube.h"

static const NSInteger kBlankSplashScreen = 201;
static const NSInteger kBlankSplashScreenSpinner = 202;

static NSString *const kOAuth2ClientIDProperty = @"OAuth2ClientID";
static NSString *const kOAuth2ClientSecretProperty = @"OAuth2ClientSecret";
static NSString *const kAppServiceName = @"DAO: YouTube-direct";
static NSString *const kBackgroundImage = @"MainBackground.png";

@interface SplashViewController ()

- (void)initSplashViewController;
- (void)showBlankSplashScreen:(BOOL)blank;

@end

@implementation SplashViewController

@synthesize signInController = signInController_;
@synthesize delegate = delegate_;


#pragma mark -
#pragma mark NSObject

- (void)dealloc {
  [signInController_ release];

  [super dealloc];
}


#pragma mark -
#pragma mark Actions

- (IBAction)signIn:(id)sender {
  NSDictionary *plist = [[NSBundle mainBundle] infoDictionary];

  GTMOAuth2ViewControllerTouch *authViewController =
      [[[GTMOAuth2ViewControllerTouch alloc]
          initWithScope:[NSString stringWithFormat:@"%@",
                         [GDataServiceGoogleYouTube authorizationScope]]
          clientID:[plist objectForKey:kOAuth2ClientIDProperty]
          clientSecret:[plist objectForKey:kOAuth2ClientSecretProperty]
          keychainItemName:kAppServiceName
          delegate:self
          finishedSelector:@selector(signInController:finishedWithAuth:error:)]
       autorelease];
  [self setSignInController:authViewController];

  NSString *loadingStr = NSLocalizedString(@"Loading…", @"");
  NSString *format = @"<table height = \"100%\" width=\"100%\" "
      @"bgcolor=\"#FFFFFF\"><tr><td top=\"50%\" align=\"center\">"
      @"<span style=\"font-size:16px;font-family:arial;color:rgb(0, 0, 0);\">%@"
      @"</span></td></tr></table>";
  NSString *htmlStr = [NSString stringWithFormat:format, loadingStr];
  [signInController_ setInitialHTMLString:htmlStr];

  [self initSplashViewController];
  [self showBlankSplashScreen:YES];
  [[self navigationController] pushViewController:signInController_
                                         animated:YES];
  [[signInController_ forwardButton] setHidden:YES];
  [[signInController_ backButton] setHidden:YES];
}


#pragma mark -
#pragma mark GDataOAuthViewControllerTouch delegate

- (void)signInController:(GTMOAuth2ViewControllerTouch *)signInController
        finishedWithAuth:(GTMOAuth2Authentication *)auth
                   error:(NSError *)error {
  [self showBlankSplashScreen:NO];
  if (error) {
    if ([error code] != kGTMOAuth2ErrorWindowClosed) {
      NSLog(@"Unresolved sign in error: %@ %@", error, [error userInfo]);
      UIAlertView *alertView = [[[UIAlertView alloc]
          initWithTitle:NSLocalizedString(@"Authorization", @"")
          message:NSLocalizedString(@"Could not sign in to user account", @"")
          delegate:nil
          cancelButtonTitle:NSLocalizedString(@"OK", @"")
          otherButtonTitles:nil] autorelease];
      [alertView show];
    }
    return;
  }
  [delegate_ finishedSplashViewController:self withSuccess:YES authToken:auth];
}


#pragma mark -
#pragma mark UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
  if (viewController == self) {
    [[self navigationController] setNavigationBarHidden:YES];
  } else {
    [[self navigationController] setNavigationBarHidden:NO];
  }
}


#pragma mark -
#pragma mark Private

- (void)initSplashViewController {
  UIColor *splashBGColor = [UIColor colorWithPatternImage:
      [UIImage imageNamed:kBackgroundImage]];

  UIView *blankSplashScreen = [[self view] viewWithTag:kBlankSplashScreen];
  if (!blankSplashScreen) {
    blankSplashScreen = [[[UIView alloc] init] autorelease];
    [blankSplashScreen setTag:kBlankSplashScreen];
    [blankSplashScreen setFrame:[[self view] frame]];
    [blankSplashScreen setBackgroundColor:splashBGColor];
    [[self view] addSubview:blankSplashScreen];
    [[self view] sendSubviewToBack:blankSplashScreen];

    UIActivityIndicatorView *spinner = [[[UIActivityIndicatorView alloc]
        initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray]
        autorelease];
    [spinner setCenter:[[self view] center]];
    [spinner setTag:kBlankSplashScreenSpinner];
    [[self view] addSubview:spinner];
  }
}

- (void)showBlankSplashScreen:(BOOL)blank {
  UIView *blankSplashScreen = [[self view] viewWithTag:kBlankSplashScreen];

  UIActivityIndicatorView *spinner = (UIActivityIndicatorView*)[[self view]
      viewWithTag:kBlankSplashScreenSpinner];

  if (blank) {
    [spinner startAnimating];
    [blankSplashScreen setHidden:NO];
    [[self view] bringSubviewToFront:blankSplashScreen];
    [[self view] bringSubviewToFront:spinner];
  } else {
    [spinner stopAnimating];
    [blankSplashScreen setHidden:YES];
    [[self view] sendSubviewToBack:blankSplashScreen];
    [[self view] sendSubviewToBack:spinner];
  }
}

@end

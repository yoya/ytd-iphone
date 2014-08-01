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

#import "UploaderViewController.h"

#import <AVFoundation/AVAsset.h>
#import <AVFoundation/AVAssetImageGenerator.h>
#import <AVFoundation/AVTime.h>
#import <CoreMedia/CMTime.h>

#import "YouTubeUploadTicket.h"
#import "ConnectionRequestTicket.h"
#import "YouTubeUploadHelper.h"
#import "ConnectionRequestHandler.h"
#import "UploadModel.h"
#import "YouTubeService.h"
#import "GTMOAuth2Authentication.h"
#import "Assignment.h"

static CGFloat const kPortraitKeyboardHeight = 216;
static CGFloat const kStatusBarHeight = 20;

static NSString *const kLegal = @"Legal";
static NSString *const kDefaultUser = @"default_user";
static NSString *const kKeyboardAnimID = @"slideOnKeyboard";
static NSString *const kUploaderViewControllerNib = @"UploaderViewController";

@interface UploaderViewController ()

- (void)dismissKeyboard;
- (void)generateThumbnail;
- (void)updateViewFrame:(NSNotification *)notification;
- (void)initLocationManager;
- (BOOL)isReadyToSubmit;
- (void)uploadVideoEntity;
- (void)submitToAppEngine;
- (void)finishedUploadTicket:(YouTubeUploadTicket *)ticket
                   withEntry:(GDataEntryYouTubeUpload *)videoEntry
                       error:(NSError *)error;
- (void)connectionResponse:(NSString *)response
                 withError:(NSError *)error;
- (void)setProgress:(int)percentage;
- (CGRect)keyboardBounds:(NSNotification *)fromNotification
                    view:(UIView *)view;

@end

@implementation UploaderViewController

@synthesize scrollView = scrollView_;
@synthesize titleField = titleField_;
@synthesize descriptionField = descriptionField_;
@synthesize tagField = tagField_;
@synthesize thumbnailView = thumbnailView_;
@synthesize locationLabel = locationLabel_;
@synthesize progressBar = progressBar_;
@synthesize uploadStatusLabel = uploadStatusLabel_;

@synthesize uploadStatusView = uploadStatusView_;
@synthesize startUploadButton = startUploadButton_;
@synthesize retryLastUploadButton = retryLastUploadButton_;
@synthesize pauseOrResumeButton = pauseOrResumeButton_;

@synthesize videoURL = videoURL_;
@synthesize assignment = assignment_;
@synthesize dateTaken = dateTaken_;
@synthesize latLong = latLong_;

@synthesize locationManager = locationManager_;

@synthesize youtubeUploadTicket = youtubeUploadTicket_;
@synthesize connectionRequestTicket = connectionRequestTicket_;

@synthesize imageGenerator = imageGenerator_;


#pragma mark -
#pragma mark NSObject

- (id)initWithVideoURL:(NSURL *)videoURL
            assignment:(Assignment *)assignment
             dateTaken:(NSString *)dateTaken {
  self = [super initWithNibName:kUploaderViewControllerNib bundle:nil];
  if (self) {
    videoURL_ = [videoURL retain];
    assignment_ = [assignment retain];
    dateTaken_ = [dateTaken copy];
  }
  return self;
}

- (void)dealloc {
  [scrollView_ release];
  [titleField_ release];
  [descriptionField_ release];
  [tagField_ release];
  [thumbnailView_ release];
  [locationLabel_ release];
  [progressBar_ release];
  [uploadStatusLabel_ release];

  [uploadStatusView_ release];
  [startUploadButton_ release];
  [retryLastUploadButton_ release];
  [pauseOrResumeButton_ release];

  [videoURL_ release];
  [assignment_ release];
  [dateTaken_ release];
  [latLong_ release];

  [locationManager_ setDelegate:nil];
  [locationManager_ release];

  [youtubeUploadTicket_ release];
  [connectionRequestTicket_ release];

  [imageGenerator_ release];

  [super dealloc];
}


#pragma mark -
#pragma mark Actions

- (void)showTOSAlertView {
  NSDictionary *plist = [[NSBundle mainBundle] infoDictionary];
  NSString *kLegalText = [plist objectForKey:kLegal];

  UIAlertView *alertView =
      [[[UIAlertView alloc]
        initWithTitle:NSLocalizedString(@"Terms of Service", @"")
        message:NSLocalizedString(kLegalText, @"")
        delegate:self
        cancelButtonTitle:NSLocalizedString(@"I agree", @"")
        otherButtonTitles:NSLocalizedString(@"Disagree", @""), nil]
        autorelease];
  [alertView show];
}

- (void)retryLastUpload {
  [self dismissKeyboard];

  isUploadStarted_ = YES;
  [[self startUploadButton] setEnabled:NO];

  [[self retryLastUploadButton] setEnabled:NO];

  if (!isUploadToYouTubeFinished_) {
    VideoUploadedCompletionHandler uploadHandler =
        ^(YouTubeUploadTicket *ticket,
          GDataEntryYouTubeUpload *entry,
          NSError *error) {
          [self finishedUploadTicket:ticket withEntry:entry error:error];
    };
    [[self youtubeUploadTicket] restartUpload:uploadHandler];
  } else {
    [self submitToAppEngine];
  }

  [[self uploadStatusView] setHidden:NO];
}

- (void)pauseOrResumeUpload:(id)sender {
  BOOL isPauseSelected = ![sender isSelected];
  [sender setSelected:isPauseSelected];
  if (!isUploadToYouTubeFinished_) {
    [[self youtubeUploadTicket] pauseUpload];
  } else {
    if (isPauseSelected) {
      [[self connectionRequestTicket] dropConnection];
    } else {
      [self submitToAppEngine];
    }
  }
}


#pragma mark -
#pragma mark UIViewController methods

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self
         selector:@selector(updateViewFrame:)
             name:UIKeyboardWillShowNotification
           object:nil];
  [nc addObserver:self
         selector:@selector(updateViewFrame:)
             name:UIKeyboardWillHideNotification
           object:nil];
  [[self titleField] setDelegate:self];
  [[self titleField] addTarget:self
                        action:@selector(textFieldDidChange)
              forControlEvents:UIControlEventEditingChanged];
  [[self titleField] setEnabled:YES];

  [[self descriptionField] setDelegate:self];
  [[self descriptionField] addTarget:self
                              action:@selector(textFieldDidChange)
                    forControlEvents:UIControlEventEditingChanged];
  [[self descriptionField] setEnabled:YES];

  [[self tagField] setDelegate:self];
  [[self tagField] setEnabled:YES];

  [[self progressBar] setProgress:0.0];
  [[self uploadStatusView] setHidden:YES];

  [[self startUploadButton] setEnabled:NO];
  isUploadStarted_ = NO;

  [[self retryLastUploadButton] setEnabled:NO];
  isUploadToYouTubeFinished_ = NO;

  [[self pauseOrResumeButton] setHidden:YES];
  NSString *title = nil;
  if (assignment_) {
    title = [assignment_ description];
  } else {
    title = NSLocalizedString(@"Default Assignment", @"");
  }
  [self setTitle:title];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:YES];

  [self generateThumbnail];
  [self initLocationManager];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];

  // Cancel ticket for uploading to YouTube.
  // Cancel connection to App-engine, if any.
  [[self youtubeUploadTicket] stopUpload];
  [[self connectionRequestTicket] dropConnection];
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];

  [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark -
#pragma mark keyboard notifications

- (void)updateViewFrame:(NSNotification *)notification {
  NSString* noteName = [notification name];

  // Keyboard info.
  NSDictionary* info = [notification userInfo];
  CGRect keyboardRect = [self keyboardBounds:notification
                                        view:[self view]];
  CGSize keyboardSize = keyboardRect.size;
  NSValue* value = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
  NSTimeInterval keyboardAnimDuration = 0;
  [value getValue:&keyboardAnimDuration];
  value = [info objectForKey:UIKeyboardAnimationCurveUserInfoKey];
  UIViewAnimationCurve keyboardAnimCurve = UIViewAnimationCurveEaseInOut;
  [value getValue:&keyboardAnimCurve];

  [UIView beginAnimations:kKeyboardAnimID context:nil];
  [UIView setAnimationBeginsFromCurrentState:YES];
  [UIView setAnimationCurve:keyboardAnimCurve];
  [UIView setAnimationDuration:keyboardAnimDuration];

  // Updating view's frame.
  CGRect scrollFrame = [scrollView_ frame];
  if ([noteName isEqualToString:UIKeyboardWillShowNotification]) {
    [scrollView_ setContentSize:CGSizeMake(scrollFrame.size.width,
        scrollFrame.size.height + keyboardSize.height)];
  } else {
    [scrollView_ setContentSize:CGSizeMake(scrollFrame.size.width,
        scrollFrame.size.height - keyboardSize.height)];
  }
  [scrollView_ setFrame:scrollFrame];
  [scrollView_ layoutIfNeeded];

  [UIView commitAnimations];
}


#pragma mark -
#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
  if ([scrollView_ contentOffset].y == 0) {
    int keyboardPadding = kPortraitKeyboardHeight;
    CGPoint pt = CGPointMake(0, [textField frame].origin.y +
        [textField frame].size.height + kStatusBarHeight - keyboardPadding - 3);
    [scrollView_ setContentOffset:pt animated:YES];
  }
  return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [self dismissKeyboard];
  return YES;
}


#pragma mark -
#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
  if (!isLocationUpdated_) {
    isLocationUpdated_ = YES;
    latLong_ =
        [[NSString stringWithFormat:@"latitude = %0.2f longitude = %0.2f",
          newLocation.coordinate.latitude,
          newLocation.coordinate.longitude] copy];
    NSString *locationLabelText = [NSString stringWithFormat:@"%@ %@",
        [[self locationLabel] text], latLong_];
    [[self locationLabel] setText:locationLabelText];
    [[self locationManager] stopUpdatingLocation];
  }
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
  isLocationUpdated_ = NO;
  [[self locationManager] stopUpdatingLocation];
}


#pragma mark -
#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView
    clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (buttonIndex == 0) {
    [self uploadVideoEntity];
  }
}


#pragma mark -
#pragma mark Private

- (void)uploadVideoEntity {
  [self dismissKeyboard];

  isUploadStarted_ = YES;
  [[self startUploadButton] setEnabled:NO];

  [[self retryLastUploadButton] setEnabled:NO];
  [[self titleField] setEnabled:NO];
  [[self descriptionField] setEnabled:NO];
  [[self tagField] setEnabled:NO];

  NSString *tagText = [[self tagField] text];
  NSString *tags = [tagText length] ? tagText : kDefaultVideoTag;
  UploadModel *uploadModel =
      [[[UploadModel alloc] initWithTitle:[[self titleField] text]
                              description:[[self descriptionField] text]
                                     tags:tags
                             assignmentID:[[self assignment] assignmentID]
                                  videoID:nil
                                dateTaken:[self dateTaken]
                                  latLong:[self latLong]
                                 mediaURL:videoURL_] autorelease];

  VideoUploadedCompletionHandler uploadHandler =
      ^(YouTubeUploadTicket *ticket,
        GDataEntryYouTubeUpload *entry,
        NSError *error) {
        [self finishedUploadTicket:ticket withEntry:entry error:error];
  };
  UploadProgressCompletionHandler progressHandler =
      ^(int percentage) {
        [self setProgress:percentage];
  };
  [self setYoutubeUploadTicket:
      [YouTubeUploadHelper uploadWith:uploadModel
                       youtubeService:[YouTubeService sharedInstance]
                        uploadHandler:uploadHandler
                      progressHandler:progressHandler]];

  [[self uploadStatusView] setHidden:NO];
}

- (void)submitToAppEngine {
  ConnectionCompletionHandler handler =
      ^(NSString *response, NSError *error) {
        [self connectionResponse:response withError:error];
  };
  UploadModel *model = [[self youtubeUploadTicket] model];
  NSString *accessToken =
      [[[YouTubeService sharedInstance] authorizer] accessToken];
  ConnectionRequestTicket *ticket =
      [ConnectionRequestHandler submitToYTDDomain:model
                                        authToken:accessToken
                                         userName:kDefaultUser
                                          handler:handler];
  [self setConnectionRequestTicket:ticket];
}

- (void)finishedUploadTicket:(YouTubeUploadTicket *)ticket
                   withEntry:(GDataEntryYouTubeUpload *)videoEntry
                       error:(NSError *)error {
  if (!error) {
    isUploadToYouTubeFinished_ = YES;

    [self setYoutubeUploadTicket:ticket];

    NSString *videoID = [[videoEntry mediaGroup] videoID];
    UploadModel *model = [[self youtubeUploadTicket] model];
    [model setVideoID:videoID];

    // submit to App-Engine now.
    [self submitToAppEngine];
  } else {
    UIAlertView *alertView =
        [[[UIAlertView alloc]
          initWithTitle:NSLocalizedString(@"ERROR", @"")
          message:NSLocalizedString([error localizedDescription],
                                    @"")
          delegate:nil
          cancelButtonTitle:NSLocalizedString(@"OK", @"")
          otherButtonTitles:nil] autorelease];

    [[self uploadStatusView] setHidden:YES];
    if ([ticket uploadLocationURL]) {
      [[self retryLastUploadButton] setEnabled:YES];
    } else {
      [[self startUploadButton] setEnabled:YES];
    }
    [alertView show];
  }
}

- (void)setProgress:(int)percentage {
  NSString *progressStr = [NSString stringWithFormat:@"%d%%", percentage];
  [[self uploadStatusLabel] setText:progressStr];
  [[self progressBar] setProgress:(float)percentage/100];
}

- (void)connectionResponse:(NSString *)response
                 withError:(NSError *)error {
  [self setConnectionRequestTicket:nil];
  // check for correct response.
  if (!error) {
    [self setProgress:100];
    [[self navigationController] popViewControllerAnimated:YES];
    UIActionSheet *afterUploadSheet_ =
        [[[UIActionSheet alloc]
          initWithTitle:NSLocalizedString(@"Uploaded successfully!", @"")
          delegate:nil
          cancelButtonTitle:NSLocalizedString(@"Done", @"")
          destructiveButtonTitle:nil
          otherButtonTitles:nil] autorelease];
    [afterUploadSheet_ setActionSheetStyle:UIActionSheetStyleBlackOpaque];
    [afterUploadSheet_ showInView:
        [[UIApplication sharedApplication] keyWindow]];
  } else {
    UIAlertView *alertView =
        [[[UIAlertView alloc]
          initWithTitle:NSLocalizedString(@"ERROR", @"")
          message:[error localizedDescription]
          delegate:nil
          cancelButtonTitle:NSLocalizedString(@"OK", @"")
          otherButtonTitles:nil] autorelease];
    [alertView show];

    [[self uploadStatusView] setHidden:YES];
    [[self retryLastUploadButton] setEnabled:YES];
  }
}

- (void)dismissKeyboard {
  [[self titleField] resignFirstResponder];
  [[self descriptionField] resignFirstResponder];
  [[self tagField] resignFirstResponder];
}

- (void)generateThumbnail {
  AVURLAsset *asset = [[[AVURLAsset alloc] initWithURL:videoURL_ options:nil]
                       autorelease];
  AVAssetImageGenerator *generator =
      [[[AVAssetImageGenerator alloc] initWithAsset:asset] autorelease];
  [self setImageGenerator:generator];
  [generator setAppliesPreferredTrackTransform:TRUE];
  CMTime thumbTime = CMTimeMakeWithSeconds(0,30);

  AVAssetImageGeneratorCompletionHandler handler =
      ^(CMTime requestedTime, CGImageRef im, CMTime actualTime,
        AVAssetImageGeneratorResult result, NSError *error) {
        if (result != AVAssetImageGeneratorSucceeded) {
          NSLog(@"Couldn't generate thumbnail, error:%@", error);
        }
        [[self thumbnailView] setImage:[UIImage imageWithCGImage:im]];
  };
  NSValue *thumbnailTime = [NSValue valueWithCMTime:thumbTime];
  NSArray *imageGenerationTimes = [NSArray arrayWithObject:thumbnailTime];
  [generator generateCGImagesAsynchronouslyForTimes:imageGenerationTimes
                                  completionHandler:handler];
}

- (void)initLocationManager {
  #if TARGET_IPHONE_SIMULATOR
  // TODO: Provide Default Values.
  #else
  isLocationUpdated_ = NO;
  locationManager_ = [[[CLLocationManager alloc] init] retain];
  [[self locationManager] setDelegate:self];

  [[self locationManager] setDesiredAccuracy:kCLLocationAccuracyBest];
  [[self locationManager] setDistanceFilter:kCLDistanceFilterNone];

  [[self locationManager] startUpdatingLocation];
  #endif
}

- (void)textFieldDidChange {
  BOOL upload = [self isReadyToSubmit] && !isUploadStarted_;
  [[self startUploadButton] setEnabled:upload];
}

- (BOOL)isReadyToSubmit {
  BOOL isReady = [[self titleField].text length] > 0 &&
      [[self descriptionField].text length] > 0;
  return isReady;
}

- (CGRect)keyboardBounds:(NSNotification *)fromNotification
                    view:(UIView *)view {
  NSDictionary *userInfo = [fromNotification userInfo];
  NSValue *rectValue =
  [userInfo objectForKey:@"UIKeyboardFrameBeginUserInfoKey"];
  if (rectValue) {
    rectValue =
        [NSValue valueWithCGRect:
            [view convertRect:[rectValue CGRectValue] fromView:nil]];
  } else {
    rectValue = [userInfo objectForKey:@"UIKeyboardBoundsUserInfoKey"];
  }
  CGRect toRect = rectValue ? [rectValue CGRectValue] : CGRectZero;
  return toRect;
}

@end

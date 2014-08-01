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

#import "AssignmentListTabController.h"

#import <QuartzCore/QuartzCore.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "AssignmentListController.h"
#import "AssignmentListCell.h"
#import "Assignment.h"
#import "UploaderViewController.h"
#import "UIColor+YouTubeDirect.h"

typedef enum {
  kMediaSourceTypeCamera,
  kMediaSourceTypePhotoLibrary,
} MediaSourceTypeEnum;

static NSString *const kBackgroundImage = @"MainBackground.png";
static NSString *const kFooterButtonImage = @"footer_button_bg.jpg";
static NSString *const kFooterButtonPressedImage =
    @"footer_button_press_bg.jpg";

static NSString *const kDefaultDateFormat = @"EEE MMM dd HH':'mm':'ss z yyyy";

static const CGFloat kTabButtonHeight = 48;
static const CGFloat kNavigationBarHeight = 44;

@interface AssignmentListTabController ()

- (void)addFooterButtonWithText:(NSString *)title
                         action:(SEL)action
                     leftOffset:(CGFloat)leftOffset;
- (void)showMediaPickerController:(MediaSourceTypeEnum)sourceType;
- (void)attachVideo:(NSURL *)videoURL;

// Called if user opts to shoot a video.
- (void)captureVideo:(id)sender;

// Called if user opts to select a video via the gallery.
- (void)selectVideo:(id)sender;

@property(nonatomic, retain, readonly) AssignmentListController
    *assignmentListController;
@property(nonatomic, retain) Assignment *selectedAssignment;

@end

@implementation AssignmentListTabController

@synthesize assignmentListController = assignmentListController_;
@synthesize selectedAssignment = selectedAssignment_;


#pragma mark -
#pragma mark NSObject

- (id)initWithDelegate:(id<SignOutDelegate>)delegate {
  self = [super init];
  if (self) {
    delegate_ = delegate;
  }
  return self;
}

- (void)dealloc {
  [assignmentListController_ release];
  [selectedAssignment_ release];
  [selectedVideoDate_ release];

  [super dealloc];
}


#pragma mark -
#pragma mark Actions

- (void)submit:(id)sender {
  UIActionSheet *selectMediaSheet = [[[UIActionSheet alloc]
      initWithTitle:NSLocalizedString(@"Choose Media", @"")
      delegate:self
      cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
      destructiveButtonTitle:nil
      otherButtonTitles:NSLocalizedString(@"From Gallery", @""),
                        NSLocalizedString(@"Shoot Video", @""),
      nil] autorelease];
  [selectMediaSheet setActionSheetStyle:UIActionSheetStyleBlackOpaque];
  [selectMediaSheet showInView:[[UIApplication sharedApplication] keyWindow]];
}

- (void)settings:(id)sender {
  // Currently performing signing-out.
  UIAlertView *alertView = [[[UIAlertView alloc]
      initWithTitle:NSLocalizedString(@"Sign out", @"")
      message:NSLocalizedString(@"Do you want to sign out?", @"")
      delegate:nil
      cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
      otherButtonTitles:NSLocalizedString(@"Sign out", @""), nil] autorelease];
  [alertView setDelegate:self];
  [alertView show];
}

- (void)captureVideo:(id)sender {
  if ([UIImagePickerController
       isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
    Assignment *assignment = nil;
    if ([[[sender superview] superview] isKindOfClass:[AssignmentListCell class]]) {
      AssignmentListCell *cellView = (AssignmentListCell *)[[sender superview] superview];
      assignment = [cellView assignment];
    }
    [self setSelectedAssignment:assignment];
    [self showMediaPickerController:kMediaSourceTypeCamera];
  }
}

- (void)selectVideo:(id)sender {
  Assignment *assignment = nil;
  if ([[[sender superview] superview] isKindOfClass:[AssignmentListCell class]]) {
    AssignmentListCell *cellView = (AssignmentListCell *)[[sender superview] superview];
    assignment = [cellView assignment];
  }
  [self setSelectedAssignment:assignment];
  [self showMediaPickerController:kMediaSourceTypePhotoLibrary];
}

- (void)showMediaPickerController:(MediaSourceTypeEnum)sourceType {
  UIImagePickerController *picker =
      [[[UIImagePickerController alloc] init] autorelease];
  [picker setDelegate:self];
  [picker setMediaTypes:[NSArray arrayWithObject:(NSString *)kUTTypeMovie]];
  switch (sourceType) {
    case kMediaSourceTypeCamera:
      [picker setSourceType:UIImagePickerControllerSourceTypeCamera];
      break;
    case kMediaSourceTypePhotoLibrary:
      [picker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
      break;
    default:
      NSLog(@"Undefined source type.");
      break;
  }

  [[picker navigationBar] setTintColor:[UIColor ytdBlueColor]];
  [self presentModalViewController:picker animated:YES];
}

- (void)attachVideo:(NSURL *)videoURL {
  UploaderViewController *uploaderViewController =
      [[[UploaderViewController alloc] initWithVideoURL:videoURL
                                             assignment:selectedAssignment_
                                             dateTaken:selectedVideoDate_] autorelease];
  UIBarButtonItem *backButton =
      [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"")
                                        style:UIBarButtonItemStylePlain
                                       target:self
                                       action:nil] autorelease];
  [[self navigationItem] setBackBarButtonItem:backButton];
  [[self navigationController] pushViewController:uploaderViewController
                                         animated:YES];
  [[self view] setUserInteractionEnabled:YES];
}


#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad {
  [[self navigationItem] setTitle:NSLocalizedString(@"YouTube DIRECT", @"")];
  CGRect bounds = [[self view] bounds];
  [self addFooterButtonWithText:NSLocalizedString(@"Submit", @"")
                         action:@selector(submit:)
                     leftOffset:0.0];
  [self addFooterButtonWithText:NSLocalizedString(@"Sign Out", @"")
                         action:@selector(settings:)
                     leftOffset:ceil((CGRectGetWidth(bounds) + 1) / 2.0)];

  [[[self assignmentListController] view]
      setFrame:CGRectMake(
      0,
      0,
      CGRectGetWidth(bounds),
      CGRectGetHeight(bounds) - kTabButtonHeight)];

  UIColor *backGroundColor =
      [UIColor colorWithPatternImage:[UIImage imageNamed:kBackgroundImage]];
  [[[self assignmentListController] view] setBackgroundColor:backGroundColor];
  [[self view] addSubview:[[self assignmentListController] view]];
}

- (void)viewWillAppear:(BOOL)animated {
  [[self assignmentListController] viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
  [[self assignmentListController] viewWillDisappear:animated];
}

- (AssignmentListController *)assignmentListController {
  if (!assignmentListController_) {
    assignmentListController_ = [[AssignmentListController alloc] init];
  }
  return assignmentListController_;
}


#pragma mark -
#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker
    didFinishPickingMediaWithInfo:(NSDictionary *)info {
  ALAssetsLibrary *assetLibrary = [[[ALAssetsLibrary alloc] init] autorelease];
  ALAssetsLibraryAssetForURLResultBlock resultBlock = ^(ALAsset *myasset) {
    NSDate *videoDate;
    if ([picker sourceType] == UIImagePickerControllerSourceTypeCamera) {
      videoDate = [NSDate date];
    } else {
      videoDate = [myasset valueForProperty:ALAssetPropertyDate];
      if (!videoDate) {
        videoDate = [NSDate date];
      }
    }
    NSDateFormatter *fmt = [[[NSDateFormatter alloc] init] autorelease];
    [fmt setDateFormat:kDefaultDateFormat];
    selectedVideoDate_ = [[fmt stringFromDate:videoDate] copy];
  };

  ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError *myerror) {
    NSLog(@"Cannot get asset - %@", [myerror localizedDescription]);
  };

  [assetLibrary
      assetForURL:[info objectForKey:UIImagePickerControllerReferenceURL]
      resultBlock:resultBlock
      failureBlock:failureBlock];

  NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
  if ([mediaType isEqualToString:(NSString *)kUTTypeMovie]) {
    NSURL *videoURL = [info objectForKey:UIImagePickerControllerMediaURL];
    if (!videoURL) {
      UIAlertView *alertView = [[[UIAlertView alloc]
          initWithTitle:NSLocalizedString(@"Error", @"")
          message:NSLocalizedString(@"Video selection interrupted.", @"")
          delegate:nil
          cancelButtonTitle:NSLocalizedString(@"OK", @"")
          otherButtonTitles:nil] autorelease];
      [alertView setDelegate:self];
      [alertView show];
      [picker dismissModalViewControllerAnimated:YES];
      return;
    } else if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum([videoURL path]) &&
          [picker sourceType] == UIImagePickerControllerSourceTypeCamera) {
      UISaveVideoAtPathToSavedPhotosAlbum([videoURL path], nil, nil, nil);
    }

    [[self view] setUserInteractionEnabled:NO];
    [picker dismissModalViewControllerAnimated:YES];

    // Introduces a delay of 0.5f, otherwise screen transition (from this
    // controller to UploaderViewController) produces some flickering.
    [self performSelector:@selector(attachVideo:)
               withObject:videoURL
               afterDelay:0.5f];
  }
}


#pragma mark -
#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView
    clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (buttonIndex == 1) {
    [delegate_ performSignOut];
  }
}


#pragma mark -
#pragma mark UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet
    clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (buttonIndex == 0) {
    [self selectVideo:nil];
  } else if (buttonIndex == 1) {
    [self captureVideo:nil];
  }
}


#pragma mark -
#pragma mark Private

- (void)addFooterButtonWithText:(NSString *)title
                         action:(SEL)action
                     leftOffset:(CGFloat)leftOffset {
  CGRect bounds = [[self view] bounds];
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  [button setTitle:title forState:UIControlStateNormal];
  [button setBackgroundImage:[UIImage imageNamed:kFooterButtonImage]
                    forState:UIControlStateNormal];
  [button setBackgroundImage:[UIImage imageNamed:kFooterButtonPressedImage]
                    forState:UIControlStateHighlighted];
  [button setFrame:CGRectMake(
      leftOffset,
      CGRectGetHeight(bounds) - (kNavigationBarHeight + kTabButtonHeight),
      CGRectGetWidth(bounds) / 2.0,
      kTabButtonHeight)];
  [button addTarget:self action:action
      forControlEvents:UIControlEventTouchUpInside];
  [[button layer] setMasksToBounds:YES];

  [[self view] addSubview:button];
}

@end

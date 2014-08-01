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

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@class AVAssetImageGenerator;

@class YouTubeUploadTicket;
@class ConnectionRequestTicket;
@class Assignment;

// Controller handles video upload to YouTube and App-engine.
@interface UploaderViewController : UIViewController
    <UITextFieldDelegate, CLLocationManagerDelegate, UIAlertViewDelegate> {
 @private
  UIScrollView *scrollView_;
  UITextField *titleField_;
  UITextField *descriptionField_;
  UITextField *tagField_;
  UIImageView *thumbnailView_;
  UILabel *locationLabel_;
  UIProgressView *progressBar_;
  UILabel *uploadStatusLabel_;
  UIView *uploadStatusView_;
  UIButton *startUploadButton_;
  UIButton *retryLastUploadButton_;
  UIButton *pauseOrResumeButton_;

  NSURL *videoURL_;
  Assignment *assignment_;
  NSString *dateTaken_;
  NSString *latLong_;

  CLLocationManager *locationManager_;

  YouTubeUploadTicket *youtubeUploadTicket_;
  ConnectionRequestTicket *connectionRequestTicket_;

  AVAssetImageGenerator *imageGenerator_;

  BOOL isLocationUpdated_;
  BOOL isUploadStarted_;
  BOOL isUploadToYouTubeFinished_;
}

@property(nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property(nonatomic, retain) IBOutlet UITextField *titleField;
@property(nonatomic, retain) IBOutlet UITextField *descriptionField;
@property(nonatomic, retain) IBOutlet UITextField *tagField;
@property(nonatomic, retain) IBOutlet UIImageView *thumbnailView;
@property(nonatomic, retain) IBOutlet UILabel *locationLabel;
@property(nonatomic, retain) IBOutlet UIProgressView *progressBar;
@property(nonatomic, retain) IBOutlet UILabel *uploadStatusLabel;
@property(nonatomic, retain) IBOutlet UIView *uploadStatusView;
@property(nonatomic, retain) IBOutlet UIButton *startUploadButton;
@property(nonatomic, retain) IBOutlet UIButton *retryLastUploadButton;
@property(nonatomic, retain) IBOutlet UIButton *pauseOrResumeButton;

@property(nonatomic, retain) NSURL *videoURL;
@property(nonatomic, retain) Assignment *assignment;
@property(nonatomic, copy) NSString *dateTaken;
@property(nonatomic, copy, readonly) NSString *latLong;

@property(nonatomic, retain, readonly) CLLocationManager *locationManager;

@property(nonatomic, retain) YouTubeUploadTicket *youtubeUploadTicket;
@property(nonatomic, retain) ConnectionRequestTicket *connectionRequestTicket;

@property(nonatomic, retain) AVAssetImageGenerator *imageGenerator;

// init method
- (UploaderViewController *)initWithVideoURL:(NSURL *)videoURL
                                  assignment:(Assignment *)assignment
                                   dateTaken:(NSString *)dateTaken;

// Show 'Terms Of Service'
- (IBAction)showTOSAlertView;

// Retry the unfinished upload.
- (IBAction)retryLastUpload;

// Pause/Resume current upload.
- (IBAction)pauseOrResumeUpload:(id)sender;

@end

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

#import <Foundation/Foundation.h>

#import "GDataEntryYouTubeUpload.h"

@class GDataServiceGoogleYouTube;
@class YouTubeUploadTicket;
@class UploadModel;

extern NSString *const kDefaultVideoTag;

typedef void (^VideoUploadedCompletionHandler)(YouTubeUploadTicket *ticket,
                                               GDataEntryYouTubeUpload *entry,
                                               NSError *error);
typedef void (^UploadProgressCompletionHandler)(int percentage);

// Ticket class corresponding to youtube upload.
@interface YouTubeUploadTicket : NSObject {
 @private
  UploadModel *model_;
  GDataServiceGoogleYouTube *youtubeService_;
  GDataServiceTicket *ticket_;
  NSURL *uploadLocationURL_;
  VideoUploadedCompletionHandler videoUploadedHandler_;
  UploadProgressCompletionHandler uploadProgressHandler_;
}

@property(nonatomic, retain) UploadModel *model;
@property(nonatomic, retain) NSURL *uploadLocationURL;

// init method
- (id)initWithUploadModel:(UploadModel *)model
           youtubeService:(GDataServiceGoogleYouTube *)service;

// setters and getters
- (GDataServiceTicket *)uploadTicket;
- (void)setUploadTicket:(GDataServiceTicket *)ticket;

- (void)startUpload:(VideoUploadedCompletionHandler)uploadHandler
    progressHandler:(UploadProgressCompletionHandler)progressHandler;
- (void)stopUpload;

- (void)pauseUpload;
- (void)restartUpload:(VideoUploadedCompletionHandler)uploadHandler;

@end

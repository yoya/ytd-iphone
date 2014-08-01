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

#import "YouTubeUploadHelper.h"
#import "UploadModel.h"
#import "GDataServiceGoogleYouTube.h"

@implementation YouTubeUploadHelper


#pragma mark -
#pragma mark public methods

+ (YouTubeUploadTicket *)uploadWith:(UploadModel *)model
    youtubeService:(GDataServiceGoogleYouTube *)service
    uploadHandler:(VideoUploadedCompletionHandler)uploadHandler
    progressHandler:(UploadProgressCompletionHandler)progressHandler {
  YouTubeUploadTicket *youtubeUploadTicket =
      [[[YouTubeUploadTicket alloc] initWithUploadModel:model
                                         youtubeService:service] autorelease];
  [youtubeUploadTicket startUpload:uploadHandler
                   progressHandler:progressHandler];
  return youtubeUploadTicket;
}

@end

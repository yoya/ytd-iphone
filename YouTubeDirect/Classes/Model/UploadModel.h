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

// Model class for video upload.
@interface UploadModel : NSObject {
 @private
  NSString *title_;
  NSString *description_;
  NSString *tags_;
  NSString *assignmentID_;
  NSString *videoID_;
  NSString *dateTaken_;
  NSString *latLong_;
  NSURL *mediaURL_;
}

@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSString *description;
@property(nonatomic, copy) NSString *tags;
@property(nonatomic, copy) NSString *assignmentID;
@property(nonatomic, copy) NSString *videoID;
@property(nonatomic, copy) NSString *dateTaken;
@property(nonatomic, copy) NSString *latLong;
@property(nonatomic, retain) NSURL *mediaURL;

// init method
- (id)initWithTitle:(NSString *)title
        description:(NSString *)description
               tags:(NSString *)tags
       assignmentID:(NSString *)assignmentID
            videoID:(NSString *)videoID
          dateTaken:(NSString *)dateTaken
            latLong:(NSString *)latLong
           mediaURL:(NSURL *)mediaURL;

@end

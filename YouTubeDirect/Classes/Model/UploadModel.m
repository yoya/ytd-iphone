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

#import "UploadModel.h"

@implementation UploadModel

@synthesize title = title_;
@synthesize description = description_;
@synthesize tags = tags_;
@synthesize assignmentID = assignmentID_;
@synthesize videoID = videoID_;
@synthesize dateTaken = dateTaken_;
@synthesize latLong = latLong_;
@synthesize mediaURL = mediaURL_;

- (id)initWithTitle:(NSString *)title
        description:(NSString *)description
               tags:(NSString *)tags
       assignmentID:(NSString *)assignmentID
            videoID:(NSString *)videoID
          dateTaken:(NSString *)dateTaken
            latLong:(NSString *)latLong
           mediaURL:(NSURL *)mediaURL {
  self = [super init];
  if (self) {
    title_ = [title copy];
    description_ = [description copy];
    tags_ = [tags copy];
    assignmentID_ = [assignmentID copy];
    videoID_ = [videoID copy];
    dateTaken_ = [dateTaken copy];
    latLong_ = [latLong copy];
    mediaURL_ = [mediaURL retain];
  }
  return self;
}

- (void)dealloc {
  [title_ release];
  [description_ release];
  [tags_ release];
  [assignmentID_ release];
  [videoID_ release];
  [dateTaken_ release];
  [latLong_ release];
  [mediaURL_ release];

  [super dealloc];
}

@end

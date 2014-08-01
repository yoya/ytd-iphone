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

#import "Assignment.h"

@implementation Assignment

@synthesize title = title_;
@synthesize description = description_;
@synthesize status = status_;
@synthesize assignmentID = assignmentID_;
@synthesize playlistID = playlistID_;
@synthesize updatedDate = updatedDate_;
@synthesize createdDate = createdDate_;
@synthesize heading = heading_;

- (id)initWithTitle:(NSString *)title
        description:(NSString *)description
             status:(NSString *)status
       assignmentID:(NSString *)assignmentID
         playlistID:(NSString *)playlistID
        updatedDate:(NSDate *)updatedDate
        createdDate:(NSDate *)createdDate
            heading:(BOOL)heading {
  self = [super init];
  if (self) {
    title_ = [title copy];
    description_ = [description copy];
    status_ = [status copy];
    assignmentID_ = [assignmentID copy];
    playlistID_ = [playlistID copy];
    updatedDate_ = [updatedDate retain];
    createdDate_ = [createdDate retain];
    heading_ = heading;
  }
  return self;
}

- (void)dealloc {
  [title_ release];
  [description_ release];
  [status_ release];
  [assignmentID_ release];
  [playlistID_ release];
  [updatedDate_ release];
  [createdDate_ release];

  [super dealloc];
}

@end

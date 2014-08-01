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

// Model class for an assignment.
@interface Assignment : NSObject {
 @private
  NSString *title_;
  NSString *description_;
  NSString *status_;
  NSString *assignmentID_;
  NSString *playlistID_;

  NSDate *updatedDate_;
  NSDate *createdDate_;

  BOOL heading_;
}

@property(nonatomic, copy, readonly) NSString *status;
@property(nonatomic, copy, readonly) NSString *assignmentID;
@property(nonatomic, copy, readonly) NSString *playlistID;
@property(nonatomic, copy, readonly) NSString *title;
@property(nonatomic, copy, readonly) NSString *description;

@property(nonatomic, retain, readonly) NSDate *updatedDate;
@property(nonatomic, retain, readonly) NSDate *createdDate;

@property(nonatomic, assign, getter=isHeading, readonly) BOOL heading;

// init method
- (id)initWithTitle:(NSString *)title
        description:(NSString *)description
             status:(NSString *)status
       assignmentID:(NSString *)assignmentID
         playlistID:(NSString *)playlistID
        updatedDate:(NSDate *)updatedDate
        createdDate:(NSDate *)createdDate
            heading:(BOOL)heading;

@end

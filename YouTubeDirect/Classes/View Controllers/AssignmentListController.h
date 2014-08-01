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

#import "PullRefreshTableViewController.h"

// Custom TableViewController which forms the basis of populating
// every Assignment entry to each cell.
@interface AssignmentListController : PullRefreshTableViewController {
 @private
  NSMutableDictionary *sections_;
  NSArray *sortedKeys_;

  NSIndexPath *selectedIndexPath_;
  UIView *spinner_;
  UIActivityIndicatorView *loadingSpinner_;

  NSDateFormatter *fetchDateFormatter_;
  NSDateFormatter *compareDateFormatter_;

  BOOL firstViewAppear_;
}

@end

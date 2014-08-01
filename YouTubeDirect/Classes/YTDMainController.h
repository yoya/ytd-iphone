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

#import "AssignmentListTabController.h"
#import "SplashViewController.h"

// Controller to manage application flow just before or after the user
// authenticates.
@interface YTDMainController : NSObject
    <SplashViewDelegate, SignOutDelegate> {
 @private
  UINavigationController *ytdAuthNavController_;
  UINavigationController *mainViewNavController_;
  UIWindow *window_;
}

@property(nonatomic, readonly) UINavigationController
    *ytdAuthNavController;
@property(nonatomic, readonly) UINavigationController
    *mainViewNavController;
@property(nonatomic, readonly) UIWindow *window;

- (UIView *)view;

@end

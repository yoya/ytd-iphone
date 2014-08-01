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

@class SplashViewController;
@class GTMOAuth2Authentication;
@class GTMOAuth2ViewControllerTouch;

@protocol SplashViewDelegate <NSObject>
 @required
- (void)finishedSplashViewController:(SplashViewController *)viewController
                         withSuccess:(BOOL)success
                           authToken:(GTMOAuth2Authentication *)authToken;
@end

// Controller for the sign-in screen.
@interface SplashViewController : UIViewController
    <UINavigationControllerDelegate> {
 @private
  GTMOAuth2ViewControllerTouch *signInController_;
  id<SplashViewDelegate> delegate_;
}

@property(nonatomic, retain) GTMOAuth2ViewControllerTouch *signInController;
@property(nonatomic, assign) id<SplashViewDelegate> delegate;

- (IBAction)signIn:(id)sender;

@end

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

#import "YouTubeService.h"

static GDataServiceGoogleYouTube *gShared = nil;

@implementation YouTubeService


#pragma mark -
#pragma mark singleton object methods

+ (GDataServiceGoogleYouTube *)sharedInstance {
  @synchronized(self) {
    if (!gShared) {
      gShared = [[GDataServiceGoogleYouTube allocWithZone:NULL] init];
      [gShared setShouldCacheResponseData:YES];
      [gShared setServiceShouldFollowNextLinks:YES];
      [gShared setIsServiceRetryEnabled:YES];
    }
  }
  return gShared;
}

+ (id)allocWithZone:(NSZone *)zone {
  return [[self sharedInstance] retain];
}

- (id)copyWithZone:(NSZone *)zone {
  return self;
}

- (id)retain {
  return self;
}

- (unsigned)retainCount {
  return UINT_MAX;
}

- (void)release {
  //do nothing
}

- (id)autorelease {
  return self;
}

- (void)dealloc {
  [super dealloc];
}
@end

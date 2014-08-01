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

#import "ConnectionRequestTicket.h"
#import "GTMHTTPFetcher.h"

static NSString *const kYTDTicketKey = @"YTDTicket_";

@interface ConnectionRequestTicket ()

- (NSString *)convertJSONDataToString:(NSData *)jsonData;

@end

@implementation ConnectionRequestTicket

#pragma mark -
#pragma mark NSObject

- (id)initWithRequest:(NSURLRequest *)request
              handler:(ConnectionCompletionHandler)handler {
  self = [super init];
  if (self) {
    httpFetcher_ = [[GTMHTTPFetcher fetcherWithRequest:request] retain];
    handler_ = [handler copy];
  }
  return self;
}

- (void)dealloc {
  [httpFetcher_ release];
  [handler_ release];

  [super dealloc];
}


#pragma mark -
#pragma mark Connection methods

- (void)performRPCWithJSON {
  [httpFetcher_ setProperty:self forKey:kYTDTicketKey];

  [httpFetcher_ beginFetchWithCompletionHandler:
      ^(NSData *retrievedData, NSError *error) {
        NSString *string = [self convertJSONDataToString:retrievedData];
        handler_(string,error);

        [httpFetcher_ setProperties:nil];
  }];
}

- (void)dropConnection {
  [httpFetcher_ stopFetching];

  [httpFetcher_ release];
  [handler_ release];
  httpFetcher_ = nil;
  handler_ = nil;
}


#pragma mark -
#pragma mark private methods

- (NSString *)convertJSONDataToString:(NSData *)jsonData {
  NSString *string =
      [[[NSString alloc] initWithData:jsonData
                             encoding:NSUTF8StringEncoding] autorelease];
  return string;
}

@end

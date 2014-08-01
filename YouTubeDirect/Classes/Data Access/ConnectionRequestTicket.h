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

@class GTMHTTPFetcher;

typedef void (^ConnectionCompletionHandler)(NSString *response, NSError *error);

// Ticket class for communication with app-engine.
@interface ConnectionRequestTicket : NSObject {
 @private
  GTMHTTPFetcher *httpFetcher_;
  ConnectionCompletionHandler handler_;
}

// init method.
- (id)initWithRequest:(NSURLRequest *)request
              handler:(ConnectionCompletionHandler)handler;

// Initiates a fresh HttpFetcher connection from the handler object.
- (void)performRPCWithJSON;

// Stops HttpFetcher connection & sets it to nil.
- (void)dropConnection;

@end

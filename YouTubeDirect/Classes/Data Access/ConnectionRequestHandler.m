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

#import "ConnectionRequestHandler.h"
#import "UploadModel.h"

#import "NSString+SBJSON.h"
#import "NSObject+SBJSON.h"

static NSString *const kYTDDomainKey = @"Default_ytd_domain";

static NSString *const kSortByKey = @"sortBy";
static NSString *const kSortByCreated = @"created";
static NSString *const kSortOrderKey = @"sortOrder";
static NSString *const kSortOrderDesc = @"desc";
static NSString *const kFilterTypeKey = @"filterType";
static NSString *const kFilterTypeAll = @"all";
static NSString *const kPageIndexKey = @"pageIndex";
static NSString *const kPageIndex = @"1";
static NSString *const kPageSizeKey = @"pageSize";
static NSString *const kPageSize = @"30";

static NSString *const kGetAssignmentsMethod = @"GET_ASSIGNMENTS";
static NSString *const kVideoSubmissionMethod = @"NEW_MOBILE_VIDEO_SUBMISSION";
static NSString *const kMethodKey = @"method";
static NSString *const kParamKey = @"params";

static NSString *const kVideoIDKey = @"videoId";
static NSString *const kYouTubeNameKey = @"youTubeName";
static NSString *const kAuthTokenKey = @"authToken";
static NSString *const kTitleKey = @"title";
static NSString *const kDescriptionKey = @"description";
static NSString *const kVideoDateKey = @"videoDate";
static NSString *const kTagsKey = @"tags";

static NSString *const kVideoLocationKey = @"videoLocation";
static NSString *const kAssignmentIDKey = @"assignmentId";

static NSString *const kUserAgent = @"YouTube DIRECT";
static NSString *const kContentType = @"application/json";

@interface ConnectionRequestHandler ()

+ (NSURLRequest *)requestWithData:(NSData *)postData;

+ (NSData *)postDataFromUploadModel:(UploadModel *)model
                          authToken:(NSString *)authToken
                           userName:(NSString *)userName;

@end

@implementation ConnectionRequestHandler

#pragma mark -
#pragma mark Connection methods

+ (ConnectionRequestTicket *)fetchAssignments:
    (ConnectionCompletionHandler)handler {
  NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                          kSortByCreated, kSortByKey,
                          kSortOrderDesc, kSortOrderKey,
                          kFilterTypeAll, kFilterTypeKey,
                          kPageIndex, kPageIndexKey,
                          kPageSize, kPageSizeKey,
                          nil];
  NSString *paramsJSON = [params JSONRepresentation];
  id paramsJSONObject = [paramsJSON JSONValue];
  NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                        kGetAssignmentsMethod, kMethodKey,
                        paramsJSONObject, kParamKey,
                        nil];
  NSString *postJSON = [dict JSONRepresentation];
  NSData *postData = [postJSON dataUsingEncoding:NSUTF8StringEncoding];
  NSURLRequest *request = [self requestWithData:postData];

  ConnectionRequestTicket *ticket =
      [[[ConnectionRequestTicket alloc] initWithRequest:request
                                                handler:handler] autorelease];
  [ticket performRPCWithJSON];
  return ticket;
}

+ (ConnectionRequestTicket *)submitToYTDDomain:(UploadModel *)model
    authToken:(NSString *)authToken
    userName:(NSString *)userName
    handler:(ConnectionCompletionHandler)handler {
  NSData *postData = [self postDataFromUploadModel:model
                                         authToken:authToken
                                          userName:userName];
  NSURLRequest *request = [self requestWithData:postData];

  ConnectionRequestTicket *ticket =
      [[[ConnectionRequestTicket alloc] initWithRequest:request
                                                handler:handler] autorelease];
  [ticket performRPCWithJSON];
  return ticket;
}


#pragma mark -
#pragma mark private methods

+ (NSURLRequest *)requestWithData:(NSData *)postData {
  NSDictionary *plist = [[NSBundle mainBundle] infoDictionary];
  NSString *ytdDomain = [NSString stringWithFormat:@"https://%@/jsonrpc",
                         [plist objectForKey:kYTDDomainKey]];
  NSURL *url = [NSURL URLWithString:ytdDomain];

  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  [request setValue:kUserAgent forHTTPHeaderField:@"User-Agent"];
  [request setValue:kContentType forHTTPHeaderField:@"Content-Type"];
  [request setHTTPMethod:@"POST"];
  [request setHTTPBody:postData];

  return request;
}

+ (NSData *)postDataFromUploadModel:(UploadModel *)model
                          authToken:(NSString *)authToken
                           userName:(NSString *)userName {
  NSMutableDictionary *params =
      [NSMutableDictionary dictionaryWithObjectsAndKeys:
      [model videoID], kVideoIDKey,
      userName, kYouTubeNameKey,
      authToken , kAuthTokenKey,
      [model title], kTitleKey,
      [model description], kDescriptionKey,
      [model dateTaken], kVideoDateKey,
      [model tags], kTagsKey,
      nil];

  if ([model latLong]) {
    [params setObject:[model latLong] forKey:kVideoLocationKey];
  }

  if ([model assignmentID]) {
    [params setObject:[model assignmentID] forKey:kAssignmentIDKey];
  }

  NSString *paramsJSON = [params JSONRepresentation];
  id paramsJSONObject = [paramsJSON JSONValue];
  NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                        kVideoSubmissionMethod, kMethodKey,
                        paramsJSONObject, kParamKey,
                        nil];
  NSString *postJSON = [dict JSONRepresentation];
  NSData *postData = [postJSON dataUsingEncoding:NSUTF8StringEncoding];

  return postData;
}

@end

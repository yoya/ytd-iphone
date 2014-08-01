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

#import "YouTubeUploadTicket.h"
#import "UploadModel.h"
#import "YoutubeService.h"
#import "GTMOAuth2Authentication.h"
#import "GDataServiceGoogleYouTube.h"
#import "GDataYouTubeConstants.h"
#import "GDataServiceBase.h"

#import "NSString+SBJSON.h"
#import "NSObject+SBJSON.h"

static NSString *const kDefaultVideoCategory = @"News";
static NSString *const kDefaultMIMEType = @"video/mp4";

NSString *const kDefaultVideoTag = @"mobile";

@implementation YouTubeUploadTicket

@synthesize model = model_;
@synthesize uploadLocationURL = uploadLocationURL_;


#pragma mark -
#pragma mark NSObject

- (id)initWithUploadModel:(UploadModel *)model
           youtubeService:(GDataServiceGoogleYouTube *)service {
  self = [super init];
  if (self) {
    model_ = [model retain];
    youtubeService_ = [service retain];
  }
  return self;
}

- (void)dealloc {
  [model_ release];
  [youtubeService_ release];
  [ticket_ release];
  [uploadLocationURL_ release];

  [super dealloc];
}


#pragma mark -
#pragma mark Setters and Getters

- (GDataServiceTicket *)uploadTicket {
  return ticket_;
}

- (void)setUploadTicket:(GDataServiceTicket *)ticket {
  [ticket_ autorelease];
  ticket_ = [ticket retain];
}


#pragma mark -
#pragma mark Public methods

- (void)startUpload:(VideoUploadedCompletionHandler)uploadHandler
    progressHandler:(UploadProgressCompletionHandler)progressHandler {
  NSURL *feedURL =
      [GDataServiceGoogleYouTube
          youTubeUploadURLForUserID:kGDataServiceDefaultUser];

  GDataMediaTitle *mediaTitle =
      [GDataMediaTitle textConstructWithString:[model_ title]];

  GDataMediaDescription *mediaDescription =
      [GDataMediaDescription textConstructWithString:[model_ description]];

  GDataMediaCategory *mediaCategory =
      [GDataMediaCategory mediaCategoryWithString:kDefaultVideoCategory];
  [mediaCategory setScheme:kGDataSchemeYouTubeCategory];

  NSString *tags = [[model_ tags] length] ? [model_ tags] : kDefaultVideoTag;
  GDataMediaKeywords *mediaKeywords =
      [GDataMediaKeywords keywordsWithString:tags];

  GDataYouTubeMediaGroup *mediaGroup = [GDataYouTubeMediaGroup mediaGroup];
  [mediaGroup setMediaTitle:mediaTitle];
  [mediaGroup setMediaDescription:mediaDescription];
  [mediaGroup addMediaCategory:mediaCategory];
  [mediaGroup setMediaKeywords:mediaKeywords];
  [mediaGroup setIsPrivate:NO];

  NSString *filePath = [[model_ mediaURL] path];
  NSString *slug = [filePath lastPathComponent];

  // load the file data
  NSFileHandle *fileHandle =
      [NSFileHandle fileHandleForReadingAtPath:filePath];

  NSString *mimeType =
      [GDataUtilities MIMETypeForFileAtPath:filePath
                            defaultMIMEType:kDefaultMIMEType];

  GDataEntryYouTubeUpload *entry =
      [GDataEntryYouTubeUpload uploadEntryWithMediaGroup:mediaGroup
                                              fileHandle:fileHandle
                                                MIMEType:mimeType
                                                    slug:slug];

  [youtubeService_ setServiceUploadProgressHandler:
      ^(GDataServiceTicketBase *ticket, unsigned long long numberOfBytesRead,
          unsigned long long dataLength) {
    double percent = (numberOfBytesRead * 99) / dataLength;
    progressHandler(percent);
  }];

  GDataServiceTicket *ticket =
      [youtubeService_ fetchEntryByInsertingEntry:entry
                                       forFeedURL:feedURL
                                completionHandler:^(GDataServiceTicket *ticket,
                                                    GDataEntryBase *entry,
                                                    NSError *error) {
    uploadHandler(self, (GDataEntryYouTubeUpload *)entry, error);
    [self setUploadTicket:nil];
  }];
  [self setUploadTicket:ticket];

  GTMHTTPUploadFetcher *uploadFetcher =
      (GTMHTTPUploadFetcher *)[[self uploadTicket] objectFetcher];
  [uploadFetcher setLocationChangeBlock:^(NSURL *url) {
    [self setUploadLocationURL:url];
  }];
}

- (void)restartUpload:(VideoUploadedCompletionHandler)uploadHandler {
  if (![self uploadLocationURL]) {
    return;
  }

  NSString *filePath = [[model_ mediaURL] path];

  // load the file data
  NSFileHandle *fileHandle =
      [NSFileHandle fileHandleForReadingAtPath:filePath];

  NSString *mimeType =
      [GDataUtilities MIMETypeForFileAtPath:filePath
                            defaultMIMEType:kDefaultMIMEType];

  GDataEntryYouTubeUpload *entry;
  entry = [GDataEntryYouTubeUpload uploadEntryWithMediaGroup:nil
                                                  fileHandle:fileHandle
                                                    MIMEType:mimeType
                                                        slug:nil];
  [entry setUploadLocationURL:[self uploadLocationURL]];

  GDataServiceTicket *ticket =
      [youtubeService_ fetchEntryByInsertingEntry:entry
                                       forFeedURL:nil
                                completionHandler:^(GDataServiceTicket *ticket,
                                                    GDataEntryBase *entry,
                                                    NSError *error) {
    uploadHandler(self, (GDataEntryYouTubeUpload *)entry, error);
    [self setUploadTicket:nil];
  }];
  [self setUploadTicket:ticket];

  // To allow restarting after stopping, we need to track
  // the upload location URL
  GTMHTTPUploadFetcher *uploadFetcher =
      (GTMHTTPUploadFetcher *)[[self uploadTicket] objectFetcher];
  [uploadFetcher setLocationChangeBlock:^(NSURL *url) {
    [self setUploadLocationURL:url];
  }];
}

- (void)pauseUpload {
  if ([self uploadTicket]) {
    if (![[self uploadTicket] isUploadPaused]) {
      [[self uploadTicket] pauseUpload];
    } else {
      [[self uploadTicket] resumeUpload];
    }
  }
}

- (void)stopUpload {
  if ([self uploadTicket]) {
    [[self uploadTicket] cancelTicket];
    [self setUploadTicket:nil];
  }
}

@end

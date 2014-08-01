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

#import "AssignmentListController.h"

#import <QuartzCore/QuartzCore.h>

#import "ConnectionRequestHandler.h"
#import "AssignmentListCell.h"
#import "Assignment.h"
#import "SBJSON.h"

static NSString *const kAssignTitleKey = @"title";
static NSString *const kAssignDescriptionKey = @"description";
static NSString *const kAssignCreatedKey = @"created";
static NSString *const kAssignUpdatedKey = @"updated";
static NSString *const kAssignResultKey =@"result";
static NSString *const kAssignStatusKey = @"status";
static NSString *const kAssignIDKey = @"id";
static NSString *const kAssignPlaylistIDKey = @"playlistId";
static NSString *const kDefaultMobileAssignment = @"default mobile assignment";
static NSString *const kUpdatedDateKey = @"updatedDate";

static NSString *const kFetchDateFormat = @"EEE',' dd MMM yyyy HH':'mm':'ssZ";
static NSString *const kCompareDateFormat = @"EEE',' MMM dd',' yyyy";

@interface AssignmentListController ()

- (void)initSectionsFromList:(NSArray *)list;
- (void)connectionResponse:(NSString *)response withError:(NSError *)error;
- (NSDate *)parseStringAsDate:(NSString *)string;
- (NSDate *)dateForComparison:(NSString *)string;
- (NSString *)formatDate:(NSDate *)date;
- (void)cellView:(AssignmentListCell *)cell collapsed:(BOOL)collapse;
- (void)clearRowSelection;
- (UIView *)showSpinnerWithMessage:(NSString *)message;
- (void)removeSpinner:(UIView *)spinner;

// Action-method for the detail button - present on each Assignment
// cell- that presents an expanded view of the cell to allow user
// to select a video from Gallery/Camera.
- (void)displayExpandedVideoSelectionView:(UIView *)sender;

@property(nonatomic, retain, readonly) NSDictionary *sections;
@property(nonatomic, retain, readonly) NSArray *sortedKeys;

@end

@implementation AssignmentListController

@synthesize sections = sections_;
@synthesize sortedKeys = sortedKeys_;


#pragma mark -
#pragma mark NSObject

- (id)init {
  self = [super init];
  if (self) {
    [ConnectionRequestHandler fetchAssignments:
        ^(NSString *response, NSError *error) {
          [self connectionResponse:response withError:error];
    }];
    sections_ = [[NSMutableDictionary alloc] init];

    firstViewAppear_ = NO;

    fetchDateFormatter_ = [[NSDateFormatter alloc] init];
    [fetchDateFormatter_ setDateFormat:kFetchDateFormat];
    compareDateFormatter_ = [[NSDateFormatter alloc] init];
    [compareDateFormatter_ setDateFormat:kCompareDateFormat];
  }
  return self;
}

- (void)dealloc {
  [sections_ release];
  [sortedKeys_ release];
  [selectedIndexPath_ release];
  [spinner_ release];
  [loadingSpinner_ release];
  [fetchDateFormatter_ release];
  [compareDateFormatter_ release];

  [super dealloc];
}


#pragma mark -
#pragma mark Actions

- (void)refresh {
  [self clearRowSelection];
  [[self tableView] reloadData];

  [ConnectionRequestHandler fetchAssignments:
      ^(NSString *response, NSError *error) {
        [self connectionResponse:response withError:error];
  }];

  [self performSelector:@selector(stopLoading) withObject:nil afterDelay:0.0];
}

- (void)displayExpandedVideoSelectionView:(UIView *)sender {
  AssignmentListCell *cellView;
  if ([[sender superview] isKindOfClass:[AssignmentListCell class]]) {
    cellView = (AssignmentListCell *)[sender superview];
  }

  UITableView *tableView = [self tableView];
  NSIndexPath *prevSelectedIndexPath = [selectedIndexPath_ autorelease];
  NSIndexPath *cellIndexPath = [tableView indexPathForCell:cellView];
  if ([selectedIndexPath_ isEqual:cellIndexPath]) {
    selectedIndexPath_ = nil;
  } else {
    [self cellView:cellView collapsed:NO];
    selectedIndexPath_ = [cellIndexPath retain];
  }
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationBeginsFromCurrentState:YES];
  [UIView setAnimationDuration:0.3];
  [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];

  [tableView beginUpdates];
  NSArray *changedIndexPaths = nil;
  if (selectedIndexPath_ && prevSelectedIndexPath
      && selectedIndexPath_ != prevSelectedIndexPath) {
    changedIndexPaths = [NSArray arrayWithObjects:selectedIndexPath_,
        prevSelectedIndexPath, nil];
  } else {
    changedIndexPaths = [NSArray arrayWithObject:cellIndexPath];
  }
  [tableView reloadRowsAtIndexPaths:changedIndexPaths
                   withRowAnimation:UITableViewRowAnimationFade];
  [tableView endUpdates];
  [UIView commitAnimations];
}


#pragma mark -
#pragma mark UITableViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  [[self tableView] setAllowsSelection:NO];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  if (!firstViewAppear_) {
    firstViewAppear_ = YES;
    spinner_ = [[self showSpinnerWithMessage:
        NSLocalizedString(@"Loading…", @"")] retain];
  }
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];

  [self clearRowSelection];
}


#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
  NSString *sectionKey = [sortedKeys_ objectAtIndex:section];
  NSArray *items = [sections_ objectForKey:sectionKey];
  return [items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  NSString *cellId = @"AssignmentListCell";
  AssignmentListCell *cell = (AssignmentListCell *)
      [tableView dequeueReusableCellWithIdentifier:cellId];
  if (!cell) {
    cell =
        [[[AssignmentListCell alloc] initWithStyle:UITableViewCellStyleDefault
                                   reuseIdentifier:cellId] autorelease];
  }

  if (![selectedIndexPath_ isEqual:indexPath]) {
    [self cellView:cell collapsed:YES];
  } else {
    [self cellView:cell collapsed:NO];
  }

  NSMutableArray *section = [sections_ objectForKey:
      [sortedKeys_ objectAtIndex:[indexPath section]]];
  Assignment *assignment = [section objectAtIndex:[indexPath row]];

  [cell setAssignment:assignment];
  [cell setTag:[indexPath row]];

  return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return [sections_ count];
}

- (NSString *)tableView:(UITableView *)tableView
    titleForHeaderInSection:(NSInteger)section {
  return [sortedKeys_ objectAtIndex:section];
}


#pragma mark -
#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  if ([selectedIndexPath_ isEqual:indexPath]) {
    return [AssignmentListCell rowHeight] +
        [AssignmentListCell footerViewHeight];
  } else {
    return [AssignmentListCell rowHeight];
  }
}


#pragma mark -
#pragma mark Private

- (void)connectionResponse:(NSString *)response
                 withError:(NSError *)error {
  [self removeSpinner:spinner_];
  [spinner_ release];
  spinner_ = nil;

  if (error) {
    UIAlertView *alertView = [[[UIAlertView alloc]
        initWithTitle:NSLocalizedString(@"Network Error", @"")
        message:NSLocalizedString(@"Results could not be fetched.", @"")
        delegate:nil
        cancelButtonTitle:NSLocalizedString(@"OK", @"")
        otherButtonTitles:nil] autorelease];
    [alertView setDelegate:self];
    [alertView show];
    return;
  }
  SBJSON *parser = [[[SBJSON alloc] init] autorelease];
  NSDictionary *jsonObject = [parser objectWithString:response error:nil];

  [self initSectionsFromList:[jsonObject objectForKey:kAssignResultKey]];
  [[self tableView] reloadData];
}

- (void)cellView:(AssignmentListCell *)cell collapsed:(BOOL)collapse {
  [cell collapseView:collapse];
}

- (NSDate *)parseStringAsDate:(NSString *)string {
  return [fetchDateFormatter_ dateFromString:string];
}

- (NSDate *)dateForComparison:(NSString *)string {
  return [compareDateFormatter_ dateFromString:string];
}

- (NSString *)formatDate:(NSDate *)date {
  return [compareDateFormatter_ stringFromDate:date];
}

- (void)initSectionsFromList:(NSArray *)list {
  [sections_ removeAllObjects];
  for (NSDictionary *item in list) {
    if ([[item objectForKey:kAssignDescriptionKey]
        isEqualToString:kDefaultMobileAssignment]) {
      continue;
    }
    NSDate *updatedDate =
        [self parseStringAsDate:[item objectForKey:kAssignUpdatedKey]];
    NSString *key = [self formatDate:updatedDate];
    if (![sections_ objectForKey:key]) {
      [sections_ setObject:[NSMutableArray array] forKey:key];
    }

    Assignment *assignment = [[[Assignment alloc]
        initWithTitle:[item objectForKey:kAssignTitleKey]
        description:[item objectForKey:kAssignDescriptionKey]
        status:[item objectForKey:kAssignStatusKey]
        assignmentID:[[item objectForKey:kAssignIDKey] stringValue]
        playlistID:[item objectForKey:kAssignPlaylistIDKey]
        updatedDate:[self parseStringAsDate:
                     [item objectForKey:kAssignUpdatedKey]]
        createdDate:[self parseStringAsDate:
                     [item objectForKey:kAssignCreatedKey]]
        heading:YES] autorelease];
    [[sections_ objectForKey:key] addObject:assignment];
  }

  // Sort each section array
  NSArray *sortDescriptor = [NSArray arrayWithObject:
      [NSSortDescriptor sortDescriptorWithKey:kUpdatedDateKey ascending:NO]];
  for (NSDate *key in sections_) {
    [[sections_ objectForKey:key] sortUsingDescriptors:sortDescriptor];
  }


  // "Date"Sort categories(Keys) within sections
  NSComparator dateComparator = (NSComparator)^(id object1, id object2) {
    NSDate *dateObject1 = [self dateForComparison:object1];
    NSDate *dateObject2 = [self dateForComparison:object2];
    return [dateObject2 compare:dateObject1];
  };
  sortedKeys_ = [[[sections_ allKeys] sortedArrayUsingComparator:
                  dateComparator] retain];
}

- (UIView *)showSpinnerWithMessage:(NSString *)message {
  if (!loadingSpinner_) {
    loadingSpinner_ = [[UIActivityIndicatorView alloc]
        initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  }
  [loadingSpinner_ startAnimating];
  [loadingSpinner_ sizeToFit];

  UILabel *messageLabel = [[[UILabel alloc] init] autorelease];
  [messageLabel setText:message];
  [messageLabel setTextAlignment:UITextAlignmentLeft];
  [messageLabel setTextColor:[UIColor grayColor]];
  [messageLabel setBackgroundColor:[UIColor clearColor]];
  [messageLabel sizeToFit];

  UIView *transparentView = [[[UIView alloc] init] autorelease];
  [transparentView addSubview:loadingSpinner_];
  [transparentView addSubview:messageLabel];
  [transparentView setBackgroundColor:
      [UIColor colorWithRed:0.90 green:0.90 blue:0.90 alpha:0.5]];
  [transparentView layer].cornerRadius = 5.0;

  CGFloat transparentViewWidth =
      CGRectGetWidth([loadingSpinner_ frame]) +
          CGRectGetWidth([messageLabel frame]) + 30;
  CGFloat transparentViewHeight =
      MAX(CGRectGetHeight([loadingSpinner_ frame]),
          CGRectGetHeight([messageLabel frame])) + 10;

  UITableView *tableView = [self tableView];
  CGRect transparentViewFrame =
      CGRectMake([tableView center].x - transparentViewWidth / 2,
                 [tableView center].y + [tableView contentOffset].y -
                     transparentViewHeight / 2,
                 transparentViewWidth,
                 transparentViewHeight);
  [transparentView setFrame:transparentViewFrame];

  CGRect frame = [messageLabel frame];
  frame.origin.x += CGRectGetWidth([loadingSpinner_ frame]) + 20;
  frame.origin.y = (CGRectGetHeight([transparentView frame]) -
      CGRectGetHeight(frame)) / 2;
  [messageLabel setFrame:frame];

  frame = [loadingSpinner_ frame];
  frame.origin.x = 10;
  frame.origin.y = (CGRectGetHeight([transparentView frame]) -
      CGRectGetHeight(frame)) / 2;
  [loadingSpinner_ setFrame:frame];

  [[self view] addSubview:transparentView];
  [[self view] bringSubviewToFront:transparentView];

  return transparentView;
}

- (void)removeSpinner:(UIView *)spinner {
  [loadingSpinner_ stopAnimating];
  [spinner removeFromSuperview];
}

- (void)clearRowSelection {
  UITableView *tableView = [self tableView];
  [tableView beginUpdates];
  if (selectedIndexPath_) {
    AssignmentListCell *cell = (AssignmentListCell *)
        [tableView cellForRowAtIndexPath:selectedIndexPath_];
    [self cellView:cell collapsed:YES];
    [selectedIndexPath_ release];
    selectedIndexPath_ = nil;
  }
  [tableView endUpdates];
}

@end

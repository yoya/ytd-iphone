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

#import "AssignmentListCell.h"
#import "Assignment.h"
#import "GTMUIFont+LineHeight.h"
#import "YouTubeDirectUIViewAdditions.h"

static NSString *const kCellFooterViewBackground = @"assignment_options_bg.png";
static NSString *const kCameraButtonImage = @"camera_blue.png";
static NSString *const kCameraButtonPressedImage = @"camera_press.png";
static NSString *const kGaleryButtonImage = @"gallery_blue.png";
static NSString *const kGaleryButtonPressedImage = @"gallery_press.png";
static NSString *const kDetailButtonDownImage = @"assignment_options.png";
static NSString *const kDetailButtonDownPressedImage =
    @"assignment_options_press.png";
static NSString *const kDetailButtonUpImage = @"assignment_options_up.png";
static NSString *const kDetailButtonUpPressedImage =
    @"assignment_options_up_press.png";

static const CGFloat kHPadding = 10.0;
static const CGFloat kTitleLabelWidth = 175.0;
static const CGFloat kTimeLabelWidth = 75.0;
static const CGFloat kMarginLeftTitleLabel= 5.0;
static const CGFloat kDetailButtonImageWidth = 26;
static const CGFloat kDetailButtonImageHeight = 26;
static const CGFloat kDetailButtonWidth = 44;
static const CGFloat kDetailButtonHeight = 50;
static const CGFloat kIconWidth = 35;
static const CGFloat kIconHeight = 30;
static const CGFloat kRowHeight = 50;
static const CGFloat kFooterViewHeight = 46.0;

static const int kTextFontSize = 14;
static const int kBoldTextFontSize = 16;
static const int kFooterImageTag = 100;

@interface AssignmentListCell ()

- (void)createCellView;
- (NSString *)timeFromDate:(NSDate *)date;
- (UILabel *)titleLabel;
- (UILabel *)timeLabel;
- (UIButton *)addVideoCameraButton;
- (UIButton *)addVideoGalleryButton;
- (UIButton *)detailButton;

@end

@implementation AssignmentListCell

@synthesize assignment = assignment_;

#pragma mark -
#pragma mark NSObject

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    cellFooterView_ = [[UIView alloc] initWithFrame:CGRectZero];
    [self addSubview:cellFooterView_];

    UIImageView *imageView = [[[UIImageView alloc] initWithImage:
        [UIImage imageNamed:kCellFooterViewBackground]] autorelease];

    [imageView setTag:kFooterImageTag];
    [cellFooterView_ addSubview:imageView];

    [self createCellView];
  }
  return self;
}

- (void)dealloc {
  [assignment_ release];
  [titleLabel_ release];
  [timeLabel_ release];
  [cellFooterView_ release];
  [addVideoCameraButton_ release];
  [addVideoGalleryButton_ release];
  [detailButton_ release];

  [super dealloc];
}


#pragma mark -
#pragma mark UIView

- (void)layoutSubviews {
  [super layoutSubviews];

  CGRect bounds = [self bounds];
  CGFloat width = CGRectGetWidth(bounds);

  CGFloat cellHeight = [AssignmentListCell rowHeight];

  CGFloat titleTextHeight = [[[self titleLabel] font] gtm_lineHeight];
  CGFloat left = kHPadding;
  [[self titleLabel] setFrame:CGRectMake(
      left + kTimeLabelWidth + kMarginLeftTitleLabel,
      (cellHeight - titleTextHeight) / 2.0,
      kTitleLabelWidth,
      titleTextHeight)];

  CGFloat timeTextHeight = [[[self timeLabel] font] gtm_lineHeight];
  [[self timeLabel] setFrame:CGRectMake(
      left,
      (cellHeight - timeTextHeight) / 2.0,
      kTimeLabelWidth,
      timeTextHeight)];

  [detailButton_ sizeToFit];
  CGRect detailButtonFrame = [detailButton_ frame];
  detailButtonFrame.size.width = kDetailButtonWidth;
  detailButtonFrame.size.height = kDetailButtonHeight;
  [detailButton_ setFrame:detailButtonFrame];
  [detailButton_ setAssignmentLeft:
      (width - CGRectGetWidth([detailButton_ frame]) - kHPadding)];
  [detailButton_ setAssignmentTop:
      (cellHeight - CGRectGetHeight([detailButton_ frame])) / 2.0];

  CGFloat widthInset =
      (CGRectGetWidth(detailButtonFrame) - kDetailButtonImageWidth) / 2.0;
  CGFloat heightInset =
      (CGRectGetHeight(detailButtonFrame) - kDetailButtonImageHeight) / 2.0;
  [detailButton_ setImageEdgeInsets:
      UIEdgeInsetsMake(heightInset, widthInset, heightInset, widthInset)];
  [self bringSubviewToFront:detailButton_];

  [cellFooterView_ setFrame:
      CGRectMake(0, cellHeight, width, kFooterViewHeight)];
  [[cellFooterView_ viewWithTag:kFooterImageTag]
      setFrame:CGRectMake(0, 0, width, kFooterViewHeight)];

  [addVideoCameraButton_ sizeToFit];
  CGRect videoButtonFrame = [addVideoCameraButton_ frame];
  videoButtonFrame.size.width = kIconWidth;
  videoButtonFrame.size.height = kIconHeight;
  [addVideoCameraButton_ setFrame:videoButtonFrame];
  [addVideoCameraButton_ setAssignmentLeft:kHPadding];
  [addVideoCameraButton_ setAssignmentTop:
      (kFooterViewHeight - kIconHeight) / 2];

  [addVideoGalleryButton_ sizeToFit];
  [addVideoGalleryButton_ setFrame:videoButtonFrame];
  [addVideoGalleryButton_ setAssignmentLeft:(width - kHPadding * 4.5)];
  [addVideoGalleryButton_ setAssignmentTop:
      (kFooterViewHeight - kIconHeight) / 2];
}


#pragma mark -
#pragma mark Public

+ (CGFloat)rowHeight {
  return kRowHeight;
}

+ (CGFloat)footerViewHeight {
  return kFooterViewHeight;
}

- (void)setAssignment:(Assignment *)assignment {
  if (assignment != assignment_) {
    [assignment_ autorelease];
    assignment_ = [assignment retain];
    NSString *title = [assignment_ description];
    if ([title length] == 0) {
      title = NSLocalizedString(@"(no title)",@"");
    }
    [[self titleLabel] setText:title];

    NSString *updatedTime = [self timeFromDate:[assignment_ updatedDate]];
    [[self timeLabel] setText: [NSString stringWithFormat:@"(%@)",updatedTime]];

    NSInteger assignmentID = [[assignment_ assignmentID] integerValue];
    [[self addVideoCameraButton] setTag:assignmentID];
    [[self addVideoGalleryButton] setTag:assignmentID];
  }
}

- (void)collapseView:(BOOL)collapse {
  [cellFooterView_ setHidden:collapse];
  NSString *defaultImageName =
      collapse ? kDetailButtonDownImage : kDetailButtonUpImage;
  NSString *pressedImageName =
      collapse ? kDetailButtonDownPressedImage : kDetailButtonUpPressedImage;
  UIButton *detailButton = [self detailButton];
  [detailButton setImage:[UIImage imageNamed:defaultImageName]
                forState:UIControlStateNormal];
  [detailButton setImage:[UIImage imageNamed:pressedImageName]
                forState:UIControlStateHighlighted];
}

#pragma mark -
#pragma mark Private

- (void)createCellView {
  [cellFooterView_ addSubview:[self addVideoCameraButton]];
  [cellFooterView_ addSubview:[self addVideoGalleryButton]];
  [cellFooterView_ setHidden:YES];

  [self addSubview:[self titleLabel]];
  [self addSubview:[self timeLabel]];
  [self addSubview:[self detailButton]];
}

- (UILabel *)titleLabel {
  if (!titleLabel_) {
    titleLabel_ = [[UILabel alloc] init];
    [titleLabel_ setFont:[UIFont boldSystemFontOfSize:kBoldTextFontSize]];
    [titleLabel_ setTextColor:[UIColor blackColor]];
    [titleLabel_ setHighlightedTextColor:[UIColor whiteColor]];
    [titleLabel_ setBackgroundColor:[UIColor clearColor]];
    [titleLabel_ setContentMode:UIViewContentModeCenter];
    [titleLabel_ setLineBreakMode:UILineBreakModeTailTruncation];
  }
  return titleLabel_;
}

- (UILabel *)timeLabel {
  if (!timeLabel_) {
    timeLabel_ = [[UILabel alloc] init];
    [timeLabel_ setFont:[UIFont systemFontOfSize:kTextFontSize]];
    [timeLabel_ setTextColor:[UIColor blackColor]];
    [timeLabel_ setHighlightedTextColor:[UIColor whiteColor]];
    [timeLabel_ setBackgroundColor:[UIColor clearColor]];
    [timeLabel_ setContentMode:UIViewContentModeLeft];
  }
  return timeLabel_;
}

- (UIButton *)addVideoCameraButton {
  if (!addVideoCameraButton_) {
    addVideoCameraButton_ =
        [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    [addVideoCameraButton_ setImage:[UIImage imageNamed:kCameraButtonImage]
                           forState:UIControlStateNormal];
    [addVideoCameraButton_
        setImage:[UIImage imageNamed:kCameraButtonPressedImage]
        forState:UIControlStateHighlighted];
    [addVideoCameraButton_ addTarget:nil
                              action:@selector(captureVideo:)
                    forControlEvents:UIControlEventTouchUpInside];
  }
  return addVideoCameraButton_;
}

- (UIButton *)addVideoGalleryButton {
  if (!addVideoGalleryButton_) {
    addVideoGalleryButton_ =
        [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    [addVideoGalleryButton_ setImage:[UIImage imageNamed:kGaleryButtonImage]
                            forState:UIControlStateNormal];
    [addVideoGalleryButton_
        setImage:[UIImage imageNamed:kGaleryButtonPressedImage]
        forState:UIControlStateHighlighted];
    [addVideoGalleryButton_ addTarget:nil
                               action:@selector(selectVideo:)
                     forControlEvents:UIControlEventTouchUpInside];
  }
  return addVideoGalleryButton_;
}

- (UIButton *)detailButton {
  if (!detailButton_) {
    detailButton_ = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    [detailButton_ setImage:[UIImage imageNamed:kDetailButtonDownImage]
                   forState:UIControlStateNormal];
    [detailButton_ setImage:[UIImage imageNamed:kDetailButtonDownPressedImage]
                   forState:UIControlStateHighlighted];
    [detailButton_ addTarget:nil
                      action:@selector(displayExpandedVideoSelectionView:)
            forControlEvents:UIControlEventTouchUpInside];
  }
  return detailButton_;
}

- (NSString *)timeFromDate:(NSDate *)date {
  NSDateFormatter *fmt = [[[NSDateFormatter alloc] init] autorelease];
  [fmt setTimeStyle:NSDateFormatterShortStyle];
  [fmt setDateStyle:NSDateFormatterNoStyle];
  return [fmt stringFromDate:date];
}

@end

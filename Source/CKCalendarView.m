//
// Copyright (c) 2012 Jason Kozemczak
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the "Software"), to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
// and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
// THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//


#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#import "CKCalendarView.h"
#import "CKCalendarViewPopoverController.h"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]


@implementation GradientView

- (id)init {
    return [self initWithFrame:CGRectZero];
}

+ (Class)layerClass {
    return [CAGradientLayer class];
}

- (CAGradientLayer *)gradientLayer {
    return (CAGradientLayer *)self.layer;
}

- (void)setColors:(NSArray *)colors {
    NSMutableArray *cgColors = [NSMutableArray array];
    for (UIColor *color in colors) {
        [cgColors addObject:(__bridge id)color.CGColor];
    }
    self.gradientLayer.colors = cgColors;
}

@end


@implementation DateButton

@synthesize date = _date;
@synthesize calendar = _calendar;
@synthesize gradientLayer = _gradientLayer;

- (void)setDate:(NSDate *)date {
    _date = date;
    NSDateComponents *comps;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        comps = [self.calendar components:NSCalendarUnitDay|NSCalendarUnitMonth fromDate:date];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        comps = [self.calendar components:NSDayCalendarUnit|NSMonthCalendarUnit fromDate:date];
#pragma clang diagnostic pop
    }

    [self setTitle:[NSString stringWithFormat:@"%ld", (long)comps.day] forState:UIControlStateNormal];
}

@end


@interface CKCalendarView ()


@end

@implementation CKCalendarView

@synthesize highlight = _highlight;
@synthesize titleLabel = _titleLabel;
@synthesize titleButton = _titleButton;
@synthesize monthYearPopoverController = _monthYearPopoverController;
@synthesize prevButton = _prevButton;
@synthesize nextButton = _nextButton;
@synthesize calendarContainer = _calendarContainer;
@synthesize daysHeader = _daysHeader;
@synthesize dayOfWeekLabels = _dayOfWeekLabels;
@synthesize dateButtons = _dateButtons;

@synthesize monthShowing = _monthShowing;
@synthesize calendar = _calendar;
@synthesize dateFormatter = _dateFormatter;

@synthesize selectedDate = _selectedDate;
@synthesize delegate = _delegate;

@synthesize dateTextColor = _dateTextColor;
@synthesize selectedDateTextColor = _selectedDateTextColor;
@synthesize selectedDateBackgroundColor = _selectedDateBackgroundColor;
@synthesize currentDateTextColor = _currentDateTextColor;
@synthesize currentDateBackgroundColor = _currentDateBackgroundColor;
@synthesize nonCurrentMonthDateTextColor = _nonCurrentMonthDateTextColor;
@synthesize disabledDateTextColor = _disabledDateTextColor;
@synthesize disabledDateBackgroundColor = _disabledDateBackgroundColor;
@synthesize cellWidth = _cellWidth;

@synthesize calendarStartDay;
@synthesize minimumDate = _minimumDate;
@synthesize maximumDate = _maximumDate;
@synthesize shouldFillCalendar = _shouldFillCalendar;


- (id)init {
    return [self initWithStartDay:startSunday];
}

- (id)initWithStartDay:(startDay)firstDay {
    return [self initWithStartDay:firstDay frame:CGRectMake(0, 0, 320, 320)];
}

- (id)initWithStartDay:(startDay)firstDay frame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.calendarStartDay = firstDay;

        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            self.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            self.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
#pragma clang diagnostic pop
        }

        [self.calendar setLocale:[NSLocale currentLocale]];
        [self.calendar setFirstWeekday:self.calendarStartDay];
        self.cellWidth = DEFAULT_CELL_WIDTH;

        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        self.dateFormatter.dateFormat = @"MMMM yyyy";

        self.shouldFillCalendar = NO;

        self.layer.cornerRadius = 6.0f;

        UIView *highlight = [[UIView alloc] initWithFrame:CGRectZero];
        highlight.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.2];
        highlight.layer.cornerRadius = 6.0f;
        [self addSubview:highlight];
        self.highlight = highlight;

        // SET UP THE HEADER
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
        [self addSubview:titleLabel];
        self.titleLabel = titleLabel;
        
        UIButton *titleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [titleButton setFrame:[self.titleLabel frame]];
        [titleButton addTarget:self action:@selector(titleButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [titleButton setBackgroundColor:[UIColor clearColor]];
        [self addSubview:titleButton];
        self.titleButton = titleButton;
        
        UIButton *prevButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [prevButton setImage:[UIImage imageNamed:kCalendarArrowButtonLeft] forState:UIControlStateNormal];
        prevButton.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
        [prevButton addTarget:self action:@selector(moveCalendarToPreviousMonth) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:prevButton];
        self.prevButton = prevButton;

        UIButton *nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [nextButton setImage:[UIImage imageNamed:kCalendarArrowButtonRight] forState:UIControlStateNormal];
        nextButton.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
        [nextButton addTarget:self action:@selector(moveCalendarToNextMonth) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:nextButton];
        self.nextButton = nextButton;

        // THE CALENDAR ITSELF
        UIView *calendarContainer = [[UIView alloc] initWithFrame:CGRectZero];
        calendarContainer.layer.borderWidth = 1.0f;
        calendarContainer.layer.borderColor = [UIColor blackColor].CGColor;
        calendarContainer.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
        calendarContainer.layer.cornerRadius = 4.0f;
        calendarContainer.clipsToBounds = YES;
        [self addSubview:calendarContainer];
        self.calendarContainer = calendarContainer;

        GradientView *daysHeader = [[GradientView alloc] initWithFrame:CGRectZero];
        daysHeader.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
        [self.calendarContainer addSubview:daysHeader];
        self.daysHeader = daysHeader;

        NSMutableArray *labels = [NSMutableArray array];
        for (NSString *day in [self getDaysOfTheWeek]) {
            UILabel *dayOfWeekLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            dayOfWeekLabel.text = [day uppercaseString];
            dayOfWeekLabel.textAlignment = NSTextAlignmentCenter;
            dayOfWeekLabel.backgroundColor = [UIColor clearColor];
            dayOfWeekLabel.shadowColor = [UIColor whiteColor];
            dayOfWeekLabel.shadowOffset = CGSizeMake(0, 1);
            [labels addObject:dayOfWeekLabel];
            [self.calendarContainer addSubview:dayOfWeekLabel];
        }
        self.dayOfWeekLabels = labels;

        // at most we'll need 42 buttons, so let's just bite the bullet and make them now...
        NSMutableArray *dateButtons = [NSMutableArray array];
        for (NSInteger i = 1; i <= 42; i++) {
            DateButton *dateButton = [DateButton buttonWithType:UIButtonTypeCustom];
            dateButton.calendar = self.calendar;
            [dateButton addTarget:self action:@selector(dateButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            [dateButtons addObject:dateButton];
        }
        self.dateButtons = dateButtons;

        // initialize the thing
        self.monthShowing = [NSDate date];
        [self setDefaultStyle];
    }

//    [self layoutSubviews]; // TODO: this is a hack to get the first month to show properly
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    return [super initWithFrame:frame];
//    return [self initWithStartDay:startSunday frame:frame];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat containerWidth = self.bounds.size.width - (CALENDAR_MARGIN * 2);
    self.cellWidth = (containerWidth / 7.0) - CELL_BORDER_WIDTH;

    CGFloat containerHeight = ([self numberOfWeeksInMonthContainingDate:self.monthShowing] * (self.cellWidth + CELL_BORDER_WIDTH) + DAYS_HEADER_HEIGHT);


    CGRect newFrame = self.frame;
    newFrame.size.height = containerHeight + CALENDAR_MARGIN + TOP_HEIGHT;
    if (self.frame.size.height != newFrame.size.height) {
        [self.delegate calendar:self containerHeightHasChanged:newFrame];
    }
    self.frame = newFrame;

    self.highlight.frame = CGRectMake(1, 1, self.bounds.size.width - 2, 1);

    self.titleLabel.frame = CGRectMake(0, 0, self.bounds.size.width, TOP_HEIGHT);
    self.titleButton.frame = self.titleLabel.frame;
    
    self.prevButton.frame = CGRectMake(BUTTON_MARGIN, BUTTON_MARGIN, 48, 38);
    self.nextButton.frame = CGRectMake(self.bounds.size.width - 48 - BUTTON_MARGIN, BUTTON_MARGIN, 48, 38);

    self.calendarContainer.frame = CGRectIntegral(CGRectMake(CALENDAR_MARGIN, CGRectGetMaxY(self.titleLabel.frame), containerWidth, containerHeight));
    self.daysHeader.frame = CGRectIntegral(CGRectMake(0, 0, self.calendarContainer.frame.size.width, DAYS_HEADER_HEIGHT));

    CGRect lastDayFrame = CGRectZero;
    for (UILabel *dayLabel in self.dayOfWeekLabels) {
        dayLabel.frame = CGRectIntegral(CGRectMake(CGRectGetMaxX(lastDayFrame) + CELL_BORDER_WIDTH, lastDayFrame.origin.y, self.cellWidth, self.daysHeader.frame.size.height));
        lastDayFrame = dayLabel.frame;
    }

    for (DateButton *dateButton in self.dateButtons) {
        [dateButton removeFromSuperview];
    }

    NSDate *date = [self firstDayOfMonthContainingDate:self.monthShowing];
    if (self.shouldFillCalendar) {
        while ([self placeInWeekForDate:date] != 0) {
            date = [self previousDay:date];
        }
    }

    NSDate *endDate = [self firstDayOfNextMonthContainingDate:self.monthShowing];
    if (self.shouldFillCalendar) {
        while ([self placeInWeekForDate:endDate] != 0) {
            endDate = [self nextDay:endDate];
        }
    }

    NSUInteger dateButtonPosition = 0;
    while ([date laterDate:endDate] != date) {
        DateButton *dateButton = [self.dateButtons objectAtIndex:dateButtonPosition];

        dateButton.date = date;
        if ([self date:dateButton.date isSameDayAsDate:self.selectedDate]) {
            dateButton.backgroundColor = self.selectedDateBackgroundColor;
            [dateButton setTitleColor:self.selectedDateTextColor forState:UIControlStateNormal];
        } else if ([self dateIsToday:dateButton.date]) {
            [dateButton setTitleColor:self.currentDateTextColor forState:UIControlStateNormal];
            dateButton.backgroundColor = self.currentDateBackgroundColor;
        } else if ([date compare:self.minimumDate] == NSOrderedAscending ||
                [date compare:self.maximumDate] == NSOrderedDescending) {
            [dateButton setTitleColor:self.disabledDateTextColor forState:UIControlStateNormal];
            dateButton.backgroundColor = self.disabledDateBackgroundColor;
        } else if (self.shouldFillCalendar && [self compareByMonth:date toDate:self.monthShowing] != NSOrderedSame) {
            [dateButton setTitleColor:self.nonCurrentMonthDateTextColor forState:UIControlStateNormal];
            dateButton.backgroundColor = [self dateBackgroundColor];
        } else {
            [dateButton setTitleColor:self.dateTextColor forState:UIControlStateNormal];
            dateButton.backgroundColor = [self dateBackgroundColor];
        }

        dateButton.frame = [self calculateDayCellFrame:date];

        [self.calendarContainer addSubview:dateButton];

        date = [self nextDay:date];
        dateButtonPosition++;
    }
}

- (void)setMonthShowing:(NSDate *)aMonthShowing {
    _monthShowing = [self firstDayOfMonthContainingDate:aMonthShowing];

    self.titleLabel.text = [self.dateFormatter stringFromDate:_monthShowing];
    [self setNeedsLayout];
}

- (void)setSelectedDate:(NSDate *)selectedDate {
    _selectedDate = selectedDate;
    [self setNeedsLayout];
    self.monthShowing = selectedDate;
}

- (void)setShouldFillCalendar:(BOOL)shouldFillCalendar {
    _shouldFillCalendar = shouldFillCalendar;
    [self setNeedsLayout];
}

- (void)setDefaultStyle;
{
    self.backgroundColor = UIColorFromRGB(0x393B40);

    [self setTitleColor:[UIColor whiteColor]];
    [self setTitleFont:[UIFont boldSystemFontOfSize:17.0]];

    [self setDayOfWeekFont:[UIFont boldSystemFontOfSize:12.0]];
    [self setDayOfWeekTextColor:UIColorFromRGB(0x999999)];
    [self setDayOfWeekBottomColor:UIColorFromRGB(0xCCCFD5) topColor:[UIColor whiteColor]];

    [self setDateFont:[UIFont boldSystemFontOfSize:16.0f]];
    [self setDateTextColor:UIColorFromRGB(0x393B40)];
    [self setDateBackgroundColor:UIColorFromRGB(0xF2F2F2)];
    [self setDateBorderColor:UIColorFromRGB(0xDAE1E6)];


    [self setSelectedDateTextColor:UIColorFromRGB(0xF2F2F2)];
    [self setSelectedDateBackgroundColor:UIColorFromRGB(0x88B6DB)];

    [self setCurrentDateTextColor:UIColorFromRGB(0xF2F2F2)];
    [self setCurrentDateBackgroundColor:[UIColor lightGrayColor]];

    self.nonCurrentMonthDateTextColor = [UIColor lightGrayColor];

    self.disabledDateTextColor = [UIColor lightGrayColor];
    self.disabledDateBackgroundColor = self.dateBackgroundColor;
}

- (CGRect)calculateDayCellFrame:(NSDate *)date;
{
    NSComparisonResult monthComparison = [self compareByMonth:date toDate:self.monthShowing];
    NSInteger row;
    if (monthComparison == NSOrderedAscending) {
        row = 0;
    } else if (monthComparison == NSOrderedDescending) {
        row = [self numberOfWeeksInMonthContainingDate:self.monthShowing] - 1;
    } else {
        row = [self weekNumberInMonthForDate:date];
    }
    NSInteger placeInWeek = [self placeInWeekForDate:date];

    return CGRectMake(placeInWeek * (self.cellWidth + CELL_BORDER_WIDTH), (row * (self.cellWidth + CELL_BORDER_WIDTH)) + CGRectGetMaxY(self.daysHeader.frame) + CELL_BORDER_WIDTH, self.cellWidth, self.cellWidth);
}

- (void)moveCalendarToNextMonth;
{
    NSDateComponents* comps = [[NSDateComponents alloc] init];
    [comps setMonth:1];
    self.monthShowing = [self.calendar dateByAddingComponents:comps toDate:self.monthShowing options:0];
}

- (void)moveCalendarToPreviousMonth;
{
    NSDateComponents* comps = [[NSDateComponents alloc] init];
    [comps setMonth:-1];
    self.monthShowing = [self.calendar dateByAddingComponents:comps toDate:self.monthShowing options:0];
}

- (void)dateButtonPressed:(id)sender;
{
    DateButton *dateButton = sender;
    NSDate *date = dateButton.date;
    if (self.minimumDate && [date compare:self.minimumDate] == NSOrderedAscending) {
        return;
    } else if (self.maximumDate && [date compare:self.maximumDate] == NSOrderedDescending) {
        return;
    } else {
        self.selectedDate = date;
        [self.delegate calendar:self didSelectDate:self.selectedDate];
    }
}

-(UIPopoverController *)monthYearPopoverController;
{
    if (nil != _monthYearPopoverController) {
        return _monthYearPopoverController;
    }
    
    CKCalendarViewPopoverController *pickerView = [[CKCalendarViewPopoverController alloc] initWithNibName:@"CKCalendarViewPopover" bundle:nil];
    [pickerView setDelegate:self];
    UINavigationController *contentView = [[UINavigationController alloc] initWithRootViewController:pickerView];

    _monthYearPopoverController = [[UIPopoverController alloc] initWithContentViewController:contentView];
    [_monthYearPopoverController setDelegate:self];
    [_monthYearPopoverController setPopoverContentSize:CGSizeMake(320.f, 250.f)];

    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        [_monthYearPopoverController setBackgroundColor:[UIColor cptPrimaryColor]];
    }

    return _monthYearPopoverController;
}

- (void)titleButtonPressed:(id)sender;
{
    // Need to present popup or actionSheet allowing quick change of month and year via picker
    if (nil != _monthYearPopoverController) {
        [self.monthYearPopoverController dismissPopoverAnimated:YES];
    }
    if (self.monthYearPopoverController.popoverVisible == NO) {
        [self.delegate calendar:self willDisplayMonthYearPopover:self.monthYearPopoverController];
        UINavigationController *navController = (UINavigationController *)self.monthYearPopoverController.contentViewController;
        CKCalendarViewPopoverController *mainController = (CKCalendarViewPopoverController *)[navController topViewController];
        [mainController setCurrentShowingDate:[self.monthShowing copy]];
        [self.monthYearPopoverController presentPopoverFromRect:[self.titleButton frame] inView:self permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

#pragma mark - CKCalendarViewPopoverControllerDelegate Methods

-(void)cancelChangeToNewDate;
{
    [self.monthYearPopoverController dismissPopoverAnimated:YES];
    [self setMonthYearPopoverController:nil];
}

-(void)dateChangeToNewDate:(NSDate *)newDate;
{
   //DDLogVerbose(@"Change date to %@",newDate);
    [self setMonthShowing:newDate];
    [self.monthYearPopoverController dismissPopoverAnimated:YES];
    [self setMonthYearPopoverController:nil];
}

-(void)dateChangeToToday;
{
    [self dateChangeToNewDate:[NSDate date]];
    [self.delegate calendar:self didSelectDate:[NSDate date]];
}

#pragma mark - Theming getters/setters

- (void)setTitleFont:(UIFont *)font {
    self.titleLabel.font = font;
}
- (UIFont *)titleFont {
    return self.titleLabel.font;
}

- (void)setTitleColor:(UIColor *)color {
    self.titleLabel.textColor = color;
}
- (UIColor *)titleColor {
    return self.titleLabel.textColor;
}

- (void)setButtonColor:(UIColor *)color {
    [self.prevButton setImage:[CKCalendarView imageNamed:kCalendarArrowButtonLeft withColor:color] forState:UIControlStateNormal];
    [self.nextButton setImage:[CKCalendarView imageNamed:kCalendarArrowButtonRight withColor:color] forState:UIControlStateNormal];
}

- (void)setInnerBorderColor:(UIColor *)color {
    self.calendarContainer.layer.borderColor = color.CGColor;
}

- (void)setDayOfWeekFont:(UIFont *)font {
    for (UILabel *label in self.dayOfWeekLabels) {
        label.font = font;
    }
}
- (UIFont *)dayOfWeekFont {
    return (self.dayOfWeekLabels.count > 0) ? ((UILabel *)[self.dayOfWeekLabels lastObject]).font : nil;
}

- (void)setDayOfWeekTextColor:(UIColor *)color {
    for (UILabel *label in self.dayOfWeekLabels) {
        label.textColor = color;
    }
}
- (UIColor *)dayOfWeekTextColor {
    return (self.dayOfWeekLabels.count > 0) ? ((UILabel *)[self.dayOfWeekLabels lastObject]).textColor : nil;
}

- (void)setDayOfWeekBottomColor:(UIColor *)bottomColor topColor:(UIColor *)topColor {
    [self.daysHeader setColors:[NSArray arrayWithObjects:topColor, bottomColor, nil]];
}

- (void)setDateFont:(UIFont *)font {
    for (DateButton *dateButton in self.dateButtons) {
        dateButton.titleLabel.font = font;
    }
}
- (UIFont *)dateFont {
    return (self.dateButtons.count > 0) ? ((DateButton *)[self.dateButtons lastObject]).titleLabel.font : nil;
}

- (void)setDateTextColor:(UIColor *)color {
    _dateTextColor = color;
    [self setNeedsLayout];
}

- (void)setDisabledDateTextColor:(UIColor *)color {
    _disabledDateTextColor = color;
    [self setNeedsLayout];
}

- (void)setDateBackgroundColor:(UIColor *)color {
    for (DateButton *dateButton in self.dateButtons) {
        dateButton.backgroundColor = color;
    }
}
- (UIColor *)dateBackgroundColor {
    return (self.dateButtons.count > 0) ? ((DateButton *)[self.dateButtons lastObject]).backgroundColor : nil;
}

- (void)setDateBorderColor:(UIColor *)color {
    self.calendarContainer.backgroundColor = color;
}
- (UIColor *)dateBorderColor {
    return self.calendarContainer.backgroundColor;
}

#pragma mark - Calendar helpers

- (NSDate *)firstDayOfMonthContainingDate:(NSDate *)date;
{
    NSDateComponents *comps;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        comps = [self.calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:date];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        comps = [self.calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:date];
#pragma clang diagnostic pop
    }
    

    comps.day = 1;
    return [self.calendar dateFromComponents:comps];
}

- (NSDate *)firstDayOfNextMonthContainingDate:(NSDate *)date;
{
    NSDateComponents *comps;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        comps = [self.calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:date];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        comps = [self.calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:date];
#pragma clang diagnostic pop
    }
    

    comps.day = 1;
    comps.month = comps.month + 1;
    return [self.calendar dateFromComponents:comps];
}

- (NSComparisonResult)compareByMonth:(NSDate *)date toDate:(NSDate *)otherDate;
{
    NSDateComponents *day;
    NSDateComponents *day2;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        day = [self.calendar components:NSCalendarUnitYear|NSCalendarUnitMonth fromDate:date];
        day2 = [self.calendar components:NSCalendarUnitYear|NSCalendarUnitMonth fromDate:otherDate];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        day = [self.calendar components:NSYearCalendarUnit|NSMonthCalendarUnit fromDate:date];
        day2 = [self.calendar components:NSYearCalendarUnit|NSMonthCalendarUnit fromDate:otherDate];
#pragma clang diagnostic pop
    }

    if (day.year < day2.year) {
        return NSOrderedAscending;
    } else if (day.year > day2.year) {
        return NSOrderedDescending;
    } else if (day.month < day2.month) {
        return NSOrderedAscending;
    } else if (day.month > day2.month) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

- (NSArray *)getDaysOfTheWeek;
{
    // adjust array depending on which weekday should be first
    NSArray *weekdays = [self.dateFormatter shortWeekdaySymbols];
    NSUInteger firstWeekdayIndex = [self.calendar firstWeekday] - 1;
    if (firstWeekdayIndex > 0) {
        weekdays = [[weekdays subarrayWithRange:NSMakeRange(firstWeekdayIndex, 7 - firstWeekdayIndex)]
                    arrayByAddingObjectsFromArray:[weekdays subarrayWithRange:NSMakeRange(0, firstWeekdayIndex)]];
    }
    return weekdays;
}

- (NSInteger)placeInWeekForDate:(NSDate *)date;
{
    NSDateComponents *compsFirstDayInMonth;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        compsFirstDayInMonth = [self.calendar components:NSCalendarUnitWeekday fromDate:date];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        compsFirstDayInMonth = [self.calendar components:NSWeekdayCalendarUnit fromDate:date];
#pragma clang diagnostic pop
    }

    return (compsFirstDayInMonth.weekday - 1 - self.calendar.firstWeekday + 8) % 7;
}

- (BOOL)dateIsToday:(NSDate *)date;
{
    return [self date:[NSDate date] isSameDayAsDate:date];
}

- (BOOL)date:(NSDate *)date1 isSameDayAsDate:(NSDate *)date2;
{
    // Both dates must be defined, or they're not the same
    if (date1 == nil || date2 == nil) {
        return NO;
    }

    NSDateComponents *day;
    NSDateComponents *day2;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        day = [self.calendar components:NSCalendarUnitEra|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:date1];
        day2 = [self.calendar components:NSCalendarUnitEra|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:date2];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        day = [self.calendar components:NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:date1];
        day2 = [self.calendar components:NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:date2];
#pragma clang diagnostic pop
    }
    

    return ([day2 day] == [day day] &&
            [day2 month] == [day month] &&
            [day2 year] == [day year] &&
            [day2 era] == [day era]);
}

- (NSInteger)weekNumberInMonthForDate:(NSDate *)date;
{
    // Return zero-based week in month
    NSInteger placeInWeek = [self placeInWeekForDate:self.monthShowing];
    NSDateComponents *comps;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        comps = [self.calendar components:(NSCalendarUnitDay) fromDate:date];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        comps = [self.calendar components:(NSDayCalendarUnit) fromDate:date];
#pragma clang diagnostic pop
    }
    

    return (comps.day + placeInWeek - 1) / 7;
}

- (NSInteger)numberOfWeeksInMonthContainingDate:(NSDate *)date;
{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        return [self.calendar rangeOfUnit:NSCalendarUnitWeekOfMonth inUnit:NSCalendarUnitMonth forDate:date].length;
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        return [self.calendar rangeOfUnit:NSWeekCalendarUnit inUnit:NSMonthCalendarUnit forDate:date].length;
#pragma clang diagnostic pop
    }

}

- (NSDate *)nextDay:(NSDate *)date;
{
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setDay:1];
    return [self.calendar dateByAddingComponents:comps toDate:date options:0];
}

- (NSDate *)previousDay:(NSDate *)date;
{
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setDay:-1];
    return [self.calendar dateByAddingComponents:comps toDate:date options:0];
}

+ (UIImage *)imageNamed:(NSString *)name withColor:(UIColor *)color;
{
    UIImage *img = [UIImage imageNamed:name];

    UIGraphicsBeginImageContextWithOptions(img.size, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [color setFill];

    CGContextTranslateCTM(context, 0, img.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);

    CGContextSetBlendMode(context, kCGBlendModeColorBurn);
    CGRect rect = CGRectMake(0, 0, img.size.width, img.size.height);
    CGContextDrawImage(context, rect, img.CGImage);

    CGContextClipToMask(context, rect, img.CGImage);
    CGContextAddRect(context, rect);
    CGContextDrawPath(context,kCGPathFill);

    UIImage *coloredImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return coloredImg;
}

@end
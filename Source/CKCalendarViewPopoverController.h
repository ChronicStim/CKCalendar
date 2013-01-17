//
//  CKCalendarViewPopoverController.h
//  PainTracker
//
//  Created by Wendy Kutschke on 10/28/12.
//  Copyright (c) 2012 Chronic Stimulation, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CPTUIViewController.h"
#import "UIMonthYearPicker.h"

@protocol CKCalendarViewPopoverControllerDelegate;
@interface CKCalendarViewPopoverController : CPTUIViewController
< UIMonthYearPickerDelegate >

@property (strong, nonatomic) NSDate *currentShowingDate;
@property (weak, nonatomic) IBOutlet UIMonthYearPicker *pickerView;
@property (weak, nonatomic) id <CKCalendarViewPopoverControllerDelegate> delegate;

- (IBAction)barButtonCancelPressed:(id)sender;
- (IBAction)barButtonSelectPressed:(id)sender;
- (IBAction)barButtonTodayPressed:(id)sender;

@end

@protocol CKCalendarViewPopoverControllerDelegate

-(void)cancelChangeToNewDate;
-(void)dateChangeToNewDate:(NSDate *)newDate;
-(void)dateChangeToToday;

@end

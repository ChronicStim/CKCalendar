//
//  CKCalendarViewPopoverController.m
//  PainTracker
//
//  Created by Wendy Kutschke on 10/28/12.
//  Copyright (c) 2012 Chronic Stimulation, LLC. All rights reserved.
//

#import "CKCalendarViewPopoverController.h"

@interface CKCalendarViewPopoverController ()

@end

@implementation CKCalendarViewPopoverController
@synthesize currentShowingDate = _currentShowingDate;
@synthesize pickerView = _pickerView;
@synthesize barButtonCancel = _barButtonCancel;
@synthesize barButtonSelect = _barButtonSelect;
@synthesize labelMessage = _labelMessage;
@synthesize delegate = _delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self.pickerView awakeFromNib];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setCurrentShowingDate:(NSDate *)currentShowingDate;
{
    if (currentShowingDate != _currentShowingDate) {
        _currentShowingDate = currentShowingDate;
        [self.pickerView setDate:_currentShowingDate];
    }
}

- (IBAction)barButtonCancelPressed:(id)sender {
    [self.delegate cancelChangeToNewDate];
}

- (IBAction)barButtonSelectPressed:(id)sender {

    [self.delegate dateChangeToNewDate:[[self.pickerView date] copy]];
    
}

#pragma mark - UIMonthYearPickerDelegate Methods

- (void)pickerView:(UIPickerView *)pickerView didChangeDate:(NSDate*)newDate;
{
    DDLogVerbose(@"Did change date: %@",newDate);
    [self setCurrentShowingDate:newDate];
}

@end

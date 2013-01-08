//
//  CKCalendarViewPopoverController.m
//  PainTracker
//
//  Created by Wendy Kutschke on 10/28/12.
//  Copyright (c) 2012 Chronic Stimulation, LLC. All rights reserved.
//

#import "CKCalendarViewPopoverController.h"
#import "PainTrackerAppDelegate.h"

@interface CKCalendarViewPopoverController ()

@end

@implementation CKCalendarViewPopoverController
@synthesize currentShowingDate = _currentShowingDate;
@synthesize pickerView = _pickerView;
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
    [self setNavBar];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setNavBar {
    
	PainTrackerAppDelegate *appDelegate = (PainTrackerAppDelegate *)[[UIApplication sharedApplication] delegate];
	NSString *titleStr = NSLocalizedStringFromTable(@"Month Selection",@"PainTracker",@"Month Selection");
	self.navigationItem.titleView = [appDelegate titleBarLabelWithString:titleStr];
	self.navigationController.navigationBar.tintColor = [UIColor cptToolbarTintColor];
    
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithTitle:@"Today" style:UIBarButtonItemStylePlain target:self action:@selector(barButtonTodayPressed:)];
    [leftButton setTintColor:[UIColor cptPrimaryColor]];
    self.navigationItem.leftBarButtonItem = leftButton;
    
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Apply" style:UIBarButtonItemStylePlain target:self action:@selector(barButtonSelectPressed:)];
    [rightButton setTintColor:[UIColor cptPrimaryColorSelected]];
    self.navigationItem.rightBarButtonItem = rightButton;
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

- (IBAction)barButtonTodayPressed:(id)sender;
{
    [self.delegate dateChangeToToday];
}

#pragma mark - UIMonthYearPickerDelegate Methods

- (void)pickerView:(UIPickerView *)pickerView didChangeDate:(NSDate*)newDate;
{
    DDLogVerbose(@"Did change date: %@",newDate);
    [self setCurrentShowingDate:newDate];
}

@end

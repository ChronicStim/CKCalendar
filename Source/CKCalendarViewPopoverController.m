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

-(void)awakeFromNib;
{
    [super awakeFromNib];
    
    [self bk_addObserverForKeyPath:@"currentShowingDate" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) task:^(id obj, NSDictionary *change) {
        
        NSDate *oldDate = [change objectForKey:NSKeyValueChangeOldKey];
        NSDate *newDate = [change objectForKey:NSKeyValueChangeNewKey];
        
        if (nil == newDate) {
            [[(CKCalendarViewPopoverController *)obj pickerView] setDate:[NSDate date]];
        }
        else if ([oldDate isEqualToDate:newDate]) {
            return;
        }
        else {
            [[(CKCalendarViewPopoverController *)obj pickerView] setDate:newDate];
        }
    }];
    [self.pickerView setMinimumDate:[NSDate dateWithTimeIntervalSince1970:0]];
}

-(void)viewWillAppear:(BOOL)animated;
{
    [super viewWillAppear:animated];
    
    [self setNavBar];
    
    if (nil != self.currentShowingDate && ![self.currentShowingDate isEqualToDate:self.pickerView.date]) {
        [self.pickerView setDate:self.currentShowingDate];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    [self bk_removeAllBlockObservers];
}

-(void)setNavBar {
    
	NSString *titleStr = NSLocalizedStringFromTable(@"Month Selection",@"PainTracker",@"Month Selection");
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self updateNavigationBarTitle:titleStr showHelpButton:NO];
    } else {
        [self updateNavigationBarTitle:titleStr showHelpButton:NO];
    }
    
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Today",@"PainTracker",@"Today") style:UIBarButtonItemStylePlain target:self action:@selector(barButtonTodayPressed:)];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        [leftButton setTintColor:[UIColor whiteColor]];
    } else {
        [leftButton setTintColor:[UIColor cptPrimaryColor]];
    }
    self.navigationItem.leftBarButtonItem = leftButton;
    
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Apply",@"PainTracker",@"Apply") style:UIBarButtonItemStylePlain target:self action:@selector(barButtonSelectPressed:)];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        [rightButton setTintColor:[UIColor cptPrimaryColorSelected]];
    } else {
        [rightButton setTintColor:[UIColor cptPrimaryColorSelected]];
    }
    self.navigationItem.rightBarButtonItem = rightButton;
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
   //DDLogVerbose(@"Did change date: %@",newDate);
    [self setCurrentShowingDate:newDate];
}

@end

//
//  SettingsController.m
//  Sleep Diary
//
//  Created by Alexander Ivanov on 01.08.15.
//  Copyright (c) 2015 Alexander Ivanov. All rights reserved.
//

#import "SettingsController.h"
#import "AlarmController.h"
#import "Localization.h"
#import "Global.h"
#import "Widget.h"

#import "UIButton+Convenience.h"
#import "UIDatePicker+Convenience.h"
#import "UIFont+Modification.h"

#import "NSArray+Convenience.h"
#import "NSCalendar+Convenience.h"
#import "NSFormatter+Convenience.h"
#import "NSObject+Convenience.h"
#import "UIScrollView+Convenience.h"
#import "UITableView+Convenience.h"
#import "UITableViewCell+Convenience.h"
#import "Dispatch+Convenience.h"
#import "QuartzCore+Convenience.h"
#import "UserNotifications+Convenience.h"

#define IMG_ALARM_LINE @"alarm-line"
#define IMG_ALARM_FULL @"alarm-full"
#define IMG_TIMER_LINE @"timer-line"
#define IMG_TIMER_FULL @"timer-full"

@interface SettingsController ()
@property (weak, nonatomic) IBOutlet UIImageView *bedtimeAlertImage;
@property (weak, nonatomic) IBOutlet UISwitch *bedtimeAlertSwitch;
@property (weak, nonatomic) IBOutlet UIImageView *sleepDurationImage;
@property (weak, nonatomic) IBOutlet UILabel *sleepDurationLabel;

@property (weak, nonatomic) IBOutlet UIButton *sunButton;
@property (weak, nonatomic) IBOutlet UIButton *monButton;
@property (weak, nonatomic) IBOutlet UIButton *tueButton;
@property (weak, nonatomic) IBOutlet UIButton *wedButton;
@property (weak, nonatomic) IBOutlet UIButton *thuButton;
@property (weak, nonatomic) IBOutlet UIButton *friButton;
@property (weak, nonatomic) IBOutlet UIButton *satButton;
@property (strong, nonatomic, readonly) NSArray<UIButton *> *wakeUpButtons;

@property (weak, nonatomic) IBOutlet UIImageView *wakeUpTimeImage;
@property (weak, nonatomic) IBOutlet UILabel *wakeUpTimeLabel;

@property (strong, nonatomic) UIDatePickerController *pickerController;
@end

@implementation SettingsController

__synthesize(NSArray<UIButton *> *, wakeUpButtons, (@[ self.sunButton, self.monButton, self.tueButton, self.wedButton, self.thuButton, self.friButton, self.satButton ]))

- (void)setIndexPath:(NSIndexPath *)indexPath {
	self.sleepDurationLabel.textColor = indexPath && !indexPath.section ? self.bedtimeAlertSwitch.onTintColor : [UIColor color:HEX_IOS_DARK_GRAY];
	self.sleepDurationLabel.font = indexPath && !indexPath.section ? [self.sleepDurationLabel.font bold] : [self.sleepDurationLabel.font original];
	self.sleepDurationImage.image = indexPath && !indexPath.section ? [UIImage originalImage:IMG_TIMER_FULL] : [UIImage originalImage:IMG_TIMER_LINE];

	UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];

	self.wakeUpTimeLabel.textColor = indexPath && indexPath.section ? cell.tintColor : [UIColor color:HEX_IOS_DARK_GRAY];
	self.wakeUpTimeLabel.font = indexPath && indexPath.section ? [self.sleepDurationLabel.font bold] : [self.sleepDurationLabel.font original];
	self.wakeUpTimeImage.image = indexPath && indexPath.section ? [UIImage originalImage:IMG_ALARM_FULL] : [UIImage originalImage:IMG_ALARM_LINE];

	if (!indexPath)
		return;

	[self.pickerController.datePicker setNullableDate:[[[NSDate date] dateComponent] dateByAddingTimeInterval:indexPath.section ? GLOBAL.alarmTime : GLOBAL.sleepDuration]];
	
	[self.pickerController.doneButton setTitleColor:indexPath.section ? cell.tintColor : self.bedtimeAlertSwitch.onTintColor forState:UIControlStateNormal];

	self.pickerController.titleLabel.text = [self.tableView cellForRowAtIndexPath:indexPath].textLabel.text;
}

- (UIDatePickerController *)pickerController {
	if (!_pickerController) {
		_pickerController = [[UIDatePickerController alloc] initWithView:self.view.rootview];

		_pickerController.backgroundColor = RGB(23, 23, 23);
		_pickerController.pickerColor = [UIColor whiteColor];
		_pickerController.titleColor = [UIColor lightGrayColor];
		_pickerController.buttonColor = GLOBAL.tintColor;
		
		_pickerController.datePicker.datePickerMode = UIDatePickerModeTime;

		__weak SettingsController *__self = self;
		_pickerController.datePickerValueChanged = ^(UIDatePicker *sender, id identifier) {
			[__self pickerValueChanged:sender indexPath:cls(NSIndexPath, identifier)];
		};
		_pickerController.identifierValueChanged = ^(UIDatePicker *sender, id identifier) {
			[__self setIndexPath:cls(NSIndexPath, identifier)];
		};
	}

	return _pickerController;
}

- (IBAction)pickerValueChanged:(UIDatePicker *)sender indexPath:(NSIndexPath *)indexPath {
	NSTimeInterval time = [sender.date timeComponent];

	if (indexPath.section) {
		self.wakeUpTimeLabel.text = [[NSDateComponentsFormatter hhmmFormatter] stringFromTimeInterval:time];
		GLOBAL.alarmTime = time;
	} else {
		self.sleepDurationLabel.text = [[NSDateComponentsFormatter hhmmFormatter] stringFromTimeInterval:time];
		GLOBAL.sleepDuration = time;
	}

//	[AlarmController updateNotification];
	[WIDGET updateNotification:^(BOOL scheduled) {
		[self updateNotification];
	}];
}

- (IBAction)bedtimeAlertAction:(UISwitch *)sender {
	GLOBAL.bedtimeAlert = sender.on;

//	[AlarmController updateNotification];
	[WIDGET updateNotification:^(BOOL scheduled) {
		[self updateNotification];
	}];

	self.bedtimeAlertImage.highlighted = sender.on;
}

- (void)updateNotification {
	[UNUserNotificationCenter getPendingNotificationRequestWithIdentifier:GUI_FALL_ASLEEP completionHandler:^(UNNotificationRequest *request) {
		[GCD main:^{
			[self.tableView setFooterText:[Localization notification:request.nextTriggerDate] forSection:0];
		}];
	}];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	self.bedtimeAlertSwitch.on = GLOBAL.bedtimeAlert;
	self.sleepDurationLabel.text = [[NSDateComponentsFormatter hhmmFormatter] stringFromTimeInterval:GLOBAL.sleepDuration];

	self.bedtimeAlertImage.highlighted = self.bedtimeAlertSwitch.on;

	self.wakeUpTimeLabel.text = [[NSDateComponentsFormatter hhmmFormatter] stringFromTimeInterval:GLOBAL.alarmTime];

	NSUInteger firstWeekday = [NSCalendar currentCalendar].firstWeekday - 1;
	NSArray<NSString *> *weekdaySymbols = [NSCalendar currentCalendar].shortWeekdaySymbols;
	for (NSUInteger index = 0; index < self.wakeUpButtons.count; index++) {
		NSUInteger weekday = index - firstWeekday + self.wakeUpButtons.count;
		if (weekday >= self.wakeUpButtons.count)
			weekday -= self.wakeUpButtons.count;

		UIButton *button = idx(self.wakeUpButtons, weekday);
		[button setTitle:[idx(weekdaySymbols, index) uppercaseString]];
		[button.layer roundCorners:16.0];
//		[button.layer circle:1.0];
#warning Remove constant!

		button.selected = [idx(GLOBAL.alarmWeekdays, index) boolValue];
		button.backgroundColor = button.selected ? button.tintColor : button.superview.backgroundColor;
	}
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];

	[WIDGET requestRegistration:Nil];

	[self updateNotification];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];

	if (indexPath.section == 2 && indexPath.row == 0) {
		UIStepper *stepper = [[UIStepper alloc] initWithFrame:CGRectMake(0.0, 0.0, UIStepperWidth, UIStepperHeight)];
		stepper.tintColor = GLOBAL.tintColor;
		stepper.minimumValue = 0.0;
		stepper.maximumValue = 30.0 * TIME_MINUTE;
		stepper.stepValue = TIME_MINUTE;
		stepper.value = GLOBAL.sleepLatency;
		[stepper addTarget:self action:@selector(stepperValueChanged:) forControlEvents:UIControlEventValueChanged];
		[cell setAccessoryView:stepper insets:UIEdgeInsetsZero];

		cell.detailTextLabel.text = [[NSDateComponentsFormatter mmShortFormatter] stringFromTimeInterval:stepper.value];
	}

	return cell;
}

- (IBAction)stepperValueChanged:(UIStepper *)sender {
	[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]].detailTextLabel.text = [[NSDateComponentsFormatter mmShortFormatter] stringFromTimeInterval:sender.value];

	GLOBAL.sleepLatency = sender.value;

	[WIDGET updateNotification:^(BOOL scheduled) {
		[self updateNotification];
	}];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([indexPath isEqualToSection:0 row:1] || [indexPath isEqualToSection:1 row:1])
		self.pickerController.identifier = [indexPath isEqualToIndexPath:self.pickerController.identifier] ? Nil : indexPath;

	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (IBAction)wakeUpButtonTouch:(UIButton *)sender {
	sender.selected = !sender.selected;
	sender.backgroundColor = sender.selected ? sender.tintColor : sender.superview.backgroundColor;

	NSUInteger firstWeekday = [NSCalendar currentCalendar].firstWeekday - 1;
	GLOBAL.alarmWeekdays = [NSArray arrayFromCount:self.wakeUpButtons.count block:^id(NSUInteger index) {
		NSUInteger weekday = index - firstWeekday + self.wakeUpButtons.count;
		if (weekday >= self.wakeUpButtons.count)
			weekday -= self.wakeUpButtons.count;

		return @(self.wakeUpButtons[weekday].selected);
	}];

	self.pickerController.identifier = Nil;

//	[AlarmController updateNotification];
	[WIDGET updateNotification:^(BOOL scheduled) {
		[self updateNotification];
	}];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if (!UIAccessibilityIsVoiceOverRunning())
		self.pickerController.identifier = Nil;
}

@end

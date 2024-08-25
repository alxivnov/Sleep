//
//  IntervalController.m
//  Sleep Diary
//
//  Created by Alexander Ivanov on 24.02.15.
//  Copyright (c) 2015 Alexander Ivanov. All rights reserved.
//

#import "IntervalController.h"
#import "ActivityVisualizer.h"
#import "Global.h"
#import "WatchDelegate.h"

//#import "UIRateController.h"

#import "HKSleepAnalysis+CMMotionActivitySample.h"
#import "NSArray+Convenience.h"
#import "NSCalendar+Convenience.h"
#import "UIDatePicker+Convenience.h"
#import "UILabel+Convenience.h"
#import "UINavigationController+Convenience.h"
#import "UITableView+Convenience.h"
#import "UITableViewCell+Convenience.h"
#import "UserNotifications+Convenience.h"

#define SLEEP_ONSET_LATENCY_SECTION 2

@interface IntervalController ()
@property (weak, nonatomic) IBOutlet ActivityVisualizer *visualizer;

@property (strong, nonatomic) HKCategorySample *inBedSample;
@property (strong, nonatomic) NSArray<HKCategorySample *> *sleepSamples;
@property (strong, nonatomic) NSArray<CMMotionActivitySample *> *activities;
@property (strong, nonatomic) NSArray<CMMotionActivitySample *> *watchActivities;

@property (weak, nonatomic) IBOutlet UIImageView *startImage;
@property (weak, nonatomic) IBOutlet UILabel *startLabel;
@property (weak, nonatomic) IBOutlet UIImageView *endImage;
@property (weak, nonatomic) IBOutlet UILabel *endLabel;
@property (weak, nonatomic) IBOutlet UIImageView *longPressImage;
@property (weak, nonatomic) IBOutlet UISwitch *longPressSwitch;

@property (strong, nonatomic, readonly) UIDatePickerController *pickerController;

@property (strong, nonatomic) NSDate *startDate;
@property (strong, nonatomic) NSDate *endDate;

@property (strong, nonatomic) NSArray<HKCategorySample *> *inBedSamplesToDelete;
@property (strong, nonatomic) NSArray<HKCategorySample *> *sleepSamplesToDelete;
@end

@implementation IntervalController

- (void)setStartDate:(NSDate *)startDate {
	_startDate = [startDate component:NSCalendarUnitMinute];

	self.startLabel.text = [_startDate descriptionForDate:NSDateFormatterMediumStyle andTime:NSDateFormatterShortStyle];
}

- (void)setEndDate:(NSDate *)endDate {
	_endDate = [endDate component:NSCalendarUnitMinute];

	self.endLabel.text = [_endDate descriptionForDate:NSDateFormatterMediumStyle andTime:NSDateFormatterShortStyle];
}

@synthesize pickerController = _pickerController;

- (UIDatePickerController *)pickerController {
	if (!_pickerController) {
		_pickerController = [[UIDatePickerController alloc] initWithView:self.view.rootview];

		_pickerController.backgroundColor = RGB(23, 23, 23);
		_pickerController.buttonColor = [UIColor color:RGB_DARK_TINT];
		_pickerController.pickerColor = [UIColor whiteColor];
		_pickerController.titleColor = [UIColor lightGrayColor];

		__weak IntervalController *__self = self;
		_pickerController.datePickerValueChanged = ^(UIDatePicker *sender, id identifier) {
			[__self datePickerValueChanged:sender indexPath:cls(NSIndexPath, identifier)];
		};
		_pickerController.identifierValueChanged = ^(UIDatePicker *sender, id identifier) {
			[__self identifierValueChanged:cls(NSIndexPath, identifier)];
		};
	}

	return _pickerController;
}

- (IBAction)datePickerValueChanged:(UIDatePicker *)sender indexPath:(NSIndexPath *)indexPath {
	if (indexPath.row == 0)
		self.startDate = sender.date;
	else if (indexPath.row == 1)
		self.endDate = sender.date;
	
	[self setProgress:-self.visualizer.sleepLatency.doubleValue scrollRectToVisibleDate:sender.date];

	HKCategorySample *sample = [self.sample.allSamples firstObject:^BOOL(HKCategorySample *obj) {
		return obj.metadata[HKMetadataKeySampleActivities] != Nil;
	}];
	if ([sample.startDate isGreaterThan:self.startDate])
		sample = Nil;
	if ([sample.endDate isLessThan:self.endDate])
		sample = Nil;
	[self loadActivities:/*sample*/Nil];
}

- (void)identifierValueChanged:(NSIndexPath *)indexPath {
	self.startLabel.textColor = indexPath && !indexPath.row ? [UIColor color:RGB_DARK_TINT] : [UIColor color:HEX_IOS_DARK_GRAY];
	self.startLabel.font = indexPath && !indexPath.row ? self.startLabel.boldSystemFont : self.startLabel.systemFont;
	self.startImage.image = [UIImage systemImageNamed:indexPath && !indexPath.row ? @"moon.fill" : @"moon"];

	self.endLabel.textColor = indexPath && indexPath.row ? [UIColor color:HEX_NCS_YELLOW] : [UIColor color:HEX_IOS_DARK_GRAY];
	self.endLabel.font = indexPath && indexPath.row ? self.startLabel.boldSystemFont : self.startLabel.systemFont;
	self.endImage.image = [UIImage systemImageNamed:indexPath && indexPath.row ? @"sun.min.fill" : @"sun.min"];

	if (!indexPath)
		return;

	[self.pickerController.datePicker setNullableDate:indexPath.row ? self.endDate : self.startDate];

	HKCategorySample *sample = GLOBAL.asleep ? [self.visualizer.sleepSamples lastObject:^BOOL(HKCategorySample *obj) {
		return ![obj isEqualToAnyObject:self.sleepSamples];
	}] : Nil;
	self.pickerController.datePicker.maximumDate = indexPath.row ? [NSDate date] : self.endDate;
	self.pickerController.datePicker.minimumDate = indexPath.row ? self.startDate : /*sample ? */sample.endDate/* : [self.endDate dateByAddingTimeInterval:0.0 - 10.0 * TIME_HOUR]*/;

	[self.pickerController.doneButton setTitleColor:indexPath.row ? [UIColor color:HEX_NCS_YELLOW] : [UIColor color:RGB_DARK_TINT] forState:UIControlStateNormal];

	self.pickerController.titleLabel.text = [self.tableView cellForRowAtIndexPath:indexPath].textLabel.text;
}

- (void)setInBedSample:(HKCategorySample *)inBedSample {
	if (_inBedSample == inBedSample)
		return;

	NSMutableArray<HKCategorySample *> *samples = [self.visualizer.inBedSamples mutableCopy] ?: [NSMutableArray new];
	if (_inBedSample)
		[samples removeObject:_inBedSample];
	if (inBedSample)
		[samples addObject:inBedSample];
	self.visualizer.inBedSamples = [samples sortedArrayUsingComparator:^NSComparisonResult(HKCategorySample *  _Nonnull obj1, HKCategorySample *  _Nonnull obj2) {
		return [obj1.startDate compare:obj2.startDate];
	}];

	_inBedSample = inBedSample;
}

- (void)setSleepSamples:(NSArray<HKCategorySample *> *)sleepSamples {
	if (_sleepSamples == sleepSamples)
		return;

	NSMutableArray<HKCategorySample *> *samples = [self.visualizer.sleepSamples mutableCopy] ?: [NSMutableArray new];
	if (_sleepSamples)
		[samples removeObjectsInArray:_sleepSamples];
	if (sleepSamples)
		[samples addObjectsFromArray:sleepSamples];
	self.visualizer.sleepSamples = [samples sortedArrayUsingComparator:^NSComparisonResult(HKCategorySample *  _Nonnull obj1, HKCategorySample *  _Nonnull obj2) {
		return [obj1.startDate compare:obj2.startDate];
	}];

	_sleepSamples = sleepSamples;
}

@synthesize activities = _activities;

- (void)setActivities:(NSArray<CMMotionActivitySample *> *)activities {
	if (_activities == activities)
		return;

	_activities = activities;

	self.visualizer.activities = activities;

	[GCD main:^{
		[self setProgress:-self.visualizer.sleepLatency.doubleValue];
	}];
}

- (NSArray<CMMotionActivitySample *> *)activities {
	return /*_activities ? [_activities query:^BOOL(CMMotionActivitySample *obj) {
		return ([obj.startDate isGreaterThanOrEqual:self.startDate] && [obj.startDate isLessThan:self.endDate]) || ([obj.endDate isGreaterThan:self.startDate] && [obj.endDate isLessThanOrEqual:self.endDate]);
	}] :*/ [self.visualizer.activities query:^BOOL(CMMotionActivitySample *obj) {
		return ([obj.startDate isGreaterThanOrEqual:self.startDate] && [obj.startDate isLessThan:self.endDate]) && ([obj.endDate isGreaterThan:self.startDate] && [obj.endDate isLessThanOrEqual:self.endDate]);
	}];
}

- (void)setWatchActivities:(NSArray<CMMotionActivitySample *> *)watchActivities {
	_watchActivities = watchActivities;

	self.activities = _watchActivities;
}

- (void)setProgress:(NSTimeInterval)sleepLatency {
	[self setProgress:sleepLatency scrollRectToVisibleDate:Nil];
}

- (void)setProgress:(NSTimeInterval)sleepLatency scrollRectToVisibleDate:(NSDate *)date {
	if ([self.endDate timeIntervalSinceDate:self.startDate] <= 345600) {
		self.inBedSample = sleepLatency ? [HKDataSleepAnalysis sampleWithStartDate:self.startDate endDate:self.endDate value:HKCategoryValueSleepAnalysisInBed metadata:Nil] : Nil;
		
		NSArray<HKCategorySample *> *sleepSamples = [self.visualizer.sleepSamples query:^BOOL(HKCategorySample *obj) {
			return obj.sourceName && [obj.startDate isGreaterThanOrEqual:self.sample.startDate] && [obj.endDate isLessThanOrEqual:self.sample.endDate];
		}];
		NSTimeInterval startInterval = [sleepSamples.firstObject.startDate timeIntervalSinceDate:self.startDate];
		NSTimeInterval endInterval = [self.endDate timeIntervalSinceDate:sleepSamples.lastObject.endDate];
		NSDate *inBedStart = startInterval > sleepLatency && endInterval > sleepLatency && startInterval < endInterval ? sleepSamples.lastObject.endDate : self.startDate;
		NSDate *inBedEnd = startInterval > sleepLatency && endInterval > sleepLatency && startInterval > endInterval ? sleepSamples.firstObject.startDate : self.endDate;
		self.sleepSamples = sleepLatency
			? [HKDataSleepAnalysis samplesWithStartDate:inBedStart endDate:inBedEnd activities:self.activities sleepLatency:sleepLatency adaptive:YES]
			: arr_([HKDataSleepAnalysis sampleWithStartDate:inBedStart endDate:inBedEnd value:CategoryValueSleepAnalysisAsleepUnspecified metadata:Nil]);
		[self.visualizer scrollRectToVisibleDate:date ?: self.endDate animated:YES];
	}

	self.navigationController.navigationBar.progress = [[self.visualizer.sleepSamples query:^BOOL(HKCategorySample *obj) {
		return obj.endDate.isToday;
	}] vSum:^NSNumber *(HKCategorySample *obj) {
		return @(obj.duration);
	}] / GLOBAL.sleepDuration;
}

- (IBAction)longPressSwitchValueChanged:(UISwitch *)sender {
	GLOBAL.longPress = @(sender.on);

	self.longPressImage.highlighted = sender.on;
}

- (void)viewDidLoad {
    [super viewDidLoad];

	if (!GLOBAL.longPress)
		GLOBAL.longPress = @YES;

	self.longPressSwitch.on = GLOBAL.longPress.boolValue;
	self.longPressImage.highlighted = self.longPressSwitch.on;

	now(now);
	
	NSDate *startDate = [now addValue:-1 forComponent:NSCalendarUnitDay];
	NSDate *endDate = now;

	if (self.sample) {
		NSTimeInterval interval = (TIME_DAY - [self.sample.endDate timeIntervalSinceDate:self.sample.startDate]) / 2.0;
		startDate = [self.sample.startDate dateByAddingTimeInterval:0.0 - interval];
		endDate = [self.sample.endDate dateByAddingTimeInterval:interval];
	}

	self.visualizer.zoom = 0.5 * (GLOBAL.scale ? 2.0 : 1.0);
	self.visualizer.edit = YES;

	[self.visualizer loadWithStartDate:startDate endDate:endDate completion:^{
		if (self.sample) {
			self.inBedSamplesToDelete = [self.visualizer.inBedSamples query:^BOOL(HKCategorySample *obj) {
				return obj.isOwn && [obj.startDate isGreaterThanOrEqual:self.sample.startDate] && [obj.endDate isLessThanOrEqual:self.sample.endDate];
			}];
			self.sleepSamplesToDelete = [self.visualizer.sleepSamples query:^BOOL(HKCategorySample *obj) {
				return obj.isOwn && [obj.startDate isGreaterThanOrEqual:self.sample.startDate] && [obj.endDate isLessThanOrEqual:self.sample.endDate];
			}];

			self.visualizer.inBedSamples = [self.visualizer.inBedSamples arrayByRemovingObjectsFromArray:self.inBedSamplesToDelete];
			self.visualizer.sleepSamples = [self.visualizer.sleepSamples arrayByRemovingObjectsFromArray:self.sleepSamplesToDelete];
		}

		[UNUserNotificationCenter getPendingNotificationRequestsWithIdentifier:GUI_FALL_ASLEEP completionHandler:^(NSArray<UNNotificationRequest *> *requests) {
			self.visualizer.fallAsleep = requests.firstObject.nextTriggerDate;
		}];

		[GCD main:^{
			if (self.sample) {
				self.startDate = self.sample.startDate;
				self.endDate = self.sample.endDate;
			} else if (GLOBAL.asleep) {
				self.startDate = GLOBAL.startDate;
				self.endDate = now;
			} else {
				NSDate *startDate = [now addValue:-8 forComponent:NSCalendarUnitHour];
				NSDate *endDate = self.visualizer.inBedSamples.lastObject.endDate;

				self.startDate = [endDate isGreaterThan:startDate] ? endDate : startDate;
				self.endDate = now;
			}

			[self setProgress:GLOBAL.sleepLatency];

			NSTimeInterval sleepLatency = [self.sleepSamples.firstObject.metadata[HKMetadataKeySleepOnsetLatency] doubleValue];
			self.visualizer.sleepLatency = @(sleepLatency > 60.0 ? (floor(sleepLatency / 60.0) * 60.0) : sleepLatency);

			UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:SLEEP_ONSET_LATENCY_SECTION]];
			cell.detailTextLabel.text = [[NSDateComponentsFormatter mmShortFormatter] stringFromTimeInterval:self.visualizer.sleepLatency.doubleValue];
			cls(UIStepper, cell.accessoryView.subviews.firstObject).value = self.visualizer.sleepLatency.doubleValue;
		}];

		[self loadActivities:self.sample.allSamples.firstObject];
	}];
	
//	[self.visualizer scrollRectToVisibleDate:now animated:YES];
}

- (void)loadActivities:(HKCategorySample *)sample {
	NSArray<CMMotionActivitySample *> *activities = [CMMotionActivitySample samplesFromString:sample.metadata[HKMetadataKeySampleActivities] date:sample.startDate];
	if (activities) {
		self.activities = activities;
	} else if (!self.watchActivities) {
		if ([self.startDate isGreaterThanOrEqual:[WatchDelegate instance].installedSession.receivedApplicationContext[KEY_TIMER_START]] && [self.endDate isLessThanOrEqual:[WatchDelegate instance].installedSession.receivedApplicationContext[KEY_TIMER_END]] && [WatchDelegate instance].installedSession.receivedApplicationContext[HKMetadataKeySampleActivities])
			self.watchActivities = [CMMotionActivitySample samplesFromData:[WatchDelegate instance].installedSession.receivedApplicationContext[HKMetadataKeySampleActivities] date:[WatchDelegate instance].installedSession.receivedApplicationContext[KEY_TIMER_START]];
		else if ([WatchDelegate instance].reachableSession)
			[[WatchDelegate instance] getActivitiesFromDate:self.visualizer.startDate toDate:self.visualizer.endDate handler:^(NSArray<CMMotionActivitySample *> *activities) {
				if (activities)
					self.watchActivities = activities;
				else
					[CMMotionActivitySample queryActivityStartingFromDate:self.visualizer.startDate toDate:self.visualizer.endDate within:0.0 withHandler:^(NSArray<CMMotionActivitySample *> *activities) {
//					[HKActiveEnergy queryActivityStartingFromDate:self.visualizer.startDate toDate:self.visualizer.endDate /*within:0.0*/ withHandler:^(NSArray<CMMotionActivitySample *> *activities) {
						self.activities = activities;
					}];
			}];
		else
			[CMMotionActivitySample queryActivityStartingFromDate:self.visualizer.startDate toDate:self.visualizer.endDate within:0.0 withHandler:^(NSArray<CMMotionActivitySample *> *activities) {
//			[HKActiveEnergy queryActivityStartingFromDate:self.visualizer.startDate toDate:self.visualizer.endDate /*within:0.0*/ withHandler:^(NSArray<CMMotionActivitySample *> *activities) {
				self.activities = activities;
			}];
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];

	if (indexPath.section == SLEEP_ONSET_LATENCY_SECTION && indexPath.row == 0) {
		UIStepper *stepper = [[UIStepper alloc] initWithFrame:CGRectMake(0.0, 0.0, UIStepperWidth, UIStepperHeight)];
		stepper.tintColor = [UIColor color:RGB_DARK_TINT];
		stepper.minimumValue = 0.0;
		stepper.maximumValue = 30.0 * TIME_MINUTE;
		stepper.stepValue = TIME_MINUTE;
		stepper.value = self.visualizer.sleepLatency.doubleValue;
		[stepper addTarget:self action:@selector(stepperValueChanged:) forControlEvents:UIControlEventValueChanged];
		[cell setAccessoryView:stepper insets:UIEdgeInsetsZero];

		cell.detailTextLabel.text = [[NSDateComponentsFormatter mmShortFormatter] stringFromTimeInterval:stepper.value];
	}

	return cell;
}

- (IBAction)stepperValueChanged:(UIStepper *)sender {
	self.visualizer.sleepLatency = @(sender.value);

	UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:SLEEP_ONSET_LATENCY_SECTION]];
	cell.detailTextLabel.text = [[NSDateComponentsFormatter mmShortFormatter] stringFromTimeInterval:sender.value];

	[self setProgress:-self.visualizer.sleepLatency.doubleValue];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//	if (!self.sample)
		self.pickerController.identifier = indexPath.section != 1 || [indexPath isEqualToIndexPath:self.pickerController.identifier] ? Nil : indexPath;
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (IBAction)cancel:(UIBarButtonItem *)sender {
	[GLOBAL endSleeping];

	[self performSegueWithIdentifier:GUI_CANCEL sender:sender];
}

- (IBAction)save:(UIBarButtonItem *)sender {
	[GLOBAL endSleeping];
	
//	BOOL hasInBed = [self.visualizer.inBedSamples any:^BOOL(HKCategorySample *obj) {
//		return !obj.isOwn && [obj.startDate isGreaterThanOrEqual:self.sample.startDate] && [obj.endDate isLessThanOrEqual:self.sample.endDate];
//	}];
//	BOOL hasSleep = [self.visualizer.sleepSamples any:^BOOL(HKCategorySample *obj) {
//		return !obj.isOwn && [obj.startDate isGreaterThanOrEqual:self.sample.startDate] && [obj.endDate isLessThanOrEqual:self.sample.endDate];
//	}];
//	NSNumber *adaptive = hasInBed || hasSleep
//		? Nil
//		: @YES;
	NSNumber *adaptive = @YES;
	
	NSTimeInterval sleepLatency = self.visualizer.sleepLatency.doubleValue;
	NSArray<HKCategorySample *> *sleepSamples = [self.visualizer.sleepSamples query:^BOOL(HKCategorySample *obj) {
		return obj.sourceName && [obj.startDate isGreaterThanOrEqual:self.sample.startDate] && [obj.endDate isLessThanOrEqual:self.sample.endDate];
	}];
	NSTimeInterval startInterval = [sleepSamples.firstObject.startDate timeIntervalSinceDate:self.startDate];
	NSTimeInterval endInterval = [self.endDate timeIntervalSinceDate:sleepSamples.lastObject.endDate];
	if (startInterval > sleepLatency || endInterval > sleepLatency) {
		if (startInterval < endInterval) {
			adaptive = @(-sleepSamples.lastObject.endDate.timeIntervalSinceReferenceDate);
		} else if (startInterval > endInterval) {
			adaptive = @(sleepSamples.firstObject.startDate.timeIntervalSinceReferenceDate);
		}
	}

	if (self.inBedSamplesToDelete.count || self.sleepSamplesToDelete.count)
		[[HKHealthStore defaultStore] deleteObjects:self.inBedSamplesToDelete.count && self.sleepSamplesToDelete.count ? [self.inBedSamplesToDelete arrayByAddingObjectsFromArray:self.sleepSamplesToDelete] : self.inBedSamplesToDelete.count ? self.inBedSamplesToDelete : self.sleepSamplesToDelete completion:^(BOOL success) {
			if (success)
				[HKDataSleepAnalysis saveSampleWithStartDate:self.startDate endDate:self.endDate activities:self.activities sleepLatency:-self.visualizer.sleepLatency.doubleValue adaptive:adaptive completion:^(BOOL success) {
					[GCD main:^{
						[self performSegueWithIdentifier:success ? GUI_SAVE : GUI_CANCEL sender:Nil];
					}];
				}];
			else
				[GCD main:^{
					[self performSegueWithIdentifier:GUI_CANCEL sender:sender];
				}];
		}];
	else
		[HKDataSleepAnalysis saveSampleWithStartDate:self.startDate endDate:self.endDate activities:self.activities sleepLatency:-self.visualizer.sleepLatency.doubleValue adaptive:adaptive completion:^(BOOL success) {
			[GCD main:^{
				[self performSegueWithIdentifier:success ? GUI_SAVE : GUI_CANCEL sender:Nil];
			}];
		}];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if (!UIAccessibilityIsVoiceOverRunning())
		self.pickerController.identifier = Nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0 && indexPath.row == 1)
		return 128.0 * (GLOBAL.scale ? 2.0 : 1.0);

	return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (IBAction)scaleButtonAction:(UIButton *)sender {
	[self.tableView beginUpdates];
	GLOBAL.scale = !GLOBAL.scale;
	[self.tableView endUpdates];

	self.visualizer.zoom = 0.5 * (GLOBAL.scale ? 2.0 : 1.0);

	[sender setTitle:[NSString stringWithFormat:@"%dX", GLOBAL.scale ? 2 : 1] forState:UIControlStateNormal];
}

@end

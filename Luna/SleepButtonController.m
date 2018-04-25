//
//  SleepButtonController.m
//  Sleep Diary
//
//  Created by Alexander Ivanov on 25.04.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "SleepButtonController.h"

#import "AlarmController.h"
#import "SleepButtonCell.h"
#import "Global.h"
#import "Widget.h"
#import "Localization.h"
#import "HKCategorySample+JSON.h"

#import "UserNotifications+Convenience.h"
#import "UIAlertController+Convenience.h"
#import "UIViewController+Convenience.h"

#import "NSTimer+Convenience.h"
#import "UIRateController.h"
#import "WatchDelegate.h"
#import "WeekdaysController.h"

@interface SleepButtonController ()
@property (strong, nonatomic) NSSelectorTimer *timer;

@property (assign, nonatomic) BOOL startStopButtonTouchDown;

@property (weak, nonatomic) IBOutlet UIView *todayView;
@property (strong, nonatomic, readonly) SleepButtonCell *sleepCell;
@property (strong, nonatomic, readonly) UIButton *startButton;

@property (strong, nonatomic) IBOutlet UIView *healthKitView;
@property (strong, nonatomic) IBOutlet UIView *notificationsView;
@property (strong, nonatomic) IBOutlet UIView *emptyStateView;
@property (strong, nonatomic) IBOutlet UIView *alarmClockView;
@property (strong, nonatomic) AlarmController *alarmController;
@end

@implementation SleepButtonController

- (void)viewDidLoad {
	[super viewDidLoad];

	[WIDGET updateNotification:Nil];
	[WIDGET updateQuickActions];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	if (self.startDate.isToday) {
		if (GLOBAL.asleep)
			[HKDataSleepAnalysis querySamplesWithStartDate:GLOBAL.startDate endDate:Nil completion:^(NSArray<__kindof HKSample *> *samples) {
				if (samples.count)
					[GLOBAL endSleeping];

				[GCD main:^{
					[self setup];
				}];
			}];
		else
			[self setup];
	}
}

- (SleepButtonCell *)sleepCell {
	return cls(SleepButtonCell, [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]]);
}

- (UIButton *)startButton {
	return self.sleepCell.button;
}

- (AlarmController *)alarmController {
	if (!_alarmController)
		_alarmController = [[AlarmController alloc] initWithView:self.alarmClockView];

	return _alarmController;
}

- (void)setupTodayView:(UIView *)view {
	if (self.healthKitView != view)
		[self.healthKitView removeFromSuperview];
	if (self.notificationsView != view)
		[self.notificationsView removeFromSuperview];
	if (self.emptyStateView != view)
		[self.emptyStateView removeFromSuperview];
	if ([UIRateController instance].view != view)
		[[UIRateController instance].view removeFromSuperview];
	//	if (self.alertView != view)
	//		[self.alertView removeFromSuperview];
	if (self.alarmController.view != view)
		[self.alarmController.view removeFromSuperview];

	if (self.todayView != view.superview)
		[self.todayView addSubview:view];

	view.frame = self.todayView.bounds;
}

- (void)setDuration {
	NSTimeInterval sleepDuration = [[NSDate date] timeIntervalSinceDate:GLOBAL.startDate];
	NSUInteger cycleCount = floor(sleepDuration / SLEEP_CYCLE_DURATION);

	if ([[NSDate date] timeComponent] > 22.0 * TIME_HOUR)
		[self.sleepCell setSleepDuration:0.0 inBedDuration:sleepDuration cycleCount:cycleCount animated:NO];
	else
		[AnalysisPresenter query:NSCalendarUnitDay completion:^(NSArray<AnalysisPresenter *> *presenters) {
			[GCD main:^{
				NSTimeInterval sleep = presenters.firstObject.duration;
				NSTimeInterval inBed = [presenters.firstObject.allPresenters sum:^NSNumber *(AnalysisPresenter *obj) {
					return obj.allSamples.firstObject.value == HKCategoryValueSleepAnalysisInBed ? @(obj.duration) : Nil;
				}];

				[self.sleepCell setSleepDuration:sleep inBedDuration:inBed + sleepDuration cycleCount:presenters.firstObject.cycleCount + cycleCount animated:NO];
			}];
		}];
}

- (NSSelectorTimer *)timer {
	if (!_timer)
		_timer = [NSSelectorTimer create:^{
			if (!GLOBAL.asleep)
				return;

			[self.startButton setTitle:[[NSDateComponentsFormatter hhmmssFormatter] stringFromValue:GLOBAL.startDate toValue:[NSDate date]] forState:UIControlStateSelected];

			[self setDuration];
		} interval:1.0];

	return _timer;
}

- (void)setup {
	NSDate *startDate = GLOBAL.startDate;

	if (startDate) {
		self.startButton.selected = YES;
		//		self.startStopLabel.text = [GLOBAL button];
		//		self.startStopLabel.textColor = [[UIColorCache instance] colorWithR:63 G:58 B:171];
		[self.startButton setTitle:[[NSDateComponentsFormatter hhmmssFormatter] stringFromDate:startDate toDate:[NSDate date]] forState:UIControlStateSelected];

		[self setDuration];

		self.timer.enabled = YES;

		//		self.aboutButton.hidden = YES;
		//		self.pressureButton.hidden = YES;
		//		self.settingsButton.hidden = YES;

		if (self.alarmController.view)
			[self setupTodayView:self.alarmController.view];
	} else {
		self.startButton.selected = NO;
		//		self.startStopLabel.text = [GLOBAL button];
		//		self.startStopLabel.textColor = [UIColor whiteColor];
		[self.startButton setTitle:Nil forState:UIControlStateSelected];

		self.timer.enabled = NO;

		//		self.aboutButton.hidden = NO;
		//		self.pressureButton.hidden = NO;//![CMAltimeter isRelativeAltitudeAvailable];
		//		self.settingsButton.hidden = NO;

		WeekdaysController *vc = cls(WeekdaysController, self.parentViewController);

		[vc setupAlertView:^(BOOL hasData) {
			if (!GLOBAL.isAuthorized.boolValue)
				[GCD main:^{
					[self setupTodayView:self.healthKitView];
				}];
			else
				[WIDGET isRegistered:^(BOOL granted) {
					[GCD main:^{
						if (!granted)
							[self setupTodayView:self.notificationsView];
						else if (!hasData)
							[self setupTodayView:self.emptyStateView];
						else if ([UIRateController instance].view)
							[self setupTodayView:[UIRateController instance].view];
						//						else
						//							[self setupTodayView:self.alertView];
					}];
				}];
		}];
	}

	self.navigationItem.prompt = [[NSDate date] descriptionForDate:NSDateFormatterMediumStyle];

	self.startButton.enabled = self.startDate.isToday;
}

- (IBAction)cancel:(UIStoryboardSegue *)segue {
	[AlarmController updateNotification:Nil];
	[WIDGET updateNotification:^(BOOL scheduled) {
		[GCD main:^{
			[self setup];
		}];
	}];
	[WIDGET updateQuickActions];

	[[WatchDelegate instance] sendMessage];
}

- (IBAction)save:(UIStoryboardSegue *)segue {
	[AlarmController updateNotification:Nil];
	[WIDGET updateNotification:^(BOOL scheduled) {
		[GCD main:^{
			[self setup];
		}];
	}];
	[WIDGET updateQuickActions];

	[[WatchDelegate instance] sendMessage];
}

- (IBAction)unwind:(UIStoryboardSegue *)segue {

}

- (void)segueToIntervalController:(id)sender {
	if (!self.startStopButtonTouchDown)
		return;

	self.startStopButtonTouchDown = NO;

	if (![self requestAuthorization])
		return;

	[self performSegueWithIdentifier:GUI_INTERVAL sender:sender];
}

- (IBAction)startStopButtonTouchDown:(UIButton *)sender {
	if (!self.startDate.isToday)
		return;

	self.startStopButtonTouchDown = YES;

	[self performSelector:@selector(segueToIntervalController:) withObject:sender afterDelay:3.0];
}

- (IBAction)startStopButtonTouchUp:(UIButton *)sender {
	if (!self.startDate.isToday)
		return;

	if (GLOBAL.longPress.boolValue || !GLOBAL.asleep)
		[self startStopButtonAction:sender];
	else
		[self segueToIntervalController:sender];
}

- (void)startStopButtonAction:(UIButton *)sender {
	if (!self.startStopButtonTouchDown)
		return;

	self.startStopButtonTouchDown = NO;

	if (![self requestAuthorization])
		return;

	if (GLOBAL.asleep) {
		[GLOBAL endSleeping:^(BOOL success) {
			//			if (!success)
			//				return;

			[AlarmController updateNotification:Nil];
			[WIDGET updateNotification:^(BOOL scheduled) {
				[GCD main:^{
					[self setup];
				}];
			}];
			[WIDGET updateQuickActions];

			[[WatchDelegate instance] sendMessage];
		}];
	} else {
		[GLOBAL startSleeping];

		[AlarmController updateNotification:^(BOOL succcess) {
			[GCD main:^{
				[self.alarmController setupAlarmView];

				[self setup];
			}];
		}];
		[WIDGET updateNotification:Nil];
		[WIDGET updateQuickActions];

		[[WatchDelegate instance] sendMessage];
	}
}

- (void)handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UNNotification *)notification {
	self.startStopButtonTouchDown = YES;

	[self startStopButtonTouchUp:Nil];
}

- (BOOL)requestAuthorization {
	if (!GLOBAL.isAuthorized)
		[GLOBAL requestAuthorization:^(BOOL success) {
			[GCD main:^{
				[self setup];
			}];
		}];
	else if (!GLOBAL.isAuthorized.boolValue)
		[self presentAlertWithTitle:[Localization allowReadAndWriteData] cancelActionTitle:[Localization ok]];

	return GLOBAL.isAuthorized.boolValue;
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
	if (GLOBAL.asleep) {
		if ([shortcutItem.type isEqualToString:GUI_WAKE_UP]) {
			self.startStopButtonTouchDown = YES;

			[self startStopButtonAction:self.startButton];
		}
	} else {
		if ([shortcutItem.type isEqualToString:GUI_FALL_ASLEEP]) {
			self.startStopButtonTouchDown = YES;

			[self startStopButtonAction:self.startButton];
		}
	}
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
	NSData *data = [NSData dataWithContentsOfURL:url];
	NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data];

	NSArray<HKCategorySample *> *samples = [json[@"samples"] map:^id(id obj) {
		return [HKCategorySample categorySampleFromJSON:obj];
	}];

	[url removeItem];

	if (!samples)
		return NO;

	AnalysisController *vc = [[UIStoryboard mainStoryboard] instantiateViewControllerWithIdentifier:@"activity"];
	[vc setSamples:[AnalysisPresenter create:samples unit:NSCalendarUnitWeekday] animated:NO];
	//	vc.leftBarButtonItem.title = Nil;
	vc.navigationItem.title = [samples.lastObject.endDate descriptionForDate:NSDateFormatterMediumStyle];
	[self presentViewController:[[UINavigationController alloc] initWithRootViewController:vc] animated:YES completion:Nil];

	return samples != Nil;
}

@end

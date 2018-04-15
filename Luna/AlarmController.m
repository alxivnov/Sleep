//
//  AlarmController.m
//  Sleep Diary
//
//  Created by Alexander Ivanov on 29.11.15.
//  Copyright © 2015 Alexander Ivanov. All rights reserved.
//

#import "AlarmController.h"
#import "Global.h"
#import "Widget.h"
#import "Localization.h"

#import "UIButton+Convenience.h"

#import "AnalysisPresenter.h"
#import "UIDatePicker+Convenience.h"

#import "NSFormatter+Convenience.h"
#import "NSObject+Convenience.h"
#import "UIColor+Convenience.h"
#import "UILabel+Convenience.h"
#import "UISlider+Convenience.h"
#import "UIView+Convenience.h"
#import "Dispatch+Convenience.h"
#import "UserNotifications+Convenience.h"

//#define IMG_MOON_FULL @"moon-full"
//#define IMG_MOON_LINE @"moon-line"
//#define IMG_SUN_FULL @"sun-full"
//#define IMG_SUN_LINE @"sun-line"
#define IMG_ALARM_FULL @"alarm-full"
#define IMG_ALARM_LINE @"alarm-line"

#define SND_ALARM_1 @"alarm-1.caf"

@interface AlarmController ()
@property (strong, nonatomic) UIView *alarmView;
@property (strong, nonatomic) UIButton *alarmButton;

@property (strong, nonatomic) UIDatePickerController *pickerController;


@property (strong, nonatomic) UIView *cycleView;

@end

#warning Refactor as a child of AlertController!

@implementation AlarmController

#warning Refresh cycle colors on cycle view presentation!

- (UIView *)cycleView {
	if (!_cycleView) {
		UIView *root = self.alarmView.rootview;

		_cycleView = [[UIView alloc] initWithFrame:CGRectMake(0.0, root.bounds.size.height, root.bounds.size.width, UISliderHeight)];

		NSUInteger cycleCount = 7;
		NSTimeInterval seconds = cycleCount * SLEEP_CYCLE_DURATION;
		NSTimeInterval secondsPerPixel = seconds / _cycleView.bounds.size.width;

		UIView *view = [[UIView alloc] initWithFrame:_cycleView.bounds];
		view.backgroundColor = RGB(23, 23, 23);
		[AnalysisPresenter query:NSCalendarUnitDay completion:^(NSArray<AnalysisPresenter *> *presenters) {
			NSUInteger count = presenters.firstObject.cycleCount;

			[GCD main:^{
				CGFloat width = view.bounds.size.width / cycleCount;
				for (NSUInteger index = 0; index < cycleCount; index++) {
					UIView *subview = [[UIView alloc] initWithFrame:CGRectMake(index * width, 0.0, width, view.bounds.size.height)];
					subview.backgroundColor = [GLOBAL.tintColor colorWithAlphaComponent:0.5 + (index + count) * 0.05];
					[view addSubview:subview];
				}
			}];
		}];
		[_cycleView addSubview:view];

		for (NSInteger index = 1; index < seconds / 3600.0; index++) {
			UIView *tick = [[UIView alloc] initWithFrame:CGRectMake(3600.0 * index / secondsPerPixel - 0.5, _cycleView.bounds.size.height - 8.0, 1.0, 8.0)];
			tick.backgroundColor = [UIColor color:HEX_IOS_GRAY];
			[_cycleView addSubview:tick];

			if (index % 2 == 0)
				continue;

			UILabel *label = [[NSString stringWithFormat:@"%lu:00", (long)index] labelWithSize:CGSizeZero options:NSSizeExact attributes:@{ NSForegroundColorAttributeName : [UIColor color:HEX_IOS_LIGHT_GRAY], NSFontAttributeName : [UIFont systemFontOfSize:[UIFont smallSystemFontSize]] }];
			label.frame = CGRectSetOrigin(label.frame, CGPointMake(tick.frame.origin.x - label.frame.size.width / 2.0, 8.0));
			if (label.frame.origin.x > 0.0 && label.frame.origin.x + label.frame.size.width < _cycleView.bounds.size.width)
				[_cycleView addSubview:label];
		}
/*
		[UNUserNotificationCenter getPendingNotificationRequestWithIdentifier:GUI_WAKE_UP completionHandler:^(UNNotificationRequest *request) {
			[GCD main:^{
*/				UISlider *slider = [[UISlider alloc] initWithFrame:_cycleView.bounds];
				[slider hideTrack];
				slider.minimumValue = UISliderHeight / 2.0 * secondsPerPixel;
				slider.maximumValue = seconds - slider.minimumValue;
//				slider.value = [request.nextTriggerDate timeIntervalSinceDate:GLOBAL.startDate];
				[slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
				[_cycleView addSubview:slider];
/*			}];
		}];
*/
		_cycleView.hidden = YES;
		[root addSubview:_cycleView];
	}

	return _cycleView;
}

- (IBAction)sliderValueChanged:(UISlider *)sender {
	NSDate *date = [GLOBAL.startDate dateByAddingTimeInterval:sender.value];

//	[self.alarmButton setTitle:[date descriptionForTime:NSDateFormatterShortStyle]];

//	[[self class] updateNotificationWithDate:date];


	[self.pickerController.datePicker setNullableDate:date];
}

- (UIDatePickerController *)pickerController {
	if (!_pickerController) {
		_pickerController = [[UIDatePickerController alloc] initWithView:self.alarmView.rootview];

		_pickerController.backgroundColor = RGB(23, 23, 23);
		_pickerController.buttonColor = GLOBAL.tintColor;
		_pickerController.pickerColor = [UIColor whiteColor];
		_pickerController.titleColor = [UIColor lightGrayColor];
		
		_pickerController.datePicker.datePickerMode = UIDatePickerModeDateAndTime;
		[_pickerController.doneButton setTitleColor:self.alarmView.superview.backgroundColor];

		__weak AlarmController *__self = self;
		_pickerController.datePickerValueChanged = ^(UIDatePicker *sender, id identifier) {
//			[__self.alarmButton setTitle:[sender.date descriptionForTime:NSDateFormatterShortStyle]];

//			[[__self class] updateNotificationWithDate:sender.date];


			((UISlider *)[__self.cycleView subview:UISubviewKindOfClass(UISlider)]).value = [sender.date timeIntervalSinceDate:GLOBAL.startDate];
		};
		_pickerController.identifierValueChanged = ^(UIDatePicker *sender, id identifier) {
			sender.minimumDate = [NSDate date];
			sender.maximumDate = [sender.minimumDate addValue:1 forComponent:NSCalendarUnitDay];

			if (identifier)
				[AnalysisPresenter query:NSCalendarUnitDay completion:^(NSArray<AnalysisPresenter *> *presenters) {
					[GCD main:^{
						NSDate *date = [GLOBAL alarmDate:presenters];

						[sender setNullableDate:date];

						((UISlider *)[__self.cycleView subview:UISubviewKindOfClass(UISlider)]).value = [date timeIntervalSinceDate:GLOBAL.startDate];
					}];
				}];
			else
				[[__self class] updateNotificationWithDate:sender.date completion:^(BOOL success) {
					[GCD main:^{
						[__self setupAlarmView];
					}];
				}];

			((UISlider *)[__self.cycleView subview:UISubviewKindOfClass(UISlider)]).value = [sender.date timeIntervalSinceDate:GLOBAL.startDate];
			if (identifier)
				__self.cycleView.hidden = NO;
			[UIView animateWithDuration:ANIMATION_DURATION delay:0.0 usingSpringWithDamping:ANIMATION_DAMPING initialSpringVelocity:ANIMATION_VELOCITY options:ANIMATION_OPTIONS animations:^{
				__self.cycleView.frame = CGRectSetY(__self.cycleView.frame, identifier ? __self.pickerController.view.frame.origin.y - __self.cycleView.frame.size.height : __self.alarmView.rootview.bounds.size.height);
			} completion:^(BOOL finished) {
				if (!identifier)
					__self.cycleView.hidden = YES;
			}];
		};
	}

	return _pickerController;
}

- (instancetype)initWithView:(UIView *)view {
	self = [self init];
	
	if (self) {
		self.alarmView = view;
		
		self.alarmButton = (UIButton *)[view subview:UISubviewKindOfClass(UIButton)];
		[self.alarmButton addTarget:self action:@selector(alarmButtonAction:) forControlEvents:UIControlEventTouchUpInside];
//		[self.alarmView.alarmSwitch addTarget:self action:@selector(alarmSwitchAction:) forControlEvents:UIControlEventValueChanged];
		[self setupAlarmView];
	}
	
	return self;
}

- (void)setupAlarmView {
//	[WIDGET isRegistered:^(BOOL registered) {
//		if (registered)
			[UNUserNotificationCenter getPendingNotificationRequestWithIdentifier:GUI_WAKE_UP completionHandler:^(UNNotificationRequest *request) {
				[GCD main:^{
					[self.alarmButton setTitle:request ? [request.nextTriggerDate descriptionForTime:NSDateFormatterShortStyle] : [Localization noAlarm]];
					[self.alarmButton setImage:[UIImage templateImage:request ? /*IMG_SUN_LINE*/IMG_ALARM_FULL : /*IMG_MOON_LINE*/IMG_ALARM_LINE]];
				}];
			}];
//	}];

//	[self.alarmView.alarmButton setImage:[UIImage templateImage:notification ? IMG_SUN_FULL : IMG_MOON_FULL] forState:UIControlStateHighlighted];
//	self.alarmView.alarmSwitch.on = notification != Nil;
}

- (UIView *)view {
	return self.alarmView;
}

- (IBAction)alarmButtonAction:(UIButton *)sender {
	[WIDGET requestRegistration:^(BOOL granted) {
		if (!granted)
			return;

		[UNUserNotificationCenter getPendingNotificationRequestWithIdentifier:GUI_WAKE_UP completionHandler:^(UNNotificationRequest *request) {
			if (request) {
				[UNUserNotificationCenter removePendingNotificationRequestWithIdentifier:request.identifier];

				[GCD main:^{
					[self setupAlarmView];
				}];
			} else {
//				[AnalysisPresenter query:NSCalendarUnitDay completion:^(NSArray<AnalysisPresenter *> *presenters) {
//					[[self class] updateNotificationWithDate:[GLOBAL alarmDate:presenters]];

					[GCD main:^{
						self.pickerController.identifier = /*self.pickerController.identifier ? Nil : */self.alarmView;

//						[self setupAlarmView];
//					}];
				}];
			}
		}];
	}];
}

+ (void)updateNotificationWithDate:(NSDate *)fireDate completion:(void(^)(BOOL))completion {
	if (GLOBAL.asleep) {
		[[UNNotificationContent contentWithTitle:[Localization wakeUpNow] subtitle:Nil body:[Localization wakeUpNowBody] badge:Nil sound:SND_ALARM_1 attachments:arr_([UIImage URLForResource:IMG_LUNA_SUN withExtension:@"png"]) userInfo:Nil categoryIdentifier:GUI_WAKE_UP] scheduleWithIdentifier:GUI_WAKE_UP date:fireDate repeats:NO completion:completion];
	} else {
		[UNUserNotificationCenter removePendingNotificationRequestWithIdentifier:GUI_WAKE_UP];

		if (completion)
			completion(YES);
	}
}

+ (void)updateNotification:(void(^)(BOOL))completion {
	[AnalysisPresenter query:NSCalendarUnitDay completion:^(NSArray<AnalysisPresenter *> *presenters) {
		NSDate *notificationDate = [GLOBAL alarmDate:presenters];
		notificationDate = [GLOBAL.alarmWeekdays[[notificationDate weekday]] boolValue] ? notificationDate : Nil;
		[self updateNotificationWithDate:notificationDate completion:completion];
	}];
}

@end

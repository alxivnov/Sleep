//
//  InterfaceController.m
//  Sleep Diary WatchKit Extension
//
//  Created by Alexander Ivanov on 06.04.15.
//  Copyright (c) 2015 Alexander Ivanov. All rights reserved.
//

#import "InterfaceController.h"
#import "AnalysisPresenter.h"
#import "Global+Notifications.h"
#import "Localization.h"

#import "EDSunriseSet.h"

#import "Defaults.h"
#import "PhoneDelegate.h"

#import "UIBezierPath+Convenience.h"

#import "HKHealthStore+Convenience.h"
#import "NSBundle+Convenience.h"
#import "NSCalendar+Convenience.h"
#import "NSObject+Convenience.h"
#import "UIColor+Convenience.h"
#import "UIImage+Convenience.h"
#import "Dispatch+Convenience.h"
#import "CoreLocation+Convenience.h"
#import "CoreMotion+Convenience.h"
#import "UserNotifications+Convenience.h"
#import "ClockKit+Convenience.h"
#import "WatchKit+Convenience.h"

#define DATA [Defaults instance]

@interface InterfaceController()
@property (weak, nonatomic) IBOutlet WKInterfaceGroup *group;
@property (weak, nonatomic) IBOutlet WKInterfaceTimer *timer;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *label;

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceImage *leftImage;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *leftLabel;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceImage *rightImage;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *rightLabel;

@property (strong, nonatomic) NSArray<AnalysisPresenter *> *presenters;
@property (strong, nonatomic) HKObserverQuery *observer;

@property (strong, nonatomic) NSDate *labelDate;
@end

@implementation InterfaceController

- (void)setup {
	self.observer = [AnalysisPresenter observe:NSCalendarUnitWeekOfMonth updateHandler:^(NSArray<AnalysisPresenter *> *presenters) {
		[GCD main:^{
			self.presenters = presenters;

			[[CLKComplicationServer sharedInstance] reloadTimeline:Nil];
		}];
	}];

	[[CMMotionActivityManager defaultManager] getActivity:Nil];
}

- (void)setObserver:(HKObserverQuery *)observer {
	[[HKHealthStore defaultStore] stopQuery:_observer];

	_observer = observer;
}

- (void)setPresenters:(NSArray<AnalysisPresenter *> *)presenters {
	_presenters = presenters;

	AnalysisPresenter *today = presenters.firstObject;
	if (!today.endDate.isToday || (DATA.asleep && [[NSDate date] timeComponent] > 22.0 * TIME_HOUR))
		today = Nil;

	[self.group setBackgroundImage:[UIImage imageWithSize:[WKInterfaceDevice currentDevice].screenBounds.size opaque:NO draw:^(CGContextRef context) {
		CGRect frame = CGRectInset([WKInterfaceDevice currentDevice].screenBounds, 8.0, 8.0);

		if (DATA.asleep) {
			[GLOBAL.tintColor setFill];
			[[UIBezierPath bezierPathWithArcFrame:frame width:0.0 start:0.0 end:1.0 lineCap:kCGLineCapRound lineJoin:kCGLineJoinRound] fill];
		}

		[RGB(29, 26, 102) setStroke];
		[[UIBezierPath bezierPathWithArcFrame:frame width:-(64.0 / 580.0) start:0.0 end:1.0 lineCap:kCGLineCapRound lineJoin:kCGLineJoinRound] stroke];

		[(DATA.asleep ? [UIColor whiteColor] : GLOBAL.tintColor) setStroke];
		[[UIBezierPath bezierPathWithArcFrame:frame width:-(64.0 / 580.0) start:0.0 end:today.duration / GLOBAL.sleepDuration lineCap:kCGLineCapRound lineJoin:kCGLineJoinRound] stroke];
	}]];

	if (DATA.asleep) {
		[self.timer setDate:DATA.startDate];
		[self.timer start];
	} else {
		[self.timer setInterval:today.duration];
		[self.timer stop];
	}
	[self.timer setTextColor:presenters ? DATA.asleep ? [UIColor whiteColor] : GLOBAL.tintColor : DATA.asleep ? GLOBAL.tintColor : [UIColor blackColor]];

	[self.label setText:[DATA.asleep ? [Localization wakeUp] : [Localization fallAsleep] lowercaseString]];
	[self.label setTextColor:presenters ? DATA.asleep ? [UIColor lightGrayColor] : GLOBAL.tintColor : DATA.asleep ? GLOBAL.tintColor : [UIColor blackColor]];

	CLLocation *location = [CLLocationManager defaultManager].location;
	if (location) {
		EDSunriseSet *x = [EDSunriseSet sunrisesetWithDate:[NSDate date] timezone:[NSCalendar currentCalendar].timeZone latitude:location.coordinate.latitude longitude:location.coordinate.longitude];
		if (x.sunset.isPast)
			x = [EDSunriseSet sunrisesetWithDate:[x.date addValue:1 forComponent:NSCalendarUnitDay] timezone:[NSCalendar currentCalendar].timeZone latitude:location.coordinate.latitude longitude:location.coordinate.longitude];
		[self.leftImage setImageNamed:x.sunrise.isFuture ? IMG_SUNRISE : IMG_SUNSET];
		[self.leftLabel setText:[x.sunrise.isFuture ? x.sunrise : x.sunset descriptionForTime:NSDateFormatterShortStyle]];
		[self.leftLabel setTextColor:[UIColor lightGrayColor]];
	} else {
		[self.leftImage setImageNamed:DATA.asleep ? IMG_MOON_FILL : IMG_SUN_FILL];
		[self.leftLabel setText:presenters ? [(DATA.asleep ? DATA.startDate : today.endDate) descriptionForTime:NSDateFormatterShortStyle] : @"0:00"];
		[self.leftLabel setTextColor:presenters ? [UIColor lightGrayColor] : [UIColor blackColor]];
	}


	[self setupRightLabel:self.labelDate ? self.labelDate : presenters ? DATA.asleep ? [GLOBAL alarmDate:presenters] : [GLOBAL alertDate:presenters] : Nil image:DATA.asleep ? IMG_SUN_LINE : IMG_MOON_LINE];

	[UNUserNotificationCenter getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> *requests) {
		UNNotificationRequest *request = DATA.asleep ? [requests firstObject:^BOOL(UNNotificationRequest *obj) {
			return [obj.identifier isEqualToString:GUI_WAKE_UP];
		}] : [requests firstObject:^BOOL(UNNotificationRequest *obj) {
			return [obj.identifier isEqualToString:GUI_FALL_ASLEEP];
		}];

		if (request.nextTriggerDate)
			[GCD main:^{
				[self setupRightLabel:request.nextTriggerDate image:DATA.asleep ? IMG_SUN_FILL : IMG_MOON_FILL];
			}];
		else
			[[PhoneDelegate instance].reachableSession sendMessage:@{ STR_UNDERSCORE : DATA.asleep ? GUI_WAKE_UP : GUI_FALL_ASLEEP } replyHandler:^(NSDictionary<NSString *,id> *replyMessage) {
				if (replyMessage[GUI_WAKE_UP])
					[GCD main:^{
						[self setupRightLabel:[NSDate deserialize:replyMessage[GUI_WAKE_UP]] image:Nil];
					}];
				else if (replyMessage[GUI_FALL_ASLEEP])
					[GCD main:^{
						[self setupRightLabel:[NSDate deserialize:replyMessage[GUI_FALL_ASLEEP]] image:Nil];
					}];
			}];
	}];

#warning Allow switching on and off.
}

- (void)setupRightLabel:(NSDate *)labelDate image:(NSString *)imageName {
	self.labelDate = labelDate;

	NSString *text = labelDate ? [labelDate descriptionForTime:NSDateFormatterShortStyle] : @"0:00";
	[self.rightLabel setText:text];

	UIColor *textColor = labelDate ? [UIColor lightGrayColor] : [UIColor blackColor];
	[self.rightLabel setTextColor:textColor];

	if (imageName)
		[self.rightImage setImageNamed:imageName];
}

- (void)awakeWithContext:(id)context {
	[super awakeWithContext:context];

    // Configure interface objects here.

	self.presenters = Nil;

	if (IS_DEBUGGING)
		[self setTitle:[NSBundle bundleVersion]];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];

	if (GLOBAL.isAuthorized.boolValue) {
		[self setup];

		[self autodetect];
	}/* else if (GLOBAL.isAuthorized) {
		return;
	} */else {
		[GLOBAL requestAuthorization:^(BOOL success) {
			if (success) {
				[self setup];

				[self autodetect];
			}
		}];
	}
/*
	[self setup];
	[[PhoneDelegate instance].reachableSession sendMessage:@{ } replyHandler:^(NSDictionary<NSString *,id> *replyMessage) {
		[[MessageCache instance] loadDictionary:replyMessage];

		[GCD main:^{
			[self setup];
		}];

		[[CLKComplicationServer sharedInstance] reloadComplication:Nil];
	}];
*/
	[PhoneDelegate instance].didReceiveMessage = ^(NSDictionary<NSString *,id> *message, void (^replyHandler)(NSDictionary<NSString *,id> *replyMessage)) {
//		[[MessageCache instance] loadDictionary:message];

		if (!message[KEY_TIMER_START])
			return;

		DATA.startDate = [NSDate deserialize:message[KEY_TIMER_START]];
		[GCD main:^{
			[self setup];
		}];

		[[CLKComplicationServer sharedInstance] reloadTimeline:Nil];
	};
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];

	self.observer = Nil;
}

- (IBAction)buttonTouch {
	DATA.asleep = !DATA.asleep;

	self.labelDate = Nil;

//	if (DATA.asleep)
		self.presenters = self.presenters;

	[[CLKComplicationServer sharedInstance] reloadTimeline:Nil];

	[[PhoneDelegate instance].reachableSession sendMessage:@{ KEY_TIMER_START : [DATA.startDate serialize] ?: STR_EMPTY } replyHandler:^(NSDictionary<NSString *,id> *replyMessage) {
//		[[MessageCache instance] loadDictionary:replyMessage];

		if (!replyMessage[KEY_TIMER_START])
			return;

		DATA.startDate = [NSDate deserialize:replyMessage[KEY_TIMER_START]];
		[GCD main:^{
			[self setup];
		}];

		[[CLKComplicationServer sharedInstance] reloadTimeline:Nil];
	}];
}

- (void)autodetect {
	if (DATA.asleep)
		return;

	if (![CMMotionActivityManager isActivityAvailable])
		return;

	NSDate *endDate = [NSDate date];
	NSDate *startDate = [endDate addValue:-1 forComponent:NSCalendarUnitDay];
	NSTimeInterval sleepLatency = GLOBAL.sleepLatency;

	if ([DATA.autodetectDate isGreaterThan:startDate])
		startDate = DATA.autodetectDate;

	[HKSleepAnalysis querySampleWithStartDate:startDate endDate:endDate completion:^(__kindof HKSample *sample) {
		[CMMotionActivitySample queryActivityStartingFromDate:sample.endDate ?: startDate toDate:endDate within:sleepLatency withHandler:^(NSArray<CMMotionActivitySample *> *activities) {
			if (!activities.count)
				return;

			NSArray<HKCategorySample *> *samples = [HKSleepAnalysis samplesWithStartDate:sample.endDate ?: startDate endDate:endDate activities:activities sleepLatency:-sleepLatency adaptive:NO];
			if (!samples.count)
				return;

			NSTimeInterval maxDuration = 0.0;
			NSUInteger maxIndex = NSNotFound;
			for (NSUInteger index = 0; index < samples.count; index++) {
				NSTimeInterval duration = [samples[index] duration];
				if (duration > maxDuration) {
					maxDuration = duration;

					maxIndex = index;
				}
			}

			NSUInteger firstIndex = maxIndex;
			while (firstIndex > 0 && samples[firstIndex - 1].endDate.timeIntervalSinceReferenceDate >= samples[firstIndex].startDate.timeIntervalSinceReferenceDate - sleepLatency)
				firstIndex--;

			NSUInteger lastIndex = maxIndex;
			while (lastIndex < samples.count - 1 && samples[lastIndex].endDate.timeIntervalSinceReferenceDate >= samples[lastIndex + 1].startDate.timeIntervalSinceReferenceDate - sleepLatency)
				lastIndex++;

			NSDate *start = [samples[firstIndex].startDate dateByAddingTimeInterval:0.0 - sleepLatency];
			if ([start isLessThan:sample.endDate ?: startDate])
				start = sample.endDate ?: startDate;
			NSDate *end = [[samples[lastIndex].endDate component:NSCalendarUnitMinute] addValue:1 forComponent:NSCalendarUnitMinute];
			[self presentControllerWithName:KEY_AUTODETECT context:@[ start, end ]];

			[Defaults instance].autodetectDate = end;
		}];
	}];
}

- (IBAction)rightLabelTap:(id)sender {
	[UNUserNotificationCenter getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> *requests) {
		NSString *identifier = DATA.asleep ? GUI_WAKE_UP : GUI_FALL_ASLEEP;
		UNNotificationRequest *request = [requests firstObject:^BOOL(UNNotificationRequest *obj) {
			return [obj.identifier isEqualToString:identifier];
		}];

		if (request) {
			[UNUserNotificationCenter removePendingNotificationRequestWithIdentifier:request.identifier];

			[GCD main:^{
				[self setupRightLabel:self.labelDate image:DATA.asleep ? IMG_SUN_LINE : IMG_MOON_LINE];
			}];
		} else {
			if (GLOBAL.asleep)
				[[UNNotificationContent contentWithTitle:[Localization wakeUpNow] subtitle:Nil body:[Localization wakeUpNowBody] badge:Nil sound:STR_EMPTY attachments:arr_([UIImage URLForResource:IMG_LUNA_SUN withExtension:@"png"]) userInfo:Nil categoryIdentifier:GUI_WAKE_UP] scheduleWithIdentifier:GUI_WAKE_UP date:self.labelDate repeats:NO completion:^(BOOL success) {
					if (success)
						[GCD main:^{
							[self setupRightLabel:self.labelDate image:IMG_SUN_FILL];
						}];
				}];
			else
				[[UNNotificationContent contentWithTitle:[Localization goToSleep] subtitle:Nil body:[Localization goToSleepBody] badge:Nil sound:STR_EMPTY attachments:arr_([UIImage URLForResource:IMG_LUNA_MOON withExtension:@"png"]) userInfo:Nil categoryIdentifier:GUI_FALL_ASLEEP] scheduleWithIdentifier:GUI_FALL_ASLEEP date:self.labelDate repeats:NO completion:^(BOOL success) {
					if (success)
						[GCD main:^{
							[self setupRightLabel:self.labelDate image:IMG_MOON_FILL];
						}];
				}];
		}
	}];
}

@end




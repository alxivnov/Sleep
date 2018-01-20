//
//  Global.m
//  Sleep Diary
//
//  Created by Alexander Ivanov on 06.04.15.
//  Copyright (c) 2015 Alexander Ivanov. All rights reserved.
//

#import "Global.h"

#import "NSRateController.h"

#define APP_GROUP @"group.alexivanov.luna"

#define KEY_BEDTIME_ALERT @"bedtimeAlert"
#define KEY_SLEEP_DURATION @"sleepDuration"

#define KEY_WAKE_UP_TIME @"wakeUpTime"
#define KEY_WAKE_UP_WEEKDAYS @"wakeUpWeekdays"

#define KEY_SLEEP_LATENCY @"sleepLatency"

#define KEY_LONG_PRESS @"langPress"

#define KEY_ACTIVITY_SCALE @"activityScale"

#import "Affiliates+Convenience.h"
#import "NSDictionary+Convenience.h"
#import "UIColor+Convenience.h"

@interface Global ()
@property (strong, nonatomic, readonly) NSUserDefaults *defaults;

@end

@implementation Global

- (NSNumber *)isAuthorized {
	return [HKSleepAnalysis isAuthorized];
}

- (void)requestAuthorization:(void (^)(BOOL))completion {
	[[HKHealthStore defaultStore] requestAuthorizationToShare:@[ HKCategoryTypeIdentifierSleepAnalysis ] read:@[ HKCategoryTypeIdentifierSleepAnalysis, HKQuantityTypeIdentifierHeartRate, HKQuantityTypeIdentifierStepCount,HKQuantityTypeIdentifierActiveEnergyBurned ] completion:completion];
}

- (void)saveSampleWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate completion:(void(^)(BOOL))completion {
	if (!self.asleep && !(startDate && endDate))
		return;

//	start = start ? start : self.startDate;
//	end = end ? end : [NSDate date];
	if ([CMMotionActivityManager isActivityAvailable])
		[CMMotionActivitySample queryActivityStartingFromDate:startDate toDate:endDate within:self.sleepLatency withHandler:^(NSArray<CMMotionActivitySample *> *activities) {
			[HKSleepAnalysis saveSampleWithStartDate:startDate endDate:endDate activities:activities sleepLatency:GLOBAL.sleepLatency adaptive:YES completion:completion];
		}];
	else
		[HKActiveEnergy queryActivityStartingFromDate:startDate toDate:endDate /*within:self.sleepLatency*/ withHandler:^(NSArray<CMMotionActivitySample *> *activities) {
			[HKSleepAnalysis saveSampleWithStartDate:startDate endDate:endDate activities:activities sleepLatency:GLOBAL.sleepLatency adaptive:YES completion:completion];
		}];
}



__synthesize(NSUserDefaults *, defaults, [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP])

- (NSDate *)startDate {
	return [self.defaults objectForKey:KEY_TIMER_START];
}

- (void)setStartDate:(NSDate *)startDate {
	[self.defaults setObject:startDate forKey:KEY_TIMER_START];
}

- (BOOL)asleep {
	return self.startDate != Nil;
}

- (void)startSleeping {
	self.startDate = [NSDate date];
}

- (void)endSleeping {
	self.startDate = Nil;
}

- (void)endSleeping:(void (^)(BOOL))completion {
	NSDate *startDate = self.startDate;
	NSDate *endDate = [NSDate date];

	[self endSleeping];

	[self saveSampleWithStartDate:startDate endDate:endDate completion:completion];
}



- (BOOL)bedtimeAlert {
	NSNumber *bedtimeAlert = [[NSUserDefaults standardUserDefaults] objectForKey:KEY_BEDTIME_ALERT];
	return bedtimeAlert ? [bedtimeAlert boolValue] : YES;
}

- (void)setBedtimeAlert:(BOOL)bedtimeAlert {
	[[NSUserDefaults standardUserDefaults] setObject:@(bedtimeAlert) forKey:KEY_BEDTIME_ALERT];
}

- (NSTimeInterval)sleepDuration {
	NSNumber *sleepDuration = [[NSUserDefaults standardUserDefaults] objectForKey:KEY_SLEEP_DURATION];
	return sleepDuration ? [sleepDuration doubleValue] : 8.0 * TIME_HOUR;
}

- (void)setSleepDuration:(NSTimeInterval)sleepDuration {
	[[NSUserDefaults standardUserDefaults] setObject:@(sleepDuration) forKey:KEY_SLEEP_DURATION];
}

- (NSArray<NSNumber *> *)alarmWeekdays {
	NSArray<NSNumber *> *alarmWeekdays = [[NSUserDefaults standardUserDefaults] objectForKey:KEY_WAKE_UP_WEEKDAYS];
	return alarmWeekdays ? alarmWeekdays : @[ @NO, @YES, @YES, @YES, @YES, @YES, @NO ];
}

- (void)setAlarmWeekdays:(NSArray<NSNumber *> *)alarmWeekdays {
	[[NSUserDefaults standardUserDefaults] setObject:alarmWeekdays forKey:KEY_WAKE_UP_WEEKDAYS];
}

- (NSTimeInterval)alarmTime {
	NSNumber *alarmTime = [[NSUserDefaults standardUserDefaults] objectForKey:KEY_WAKE_UP_TIME];
	return alarmTime ? [alarmTime doubleValue] : 8 * TIME_HOUR;
}

- (void)setAlarmTime:(NSTimeInterval)alarmTime {
	[[NSUserDefaults standardUserDefaults] setObject:@(alarmTime) forKey:KEY_WAKE_UP_TIME];
}

- (NSTimeInterval)sleepLatency {
	NSNumber *sleepLatency = [[NSUserDefaults standardUserDefaults] objectForKey:KEY_SLEEP_LATENCY];
	return sleepLatency ? sleepLatency.doubleValue : 10.0 * TIME_MINUTE;
}

- (void)setSleepLatency:(NSTimeInterval)sleepLatency {
	[[NSUserDefaults standardUserDefaults] setObject:@(sleepLatency) forKey:KEY_SLEEP_LATENCY];
}

- (NSNumber *)longPress {
	return [[NSUserDefaults standardUserDefaults] objectForKey:KEY_LONG_PRESS];
}

- (void)setLongPress:(NSNumber *)longPress {
	[[NSUserDefaults standardUserDefaults] setObject:longPress forKey:KEY_LONG_PRESS];
}

- (BOOL)scale {
	return [[NSUserDefaults standardUserDefaults] boolForKey:KEY_ACTIVITY_SCALE];
}

- (void)setScale:(BOOL)scale {
	[[NSUserDefaults standardUserDefaults] setBool:scale forKey:KEY_ACTIVITY_SCALE];
}



static id _instance;

+ (instancetype)instance {
	@synchronized(self) {
		if (!_instance)
			_instance = [self new];
	}
	
	return _instance;
}

- (UIColor *)tintColor {
	return [UIColor color:0x3F3AAB];
}

__synthesize(NSDictionary *, affiliateInfo, [[NSDictionary dictionaryWithProvider:@"10603809" affiliate:@"1l3voBu"] dictionaryWithObject:@"write-review" forKey:@"action"])

@end

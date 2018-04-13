//
//  Settings.m
//  Sleep Diary
//
//  Created by Alexander Ivanov on 13.04.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "Settings.h"

#define KEY_BEDTIME_ALERT @"bedtimeAlert"
#define KEY_SLEEP_DURATION @"sleepDuration"

#define KEY_WAKE_UP_TIME @"wakeUpTime"
#define KEY_WAKE_UP_WEEKDAYS @"wakeUpWeekdays"

#define KEY_SLEEP_LATENCY @"sleepLatency"

@interface Settings ()
@property (strong, nonatomic, readonly) NSUserDefaults *defaults;
@end

@implementation Settings

__synthesize(NSUserDefaults *, defaults, [NSUserDefaults standardUserDefaults])

- (NSDate *)startDate {
	return [self.defaults objectForKey:KEY_TIMER_START];
}

- (void)setStartDate:(NSDate *)startDate {
	[self.defaults setObject:startDate forKey:KEY_TIMER_START];
}

- (BOOL)bedtimeAlert {
	NSNumber *bedtimeAlert = [[NSUserDefaults standardUserDefaults] objectForKey:KEY_BEDTIME_ALERT];
	return bedtimeAlert == Nil ? YES : [bedtimeAlert boolValue];
}

- (void)setBedtimeAlert:(BOOL)bedtimeAlert {
	[[NSUserDefaults standardUserDefaults] setObject:@(bedtimeAlert) forKey:KEY_BEDTIME_ALERT];
}

- (NSTimeInterval)sleepDuration {
	NSNumber *sleepDuration = [[NSUserDefaults standardUserDefaults] objectForKey:KEY_SLEEP_DURATION];
	return sleepDuration == Nil ? 8.0 * TIME_HOUR : [sleepDuration doubleValue];
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
	return alarmTime == Nil ? 8.0 * TIME_HOUR : [alarmTime doubleValue];
}

- (void)setAlarmTime:(NSTimeInterval)alarmTime {
	[[NSUserDefaults standardUserDefaults] setObject:@(alarmTime) forKey:KEY_WAKE_UP_TIME];
}

- (NSTimeInterval)sleepLatency {
	NSNumber *sleepLatency = [[NSUserDefaults standardUserDefaults] objectForKey:KEY_SLEEP_LATENCY];
	return sleepLatency == Nil ? 10.0 * TIME_MINUTE : sleepLatency.doubleValue;
}

- (void)setSleepLatency:(NSTimeInterval)sleepLatency {
	[[NSUserDefaults standardUserDefaults] setObject:@(sleepLatency) forKey:KEY_SLEEP_LATENCY];
}


- (void)saveSampleWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate completion:(void(^)(BOOL))completion {
	NSTimeInterval sleepLatency = self.sleepLatency;
	BOOL adaptive = YES;

	if ([CMMotionActivityManager isActivityAvailable])
		[CMMotionActivitySample queryActivityStartingFromDate:startDate toDate:endDate within:sleepLatency withHandler:^(NSArray<CMMotionActivitySample *> *activities) {
			[HKDataSleepAnalysis saveSampleWithStartDate:startDate endDate:endDate activities:activities sleepLatency:sleepLatency adaptive:adaptive completion:completion];
		}];
	else
		[HKActiveEnergy queryActivityStartingFromDate:startDate toDate:endDate /*within:sleepLatency*/ withHandler:^(NSArray<CMMotionActivitySample *> *activities) {
			[HKDataSleepAnalysis saveSampleWithStartDate:startDate endDate:endDate activities:activities sleepLatency:sleepLatency adaptive:adaptive completion:completion];
		}];
}


#warning Suggest wake up time which considers suggested duration of sleep (instead of GLOBAL.sleepDuration) and suggested fall asleep time (insted of 22.0 * TIME_HOUR [think about another usage of 22.0 * TIME_HOUR]) based on week samples!

- (NSDate *)alarmDate:(NSArray<AnalysisPresenter *> *)presenters {
	AnalysisPresenter *presenter = presenters.firstObject;

	if (presenter) {
		NSInteger cycleCount = lround(self.sleepDuration / SLEEP_CYCLE_DURATION) - presenter.cycleCount;
		NSTimeInterval napTime = (cycleCount > 0 ? cycleCount : 1) * SLEEP_CYCLE_DURATION + self.sleepLatency;
		if ([self.startDate timeComponent] + napTime < 22.0 * TIME_HOUR)
			return [self.startDate dateByAddingTimeInterval:napTime];
	}

	NSDate *date = [[[NSDate date] dateComponent] dateByAddingTimeInterval:self.alarmTime];
	while ([date isPast])
		date = [date addValue:1 forComponent:NSCalendarUnitDay];

	NSDate *temp = [self.startDate addValue:15 forComponent:NSCalendarUnitMinute];
	while ([temp isLessThanOrEqual:date])
		temp = [temp addValue:90 forComponent:NSCalendarUnitMinute];
	temp = [temp addValue:0 - 90 forComponent:NSCalendarUnitMinute];
	if ([temp isGreaterThanOrEqual:[date addValue:0 - 30 forComponent:NSCalendarUnitMinute]])
		date = temp;

	return date.isPast ? Nil : date;
}

- (NSDate *)alertDate:(NSArray<AnalysisPresenter *> *)presenters {
	NSTimeInterval avgEndTime = [presenters avgEndTime];
	NSTimeInterval avgDuration = [presenters avgDuration];

	NSDate *today = [NSDate today];
	NSDate *tomorrow = [NSDate tomorrow];

	NSDate *date = [today dateByAddingTimeInterval:[idx(self.alarmWeekdays, [today weekday]) boolValue] || avgEndTime <= 0.0 ? self.alarmTime : avgEndTime];
	if (!date.isFuture)
		date = [tomorrow dateByAddingTimeInterval:[idx(self.alarmWeekdays, [tomorrow weekday]) boolValue] || avgEndTime <= 0.0 ? self.alarmTime : avgEndTime];

	date = [date dateByAddingTimeInterval:0.0 - self.sleepDuration - self.sleepLatency];
	if (avgDuration > 0.0 && avgDuration < self.sleepDuration)
		date = [date dateByAddingTimeInterval:avgDuration - self.sleepDuration];

	return /*date.isPast ? Nil : */date;
}

@end

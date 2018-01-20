//
//  Global+Notifications.m
//  Sleep Diary
//
//  Created by Alexander Ivanov on 01.10.16.
//  Copyright © 2016 Alexander Ivanov. All rights reserved.
//

#import "Global+Notifications.h"
#import "NSArray+AnalysisPresenter.h"

#import "NSCalendar+Convenience.h"
#import "NSObject+Convenience.h"

@implementation Global (Notifications)

#warning Suggest wake up time which considers suggested duration of sleep (instead of GLOBAL.sleepDuration) and suggested fall asleep time (insted of 22.0 * TIME_HOUR [think about another usage of 22.0 * TIME_HOUR]) based on week samples!

- (NSDate *)alarmDate:(NSArray<AnalysisPresenter *> *)presenters {
	AnalysisPresenter *presenter = presenters.firstObject;

	if (presenter) {
		NSInteger cycleCount = lround(GLOBAL.sleepDuration / SLEEP_CYCLE_DURATION) - presenter.cycleCount;
		NSTimeInterval napTime = (cycleCount > 0 ? cycleCount : 1) * SLEEP_CYCLE_DURATION + self.sleepLatency;
		if ([GLOBAL.startDate timeComponent] + napTime < 22.0 * TIME_HOUR)
			return [GLOBAL.startDate dateByAddingTimeInterval:napTime];
	}

	NSDate *date = [[[NSDate date] dateComponent] dateByAddingTimeInterval:GLOBAL.alarmTime];
	while ([date isPast])
		date = [date addValue:1 forComponent:NSCalendarUnitDay];

	NSDate *temp = [GLOBAL.startDate addValue:15 forComponent:NSCalendarUnitMinute];
	while ([temp isLessThanOrEqual:date])
		temp = [temp addValue:90 forComponent:NSCalendarUnitMinute];
	temp = [temp addValue:0 - 90 forComponent:NSCalendarUnitMinute];
	if ([temp isGreaterThanOrEqual:[date addValue:0 - 30 forComponent:NSCalendarUnitMinute]])
		date = temp;

	return date.isPast ? Nil : date;
}

- (NSDate *)wakeUpTimeForDate:(NSDate *)date avgWakeUpTime:(NSTimeInterval)avgWakeUpTime {
	return [[date dateComponent] dateByAddingTimeInterval:[idx(self.alarmWeekdays, [date weekday]) boolValue] || avgWakeUpTime <= 0.0 ? self.alarmTime : avgWakeUpTime];
}

- (NSDate *)alertDate:(NSArray<AnalysisPresenter *> *)presenters {
	NSTimeInterval avgEndTime = [presenters avgEndTime];
	NSTimeInterval avgDuration = [presenters avgDuration];

	NSDate *date = [self wakeUpTimeForDate:[NSDate today] avgWakeUpTime:avgEndTime];
	if (!date.isFuture)
		date = [self wakeUpTimeForDate:[NSDate tomorrow] avgWakeUpTime:avgEndTime];

	date = [date dateByAddingTimeInterval:0.0 - self.sleepDuration - self.sleepLatency];
	if (avgDuration > 0.0 && avgDuration < self.sleepDuration)
		date = [date dateByAddingTimeInterval:avgDuration - self.sleepDuration];

	return /*date.isPast ? Nil : */date;
}

@end

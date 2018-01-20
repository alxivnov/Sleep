//
//  Defaults.m
//  Sleep Diary
//
//  Created by Alexander Ivanov on 12.10.16.
//  Copyright © 2016 Alexander Ivanov. All rights reserved.
//

#import "Defaults.h"
#import "Global.h"

#import "HKActiveEnergy+CMMotionActivitySample.h"
#import "HKSleepAnalysis+CMMotionActivitySample.h"
#import "NSObject+Convenience.h"

#define KEY_START_DATE @"startDate"

@interface Defaults ()
@property (strong, nonatomic, readonly) NSUserDefaults *defaults;

@property (assign, nonatomic, readonly) NSTimeInterval sleepLatency;
@end

@implementation Defaults

__synthesize(NSUserDefaults *, defaults, [NSUserDefaults standardUserDefaults])

__synthesize(NSTimeInterval, sleepLatency, GLOBAL.sleepLatency)

- (NSDate *)autodetectDate {
	return [self.defaults objectForKey:KEY_AUTODETECT];
}

- (void)setAutodetectDate:(NSDate *)autodetectDate {
	[self.defaults setObject:autodetectDate forKey:KEY_AUTODETECT];
}

- (NSDate *)startDate {
	return [self.defaults objectForKey:KEY_START_DATE];
}

- (void)setStartDate:(NSDate *)startDate {
	[self.defaults setObject:startDate forKey:KEY_START_DATE];
}

- (BOOL)asleep {
	return self.startDate;
}

- (void)setAsleep:(BOOL)asleep {
	NSDate *startDate = self.startDate;
	NSDate *endDate = [NSDate date];

	self.startDate = asleep ? endDate : Nil;

	if (!startDate)
		return;

	[[self class] saveSampleWithStartDate:startDate endDate:endDate sleepLatency:self.sleepLatency adaptive:YES completion:Nil];
}

+ (void)saveSampleWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate sleepLatency:(NSTimeInterval)sleepLatency adaptive:(BOOL)adaptive completion:(void(^)(BOOL))completion {
	if ([CMMotionActivityManager isActivityAvailable])
		[CMMotionActivitySample queryActivityStartingFromDate:startDate toDate:endDate within:sleepLatency withHandler:^(NSArray<CMMotionActivitySample *> *activities) {
			[HKSleepAnalysis saveSampleWithStartDate:startDate endDate:endDate activities:activities sleepLatency:sleepLatency adaptive:adaptive completion:completion];
		}];
	else
		[HKActiveEnergy queryActivityStartingFromDate:startDate toDate:endDate /*within:sleepLatency*/ withHandler:^(NSArray<CMMotionActivitySample *> *activities) {
			[HKSleepAnalysis saveSampleWithStartDate:startDate endDate:endDate activities:activities sleepLatency:sleepLatency adaptive:adaptive completion:completion];
		}];
}

__static(Defaults *, instance, [self new])

@end

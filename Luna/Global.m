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

#define KEY_LONG_PRESS @"langPress"

#define KEY_ACTIVITY_SCALE @"activityScale"

#import "Affiliates+Convenience.h"
#import "NSDictionary+Convenience.h"
#import "UIColor+Convenience.h"

@interface Global ()

@end

@implementation Global

- (NSNumber *)isAuthorized {
	return [HKDataSleepAnalysis isAuthorized];
}

- (void)requestAuthorization:(void (^)(BOOL))completion {
	[[HKHealthStore defaultStore] requestAuthorizationToShare:@[ HKCategoryTypeIdentifierSleepAnalysis ] read:@[ HKCategoryTypeIdentifierSleepAnalysis, HKQuantityTypeIdentifierHeartRate, HKQuantityTypeIdentifierStepCount,HKQuantityTypeIdentifierActiveEnergyBurned ] completion:completion];
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

//
//  HKSleepAnalysis+CMMotionActivitySample.h
//  Sleep Diary
//
//  Created by Alexander Ivanov on 01.12.16.
//  Copyright © 2016 Alexander Ivanov. All rights reserved.
//

#import "HKData.h"
#import "Accelerate+Convenience.h"
#import "CMMotionActivitySample.h"
#import "NSCalendar+Convenience.h"

#define HKMetadataKeyActivities @"HKMetadataKeyActivities"
#define HKMetadataKeySampleActivities @"HKMetadataKeySampleActivities"
#define HKMetadataKeySleepOnsetLatency @"HKMetadataKeySleepOnsetLatency"

@interface HKSleepAnalysis (CMMotionActivitySample)

+ (NSArray<HKCategorySample *> *)samplesWithStartDate:(NSDate *)start endDate:(NSDate *)end activities:(NSArray<CMMotionActivitySample *> *)activities sleepLatency:(NSTimeInterval)sleepLatency adaptive:(BOOL)adaptive;

+ (void)saveSampleWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate activities:(NSArray<CMMotionActivitySample *> *)activities sleepLatency:(NSTimeInterval)sleepLatency adaptive:(BOOL)adaptive completion:(void(^)(BOOL))completion;

@end

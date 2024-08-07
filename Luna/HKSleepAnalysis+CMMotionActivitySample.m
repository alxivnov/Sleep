//
//  HKSleepAnalysis+CMMotionActivitySample.m
//  Sleep Diary
//
//  Created by Alexander Ivanov on 01.12.16.
//  Copyright © 2016 Alexander Ivanov. All rights reserved.
//

#import "HKSleepAnalysis+CMMotionActivitySample.h"

@implementation HKDataSleepAnalysis (CMMotionActivitySample)

+ (HKCategorySample *)sampleFromActivities:(NSArray<CMMotionActivitySample *> *)activities sleepLatency:(NSTimeInterval)sleepLatency {
	CMMotionActivitySample *first = [activities firstObject:^BOOL(CMMotionActivitySample *obj) {
		return obj.duration >= sleepLatency;
	}];
//	NSTimeInterval duration = [[/*[*/activities/* subarrayWithRange:NSMakeRange(first, activities.count - first)]*/ query:^BOOL(CMMotionActivitySample *obj) {
//		return obj.duration < sleepLatency;
//	}] vAvg:^NSNumber *(CMMotionActivitySample *obj) {
//		return obj.type == CMMotionActivityTypeStationary && obj.confidence == CMMotionActivityConfidenceHigh ? @(obj.duration) : Nil;
//	}];
	NSArray<NSNumber *> *quartiles = [activities quartiles:^NSNumber *(CMMotionActivitySample *obj) {
		return obj.type == CMMotionActivityTypeStationary && obj.confidence == CMMotionActivityConfidenceHigh ? @(obj.duration) : Nil;
	}];
	double q1 = quartiles[1].isNotANumber ? 0.0 : quartiles[1].doubleValue;
	double duration = q1 * sleepLatency / TIME_MINUTE;
	CMMotionActivitySample *last = [activities lastObject:^BOOL(CMMotionActivitySample *obj) {
		return obj.duration >= duration;
	}];

	return first && last && [last.endDate timeIntervalSinceDate:first.startDate] > sleepLatency ? [HKDataSleepAnalysis sampleWithStartDate:first.startDate endDate:last.endDate value:CategoryValueSleepAnalysisAsleepUnspecified metadata:@{ HKMetadataKeySleepOnsetLatency : @(sleepLatency) }] : Nil;
}

+ (NSArray<HKCategorySample *> *)samplesFromActivities:(NSArray<CMMotionActivitySample *> *)activities sleepLatency:(NSTimeInterval)sleepLatency {
	NSTimeInterval duration = (30.0 * TIME_MINUTE - sleepLatency) / TIME_MINUTE;
//	NSTimeInterval duration = sleepLatency > 0.0 ? [activities quartiles:^NSNumber *(CMMotionActivitySample *obj) {
//		return obj.confidence == CMMotionActivityConfidenceHigh ? @(obj.duration) : Nil;
//	}][1].doubleValue * (30 * TIME_MINUTE / sleepLatency) : TIME_DAY;

	NSMutableArray<NSMutableArray<CMMotionActivitySample *> *> *arr = [NSMutableArray arrayWithObject:[NSMutableArray new]];
	for (CMMotionActivitySample *activity in activities)
		if (activity.type == CMMotionActivityTypeStationary)
			[arr.lastObject addObject:activity];
		else if (activity.type != CMMotionActivityTypeUnknown && activity.confidence == CMMotionActivityConfidenceHigh && activity.duration > duration)
			[arr addObject:[NSMutableArray new]];

	NSArray<HKCategorySample *> *samples = [arr map:^id(NSArray<CMMotionActivitySample *> *obj) {
		return [self sampleFromActivities:obj sleepLatency:sleepLatency];
	}];
	return samples;
}

+ (NSArray<HKCategorySample *> *)samplesFromActivities:(NSArray<CMMotionActivitySample *> *)activities maxSleepLatency:(NSTimeInterval)sleepLatency {
	NSArray<HKCategorySample *> *samples = [self samplesFromActivities:activities sleepLatency:fabs(sleepLatency)];

	if (sleepLatency <= 0.0)
		return samples;

	NSTimeInterval stationary = [activities vSum:^NSNumber *(CMMotionActivitySample *obj) {
		return obj.type == CMMotionActivityTypeStationary ? @(obj.duration) : Nil;
	}];
	for (NSTimeInterval min = sleepLatency - TIME_MINUTE; min > 0.0; min -= TIME_MINUTE) {
		NSArray<HKCategorySample *> *tempMin = [self samplesFromActivities:activities sleepLatency:min];

		NSTimeInterval asleepMin = [tempMin vSum:^NSNumber *(HKCategorySample *obj) {
			return @(obj.duration);
		}];
		if (asleepMin < stationary) {
			samples = tempMin;
		} else {
			samples = tempMin;
/*
			for (NSTimeInterval sec = min + 1.0; sec < min + TIME_MINUTE; sec += 1.0) {
				NSArray<HKCategorySample *> *tempSec = [self samplesFromActivities:activities sleepLatency:sec];

				NSTimeInterval asleepSec = [tempSec vSum:^NSNumber *(HKCategorySample *obj) {
					return @(obj.duration);
				}];
				if (asleepSec < stationary) {
					samples = tempSec;

//					NSLog(@"sec: %f", sec);

					break;
				}
			}
*/
//			NSLog(@"min: %f", min);

			break;
		}
	}

	return samples;
}

+ (NSArray<HKCategorySample *> *)samplesWithStartDate:(NSDate *)start endDate:(NSDate *)end activities:(NSArray<CMMotionActivitySample *> *)activities sleepLatency:(NSTimeInterval)sleepLatency adaptive:(BOOL)adaptive {
	if (adaptive) {
		NSArray<CMMotionActivitySample *> *filtered = [activities query:^BOOL(CMMotionActivitySample *obj) {
			return [obj.startDate isGreaterThanOrEqual:start] && [obj.endDate isLessThanOrEqual:end];
		}];
		NSTimeInterval duration = [filtered vSum:^NSNumber *(CMMotionActivitySample *obj) {
			return obj.confidence == CMMotionActivityConfidenceLow
			? @(obj.duration / 2.0)
				: obj.confidence == CMMotionActivityConfidenceMedium
					? @(obj.duration / 1.5)
					: @(obj.duration);
		}];
		NSTimeInterval interval = [end timeIntervalSinceDate:start];
		if (duration > interval / 3.0) {
			NSArray<HKCategorySample *> *samples = [self samplesFromActivities:filtered maxSleepLatency:sleepLatency];
			if ([samples.firstObject.startDate isGreaterThan:start] && [samples.lastObject.endDate isLessThan:end])
				return samples;
		}

		return arr_([self sampleWithStartDate:[start dateByAddingTimeInterval:fabs(sleepLatency)] endDate:end value:CategoryValueSleepAnalysisAsleepUnspecified metadata:@{ HKMetadataKeySleepOnsetLatency : @(fabs(sleepLatency)) }]);
	} else {
		return activities.count ? [self samplesFromActivities:activities maxSleepLatency:sleepLatency] : arr_([self sampleWithStartDate:[start dateByAddingTimeInterval:fabs(sleepLatency)] endDate:end value:CategoryValueSleepAnalysisAsleepUnspecified metadata:@{ HKMetadataKeySleepOnsetLatency : @(fabs(sleepLatency)) }]);
	}
}

+ (void)saveSampleWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate activities:(NSArray<CMMotionActivitySample *> *)activities sleepLatency:(NSTimeInterval)sleepLatency adaptive:(NSNumber *)adaptive completion:(void(^)(BOOL))completion {
	if (startDate && endDate && [endDate timeIntervalSinceDate:startDate] > fabs(sleepLatency))
        [HKDataSleepAnalysis saveSampleWithStartDate:startDate endDate:endDate value:sleepLatency ? HKCategoryValueSleepAnalysisInBed : CategoryValueSleepAnalysisAsleepUnspecified metadata:activities ? @{ HKMetadataKeySampleActivities : [CMMotionActivitySample samplesToString:activities date:startDate] ?: STR_EMPTY } : Nil completion:sleepLatency ? ^(BOOL success) {
			if (adaptive) {
				NSDate *start = startDate;
				NSDate *end = endDate;
				BOOL adaptiveBool = adaptive.boolValue;
				if (adaptive.doubleValue > 1) {
					end = [NSDate dateWithTimeIntervalSinceReferenceDate:fabs(adaptive.doubleValue)];
					adaptiveBool = YES;
				} else if (adaptive.doubleValue < -1) {
					start = [NSDate dateWithTimeIntervalSinceReferenceDate:fabs(adaptive.doubleValue)];
					adaptiveBool = YES;
				}
				
				NSArray<HKCategorySample *> *samples = [HKDataSleepAnalysis samplesWithStartDate:/*startDate*/start endDate:/*endDate*/end activities:activities sleepLatency:sleepLatency adaptive:/*adaptive.boolValue*/adaptiveBool];
				
				if (samples.count)
					[[HKHealthStore defaultStore] saveObjects:samples completion:completion];
				else
					if (completion)
						completion(NO);
			} else {
				if (completion)
					completion(YES);
			}
		} : completion];
	else
		if (completion)
			completion(NO);
}

@end

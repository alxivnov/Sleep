//
//  Presenter.m
//  Sleep Diary
//
//  Created by Alexander Ivanov on 09/03/16.
//  Copyright © 2016 Alexander Ivanov. All rights reserved.
//

#import "AnalysisPresenter.h"

@interface SamplePresenter : AnalysisPresenter
@end

@interface DayPresenter : AnalysisPresenter
@end

@interface MonthPresenter : AnalysisPresenter
@end

@interface AnalysisPresenter ()
@property (strong, nonatomic) NSArray *samples;
@end

@implementation AnalysisPresenter

- (NSDate *)startDate {
	return Nil;
}

- (NSDate *)endDate {
	return Nil;
}

- (NSTimeInterval)duration {
	return 0.0;
}

- (NSUInteger)cycleCount {
	return 0;
}

- (instancetype)initWithSamples:(NSArray *)samples {
	self = [super init];

	if (self)
		self.samples = samples;

	return self;
}

- (NSString *)text {
	return [arr__([self.startDate descriptionForTime:NSDateFormatterShortStyle], [self.endDate descriptionForTime:NSDateFormatterShortStyle]) componentsJoinedByString:@" - "];
}

- (NSString *)detailText {
	return Nil;
}

- (NSString *)accessoryText {
	return [[NSDateComponentsFormatter hhmmFormatter] stringFromTimeInterval:self.duration];
}

- (BOOL)isOwn {
	return self.allPresenters || self.canDeleteSamples;
}

- (BOOL)canDeleteSamples {
	return self.allSamples.firstObject.isOwn;
}

- (void)deleteSamples:(void (^)(BOOL))completion {
	[[HKHealthStore defaultStore] deleteObjects:self.allSamples completion:^(BOOL success) {
		if (completion)
			completion(success);
	}];
}

+ (NSArray<AnalysisPresenter *> *)create:(NSArray<HKCategorySample *> *)samples unit:(NSCalendarUnit)unit {
	return unit == NSCalendarUnitDay || unit == NSCalendarUnitWeekOfMonth || unit == NSCalendarUnitWeekOfYear || unit == NSCalendarUnitMonth
		? [DayPresenter create:samples unit:unit]
		: unit == NSCalendarUnitYear || unit == NSCalendarUnitYearForWeekOfYear
			? [MonthPresenter create:samples unit:unit]
			: [SamplePresenter create:samples unit:unit];
}

+ (HKSampleQuery *)query:(NSCalendarUnit)unit startDate:(NSDate *)startDate endDate:(NSDate *)endDate completion:(void(^)(NSArray<AnalysisPresenter *> *presenters))completion {
	if (!endDate)
		endDate = [NSDate date];
	if (!startDate)
		startDate = unit ? [unit == NSCalendarUnitDay || unit == NSCalendarUnitWeekday ? endDate : [[endDate addValue:-1 forComponent:unit] addValue:1 forComponent:NSCalendarUnitDay] dateComponent] : Nil;

	return [HKDataSleepAnalysis querySamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionStrictEndDate limit:HKObjectQueryNoLimit sort:@{ HKSampleSortIdentifierEndDate : @NO } completion:^(NSArray<HKCategorySample *> *samples) {
		samples = [samples query:^BOOL(__kindof HKCategorySample *sample) {
			return sample.value != HKCategoryValueSleepAnalysisAwake;
		}];
		
		if (completion)
			completion([self create:samples unit:unit]);
	}];
}

+ (HKSampleQuery *)query:(NSCalendarUnit)unit completion:(void(^)(NSArray<AnalysisPresenter *> *presenters))completion {
	return [self query:unit startDate:Nil endDate:Nil completion:completion];
}

+ (HKObserverQuery *)observe:(NSCalendarUnit)unit startDate:(NSDate *)startDate endDate:(NSDate *)endDate updateHandler:(void (^)(NSArray<AnalysisPresenter *> *))updateHandler {
	return [HKDataSleepAnalysis observeSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionNone/*HKQueryOptionStrictEndDate*/ limit:HKObjectQueryNoLimit sort:@{ HKSampleSortIdentifierEndDate : @NO } updateHandler:^(NSArray<HKCategorySample *> *samples) {
		if (updateHandler)
			updateHandler([self create:samples unit:unit]);
	}];
}

+ (HKObserverQuery *)observe:(NSCalendarUnit)unit updateHandler:(void(^)(NSArray<AnalysisPresenter *> *presenters))updateHandler {
	return [self observe:unit startDate:[[NSDate date] component:unit] endDate:Nil updateHandler:updateHandler];
}

@end

@implementation SamplePresenter

- (NSDate *)startDate {
	return [self.samples.firstObject startDate];
}

- (NSDate *)endDate {
	return [self.samples.firstObject endDate];
}

__synthesize(NSTimeInterval, duration, [(HKCategorySample *)self.samples.firstObject duration])

__synthesize(NSUInteger, cycleCount, self.allSamples.firstObject.value == CategoryValueSleepAnalysisAsleepUnspecified ? floor(self.duration / SLEEP_CYCLE_DURATION) : self.allSamples.firstObject.value == CategoryValueSleepAnalysisAsleepDeep ? 1 : 0)

- (NSArray<HKCategorySample *> *)allSamples {
	return self.samples;
}

- (NSString *)detailText {
	NSString *detailText = self.allSamples.firstObject.value == CategoryValueSleepAnalysisAsleepUnspecified
		? loc(@"Asleep")
		: self.allSamples.firstObject.value == CategoryValueSleepAnalysisAsleepCore
			? loc(@"Core")
			: self.allSamples.firstObject.value == CategoryValueSleepAnalysisAsleepDeep
				? loc(@"Deep")
				: self.allSamples.firstObject.value == CategoryValueSleepAnalysisAsleepREM
					? loc(@"REM")
					: self.allSamples.firstObject.value == HKCategoryValueSleepAnalysisInBed
						? loc(@"In Bed")
						: self.allSamples.firstObject.value == HKCategoryValueSleepAnalysisAwake
							? loc(@"Awake")
							: Nil;
	if (IS_DEBUGGING && self.allSamples.firstObject.metadata[HKMetadataKeySleepOnsetLatency])
		detailText = [NSString stringWithFormat:@"%@ (%@)", detailText, [[NSDateComponentsFormatter mmssAbbreviatedFormatter] stringFromTimeInterval:[self.allSamples.firstObject.metadata[HKMetadataKeySleepOnsetLatency] doubleValue]]];
	return detailText;
}

+ (NSArray<AnalysisPresenter *> *)create:(NSArray<HKCategorySample *> *)samples unit:(NSCalendarUnit)unit {
	return [[samples map:^id(HKCategorySample *obj) {
		return [[self alloc] initWithSamples:@[ obj ]];
	}] sortedArrayUsingComparator:^NSComparisonResult(AnalysisPresenter * obj1, AnalysisPresenter * obj2) {
		return [obj1.startDate compare:obj2.startDate];
	}];
}

@end

@interface DayPresenter ()
@property (strong, nonatomic, readonly) NSArray<SamplePresenter *> *inBedPresenters;
@property (strong, nonatomic, readonly) NSArray<SamplePresenter *> *sleepPresenters;
@end

@implementation DayPresenter

__synthesize(NSArray *, inBedPresenters, [self.samples query:^BOOL(SamplePresenter *obj) {
	return obj.allSamples.firstObject.value == HKCategoryValueSleepAnalysisInBed;
}])

__synthesize(NSArray *, sleepPresenters, [self.samples query:^BOOL(SamplePresenter *obj) {
	return IS_ASLEEP(obj.allSamples.firstObject.value);
}])

- (NSDate *)startDate {
	return [self.sleepPresenters.firstObject startDate];
}

- (NSDate *)endDate {
	return [self.sleepPresenters.lastObject endDate];
}

__synthesize(NSTimeInterval, duration, [self.sleepPresenters sumDuration])

__synthesize(NSUInteger, cycleCount, [self.sleepPresenters sumCycleCount])

- (NSArray<AnalysisPresenter *> *)allPresenters {
	return self.samples;
}

- (NSString *)detailText {
	return [self.endDate descriptionForDate:NSDateFormatterMediumStyle];
}

+ (NSArray<AnalysisPresenter *> *)create:(NSArray<HKCategorySample *> *)samples unit:(NSCalendarUnit)unit {
	NSArray<AnalysisPresenter *> *array = [SamplePresenter create:samples unit:unit];
	NSDictionary<NSDate *, NSArray<AnalysisPresenter *> *> *dictionary = [array dictionaryWithKey:^id<NSCopying>(AnalysisPresenter *obj) {
		return [[obj.endDate dateByAddingTimeInterval:2.0 * TIME_HOUR] dateComponent];
	} value:^id(AnalysisPresenter *obj, id<NSCopying> key, id val) {
		NSMutableArray *arr = val ?: [NSMutableArray new];
		[arr addObject:obj];
		return arr;
	}];
	return [[dictionary.allValues map:^id(NSArray<AnalysisPresenter *> *obj) {
		return [[self alloc] initWithSamples:[obj sortedArrayUsingComparator:^NSComparisonResult(AnalysisPresenter *obj1, AnalysisPresenter *obj2) {
			return obj1.isOwn && obj2.isOwn
				? NSOrderedSame
				: obj1.isOwn
					? NSOrderedAscending
					: obj2.isOwn
						? NSOrderedDescending
						: NSOrderedSame;
		}]];
	}] sortedArrayUsingComparator:^NSComparisonResult(AnalysisPresenter *obj1, AnalysisPresenter *obj2) {
		return [obj2.endDate compare:obj1.endDate];
	}];
}

@end

@implementation MonthPresenter

__synthesize(NSDate *, startDate, [[[self.samples.lastObject startDate] dateComponent] dateByAddingTimeInterval:[self.samples avgStartTime]])

__synthesize(NSDate *, endDate, [[[self.samples.firstObject endDate] dateComponent] dateByAddingTimeInterval:[self.samples avgEndTime]])

__synthesize(NSTimeInterval, duration, [self.samples avgDuration])

__synthesize(NSUInteger, cycleCount, [self.samples avgCycleCount])

- (NSArray<AnalysisPresenter *> *)allPresenters {
	return self.samples;
}

- (NSString *)detailText {
	return [[NSDateFormatter defaultFormatter] monthSymbolForDate:[self.samples.lastObject endDate]];
}

+ (NSArray<MonthPresenter *> *)create:(NSArray<HKCategorySample *> *)samples unit:(NSCalendarUnit)unit {
	NSArray<AnalysisPresenter *> *array = [DayPresenter create:samples unit:unit];
	NSDictionary<NSNumber *, NSArray<AnalysisPresenter *> *> *dictionary = [array dictionaryWithKey:^id<NSCopying>(AnalysisPresenter *obj) {
		return @([obj.endDate componentValue:NSCalendarUnitYear] * 100 + [obj.endDate componentValue:NSCalendarUnitMonth]);
	} value:^id(AnalysisPresenter *obj, id<NSCopying> key, id val) {
		NSMutableArray *arr = val ?: [NSMutableArray new];
		[arr addObject:obj];
		return arr;
	}];
	return [[[dictionary.allValues map:^id(NSArray<AnalysisPresenter *> *obj) {
		return [[self alloc] initWithSamples:obj];
	}] sortedArrayUsingComparator:^NSComparisonResult(AnalysisPresenter *obj1, AnalysisPresenter *obj2) {
		return [obj2.endDate compare:obj1.endDate];
	}] arrayWithCount:12];
}

@end

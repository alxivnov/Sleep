//
//  Settings.h
//  Sleep Diary
//
//  Created by Alexander Ivanov on 13.04.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NSCalendar+Convenience.h"
#import "NSObject+Convenience.h"

#import "HKActiveEnergy+CMMotionActivitySample.h"
#import "AnalysisPresenter.h"


#define KEY_TIMER_START @"HKSleepAnalysisStartDate"
#define KEY_TIMER_END @"HKSleepAnalysisEndDate"


@interface Settings : NSObject

@property (strong, nonatomic) NSDate *startDate;

@property (assign, nonatomic) BOOL bedtimeAlert;
@property (assign, nonatomic) NSTimeInterval sleepDuration;

@property (strong, nonatomic) NSArray<NSNumber *> *alarmWeekdays;
@property (assign, nonatomic) NSTimeInterval alarmTime;

@property (assign, nonatomic) NSTimeInterval sleepLatency;


- (void)saveSampleWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate completion:(void(^)(BOOL success))completion;


- (NSDate *)alarmDate:(NSArray<AnalysisPresenter *> *)presenters;
- (NSDate *)alertDate:(NSArray<AnalysisPresenter *> *)presenters;

@end

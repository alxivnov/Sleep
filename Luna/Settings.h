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

#define RGB_LIGHT_TINT		0x6C69D1
#define RGB_DARK_TINT		0x3F3AAB
#define RGB_DEEP			0x36349D
#define RGB_CORE			0x3B82F6
#define RGB_REM				0x80CFFA



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


- (NSArray<HKCategorySample *> *)samplesFromActivities:(NSArray<CMMotionActivitySample *> *)activities fromUI:(BOOL)fromUI;

@end

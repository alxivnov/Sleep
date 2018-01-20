//
//  Presenter.h
//  Sleep Diary
//
//  Created by Alexander Ivanov on 09/03/16.
//  Copyright © 2016 Alexander Ivanov. All rights reserved.
//

#import <Foundation/Foundation.h>

@import HealthKit;

#define SLEEP_CYCLE_DURATION 5400.0

@class AnalysisPresenter;

@protocol AnalysisPresenter <NSObject>

@property (strong, nonatomic, readonly) NSDate *startDate;
@property (strong, nonatomic, readonly) NSDate *endDate;
@property (assign, nonatomic, readonly) NSTimeInterval duration;

@property (assign, nonatomic, readonly) NSUInteger cycleCount;

@end

@interface AnalysisPresenter : NSObject <AnalysisPresenter>

@property (strong, nonatomic, readonly) NSArray<AnalysisPresenter *> *allPresenters;
@property (strong, nonatomic, readonly) NSArray<HKCategorySample *> *allSamples;

@property (strong, nonatomic, readonly) NSString *text;
@property (strong, nonatomic, readonly) NSString *detailText;
@property (strong, nonatomic, readonly) NSString *accessoryText;

@property (assign, nonatomic, readonly) BOOL isOwn;
@property (assign, nonatomic, readonly) BOOL canDeleteSamples;
- (void)deleteSamples:(void(^)(BOOL success))completion;

+ (NSArray<AnalysisPresenter *> *)create:(NSArray<HKCategorySample *> *)samples unit:(NSCalendarUnit)unit;

+ (HKSampleQuery *)query:(NSCalendarUnit)unit startDate:(NSDate *)startDate endDate:(NSDate *)endDate completion:(void(^)(NSArray<AnalysisPresenter *> *presenters))completion;
+ (HKSampleQuery *)query:(NSCalendarUnit)unit completion:(void(^)(NSArray<AnalysisPresenter *> *presenters))completion;

+ (HKObserverQuery *)observe:(NSCalendarUnit)unit startDate:(NSDate *)startDate endDate:(NSDate *)endDate updateHandler:(void(^)(NSArray<AnalysisPresenter *> *presenters))updateHandler;
+ (HKObserverQuery *)observe:(NSCalendarUnit)unit updateHandler:(void(^)(NSArray<AnalysisPresenter *> *presenters))updateHandler;

@end

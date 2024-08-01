//
//  ActivityVisualizer.h
//  Sleep Diary
//
//  Created by Alexander Ivanov on 31.05.16.
//  Copyright © 2016 Alexander Ivanov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "CMMotionActivitySample.h"

@import CoreMotion;
@import HealthKit;
@import UIKit;

@interface ActivityVisualizer : UIScrollView

@property (strong, nonatomic, readonly) NSDate *startDate;
@property (strong, nonatomic, readonly) NSDate *endDate;

@property (strong, nonatomic) NSNumber *sleepLatency;

@property (strong, nonatomic) NSArray<HKCategorySample *> *inBedSamples;
@property (strong, nonatomic) NSArray<HKCategorySample *> *sleepSamples;
@property (strong, nonatomic) NSArray<HKQuantitySample *> *stepsSamples;
@property (strong, nonatomic) NSArray<HKQuantitySample *> *heartSamples;
@property (strong, nonatomic) NSDate *fallAsleep;
@property (strong, nonatomic) NSArray<CMMotionActivitySample *> *activities;
@property (assign, nonatomic) NSTimeInterval timeInterval;
@property (strong, nonatomic) NSDictionary<NSNumber *, NSNumber *> *scale;
@property (strong, nonatomic) CLLocation *location;

@property (assign, nonatomic) double zoom;
@property (assign, nonatomic) BOOL edit;

- (void)setSamples:(NSArray<HKCategorySample *> *)samples startDate:(NSDate *)startDate endDate:(NSDate *)endDate;

- (void)loadWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate completion:(void (^)(void))completion;
- (void)loadWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate;

- (void)scrollRectToStartDate:(NSDate *)startDate endDate:(NSDate *)endDate animated:(BOOL)animated;
- (void)scrollRectToVisibleDate:(NSDate *)date animated:(BOOL)animated;
- (void)scrollRectToVisibleDate:(NSDate *)date;

@end

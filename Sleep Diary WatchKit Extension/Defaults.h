//
//  Defaults.h
//  Sleep Diary
//
//  Created by Alexander Ivanov on 12.10.16.
//  Copyright © 2016 Alexander Ivanov. All rights reserved.
//

#import <Foundation/Foundation.h>

#define KEY_AUTODETECT @"autodetect"

@interface Defaults : NSObject

@property (strong, nonatomic) NSDate *autodetectDate;

@property (strong, nonatomic) NSDate *startDate;
@property (assign, nonatomic) BOOL asleep;

+ (instancetype)instance;

+ (void)saveSampleWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate sleepLatency:(NSTimeInterval)sleepLatency adaptive:(BOOL)adaptive completion:(void(^)(BOOL success))completion;

@end

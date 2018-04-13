//
//  NSArray+AnalysisPresenter.h
//  Sleep Diary
//
//  Created by Alexander Ivanov on 08/09/16.
//  Copyright © 2016 Alexander Ivanov. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AnalysisPresenter.h"

#import "Accelerate+Convenience.h"
#import "NSCalendar+Convenience.h"
#import "NSObject+Convenience.h"

@interface NSArray (AnalysisPresenter)

- (NSTimeInterval)sumDuration;
- (double)sumCycleCount;

- (NSTimeInterval)avgStartTime;
- (NSTimeInterval)avgEndTime;
- (NSTimeInterval)avgDuration;
- (double)avgCycleCount;

@end

//
//  Global+Notifications.h
//  Sleep Diary
//
//  Created by Alexander Ivanov on 01.10.16.
//  Copyright © 2016 Alexander Ivanov. All rights reserved.
//

#import "Global.h"
#import "AnalysisPresenter.h"

@interface Global (Notifications)

+ (NSDate *)alarmDate:(NSArray<AnalysisPresenter *> *)presenters sleepLatency:(NSTimeInterval)sleepLatency;
- (NSDate *)alarmDate:(NSArray<AnalysisPresenter *> *)presenters;

- (NSDate *)alertDate:(NSArray<AnalysisPresenter *> *)presenters;

@end

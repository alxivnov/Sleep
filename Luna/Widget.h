//
//  Widget.h
//  Sleep Diary
//
//  Created by Alexander Ivanov on 02.05.15.
//  Copyright (c) 2015 Alexander Ivanov. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AnalysisPresenter.h"

#define WIDGET [Widget instance]

@interface Widget : NSObject

- (void)isRegistered:(void(^)(BOOL granted))handler;
- (void)requestRegistration:(void(^)(BOOL granted))handler;

//- (NSDate *)notificationDate:(NSArray<AnalysisPresenter *> *)samples;
- (void)scheduleNotification:(NSArray<AnalysisPresenter *> *)samples completion:(void(^)(BOOL success))completion;
- (void)updateNotification:(void(^)(BOOL scheduled))completion;
- (void)updateQuickActions;

+ (instancetype)instance;

@end

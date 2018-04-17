//
//  AlarmController.h
//  Sleep Diary
//
//  Created by Alexander Ivanov on 29.11.15.
//  Copyright © 2015 Alexander Ivanov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AlarmController : UIViewController

- (instancetype)initWithView:(UIView *)view;

- (void)setupAlarmView;

+ (void)updateNotification:(void(^)(BOOL success))completion;

@end

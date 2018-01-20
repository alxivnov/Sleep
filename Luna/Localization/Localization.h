//
//  Localization.h
//  Sleep Diary
//
//  Created by Alexander Ivanov on 29.04.15.
//  Copyright (c) 2015 Alexander Ivanov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Localization : NSObject

+ (NSString *)change;
+ (NSString *)delete;
+ (NSString *)save;

+ (NSString *)deleteSample;

+ (NSString *)fallAsleep;
+ (NSString *)wakeUp;
+ (NSString *)goToSleep;
+ (NSString *)goToSleepBody;
+ (NSString *)wakeUpNow;
+ (NSString *)wakeUpNowBody;

+ (NSString *)goToSleep:(NSDate *)date;
+ (NSString *)notification:(NSDate *)date;
+ (NSString *)notificationDisabled;
+ (NSString *)notificationEnabled;

+ (NSString *)noAlarm;

+ (NSString *)yes;
+ (NSString *)no;
+ (NSString *)cancel;
+ (NSString *)ok;

+ (NSString *)thankYou;
+ (NSString *)feedbackMessage;

+ (NSString *)activity:(NSTimeInterval)time;
+ (NSString *)average:(NSTimeInterval)time;
+ (NSString *)total:(NSTimeInterval)time;
+ (NSString *)starts:(NSTimeInterval)time;
+ (NSString *)ends:(NSTimeInterval)time;
+ (NSString *)duration:(NSTimeInterval)time;

+ (NSString *)allowNotifications;
+ (NSString *)allowSendNotifications;
+ (NSString *)allowReadAndWriteData;

+ (NSString *)watchBedtime;
+ (NSString *)watchWakeUp;

+ (NSString *)asleep;
+ (NSString *)inBed;

+ (NSString *)wereYouAsleep;

+ (NSString *)mailFooter;

@end

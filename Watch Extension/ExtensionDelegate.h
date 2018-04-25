//
//  ExtensionDelegate.h
//  Watch Extension
//
//  Created by Alexander Ivanov on 08.04.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import <WatchKit/WatchKit.h>

#import "Accelerate+Convenience.h"
#import "CoreLocation+Convenience.h"
#import "CoreMotion+Convenience.h"
#import "ClockKit+Convenience.h"
#import "WatchKit+Convenience.h"
#import "WatchConnectivity+Convenience.h"
#import "UserNotifications+Convenience.h"
#import "CMMotionActivitySample.h"
#import "HKData.h"
#import "NSBundle+Convenience.h"
#import "NSCalendar+Convenience.h"
#import "NSFormatter+Convenience.h"
#import "UIBezierPath+Convenience.h"
#import "UIColor+Convenience.h"
#import "UIImage+Convenience.h"

#import "Settings.h"

#define SEC_22_00_EVENING	79200.0

#define KEY_TIMER_START		@"HKSleepAnalysisStartDate"
#define KEY_TIMER_END		@"HKSleepAnalysisEndDate"

#define IMG_BACK_LINE 		@"background-line"
#define IMG_BACK_FILL 		@"background-fill"
#define IMG_BACK_SIZE		136.0

#define ROW_ID_BUTTON @"Button"
#define ROW_ID_IN_BED @"In Bed"
#define ROW_ID_ASLEEP @"Asleep"

@interface ExtensionDelegate : NSObject <WKExtensionDelegate>

@property (strong, nonatomic, readonly) NSDictionary<NSDate *, AnalysisPresenter *> *presenters;
@property (assign, nonatomic, readonly) NSTimeInterval inBedDuration;
@property (assign, nonatomic, readonly) NSTimeInterval sleepDuration;

@property (strong, nonatomic, readonly) UIImage *image;

@property (strong, nonatomic) NSDate *startDate;


- (NSDate *)alarmDate;
- (NSDate *)alertDate;


- (void)detectFromUI:(BOOL)fromUI completion:(void (^)(NSArray<HKCategorySample *> *samples))completion;

@end

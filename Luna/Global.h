//
//  Global.h
//  Sleep Diary
//
//  Created by Alexander Ivanov on 06.04.15.
//  Copyright (c) 2015 Alexander Ivanov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "Settings.h"

#define GLOBAL [Global instance]

#define GUI_CANCEL @"cancel"
#define GUI_SAVE @"save"
#define GUI_UNWIND @"unwind"

#define GUI_INTERVAL @"interval"

#define URL_SCHEME @"luna"

#define KEY_ASLEEP @"asleep"
#define KEY_DURATION @"duration"
#define KEY_SLEEP_DURATION @"sleepDuration"

#define APP_ID_DONE 734258590
#define APP_ID_LUNA 964733439
#define APP_ID_RINGO 979630381

#define STR_EMAIL @"alex@apptag.me"

#define APP_PURCHASE_ID_1 @"com.alexivanov.luna.tip.1"
#define APP_PURCHASE_ID_2 @"com.alexivanov.luna.tip.2"
#define APP_PURCHASE_ID_3 @"com.alexivanov.luna.tip.3"

#define APP_WIDGET_ID @"com.alexivanov.luna.widget"

#define IMG_ARROW_DOWN @"arrow-down"
#define IMG_ARROW_UP @"arrow-up"
#define IMG_ARROW_DOUBLE_DOWN @"arrow-double-down"
#define IMG_ARROW_DOUBLE_UP @"arrow-double-up"
#define IMG_CIRCLE_FULL @"circle-full"
#define IMG_CIRCLE_LINE @"circle-line"

#define IMG_MOON_LINE @"moon-line"
#define IMG_MOON_FILL @"moon-full"
#define IMG_SUN_LINE @"sun-line"
#define IMG_SUN_FILL @"sun-full"

#define IMG_LUNA_MOON @"Luna-Moon-64"
#define IMG_LUNA_SUN @"Luna-Sun-64"

#define IMG_SUNRISE @"sunrise"
#define IMG_SUNSET @"sunset"

#define GUI_FALL_ASLEEP @"fall-asleep"
#define GUI_WAKE_UP @"wake-up"

@interface Global : Settings

@property (strong, nonatomic, readonly) NSNumber *isAuthorized;
- (void)requestAuthorization:(void(^)(BOOL success))completion;

@property (assign, nonatomic, readonly) BOOL asleep;

- (void)startSleeping;
- (void)endSleeping;
- (void)endSleeping:(void(^)(BOOL success))completion;

@property (strong, nonatomic) NSNumber *longPress;

@property (assign, nonatomic) BOOL scale;

+ (instancetype)instance;

@property (strong, nonatomic, readonly) UIColor *tintColor;

@property (strong, nonatomic, readonly) NSDictionary *affiliateInfo;

@end

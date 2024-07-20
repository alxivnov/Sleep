//
//  Widget.m
//  Sleep Diary
//
//  Created by Alexander Ivanov on 02.05.15.
//  Copyright (c) 2015 Alexander Ivanov. All rights reserved.
//

#import "Widget.h"
#import "AnalysisPresenter.h"
#import "Global.h"
#import "Localization.h"

#import "NSArray+Convenience.h"
#import "NSObject+Convenience.h"
#import "UIApplication+Convenience.h"
#import "UIAlertController+Convenience.h"
#import "UIImage+Convenience.h"
#import "UIViewController+Convenience.h"
#import "Dispatch+Convenience.h"
#import "UserNotifications+Convenience.h"

@import NotificationCenter;

@implementation Widget

- (void)isRegistered:(void(^)(BOOL granted))handler {
	[UNUserNotificationCenter getCurrentNotificationSettings:^(UNNotificationSettings *settings) {
		handler(settings.authorization.boolValue);
	}];
}

- (void)requestRegistration:(void(^)(BOOL granted))handler {
	[UNUserNotificationCenter getCurrentNotificationSettings:^(UNNotificationSettings *settings) {
		if (settings.authorization.boolValue) {
			if (handler)
				handler(YES);
		} else if (settings.authorization) {
			[GCD main:^{
				[[UIApplication sharedApplication].rootViewController.lastViewController presentAlertWithTitle:[Localization allowNotifications] message:[Localization allowSendNotifications] cancelActionTitle:[Localization ok] destructiveActionTitle:Nil otherActionTitles:Nil completion:^(UIAlertController *instance, NSInteger index) {
					[UIApplication openSettings];
				}];
			}];

			if (handler)
				handler(NO);
		} else {
			UNNotificationCategory *fallAsleep = [UNNotificationCategory categoryWithIdentifier:GUI_FALL_ASLEEP actions:@[ [UNNotificationAction actionWithIdentifier:GUI_FALL_ASLEEP title:[Localization fallAsleep]] ]];

			UNNotificationCategory *wakeUp = [UNNotificationCategory categoryWithIdentifier:GUI_WAKE_UP actions:@[ [UNNotificationAction actionWithIdentifier:GUI_WAKE_UP title:[Localization wakeUp]] ]];

			[UNUserNotificationCenter requestAuthorizationIfNeededWithOptions:UNAuthorizationOptionAlert | UNAuthorizationOptionSound completionHandler:^(NSNumber *granted) {
				if (granted.boolValue)
					[UNUserNotificationCenter setNotificationCategories:@[ fallAsleep, wakeUp ]];

				if (handler)
					handler(granted.boolValue);
			}];
		}
	}];
}

- (void)scheduleNotification:(NSArray<AnalysisPresenter *> *)presenters completion:(void(^)(BOOL))completion {
	NSDate *fireDate = [GLOBAL alertDate:presenters];

	[[UNNotificationContent contentWithTitle:[Localization goToSleep] subtitle:Nil body:[Localization goToSleepBody] badge:Nil sound:STR_EMPTY attachments:arr_([UIImage URLForResource:IMG_LUNA_MOON withExtension:@"png"]) userInfo:Nil categoryIdentifier:GUI_FALL_ASLEEP] scheduleWithIdentifier:GUI_FALL_ASLEEP date:fireDate repeats:NO completion:completion];
}

- (void)updateNotification:(void(^)(BOOL scheduled))completion {
//	[[self class] request];

	if (GLOBAL.asleep || !GLOBAL.bedtimeAlert) {
		[UNUserNotificationCenter removePendingNotificationRequestWithIdentifier:GUI_FALL_ASLEEP];

		if (completion)
			completion(NO);
	} else {
		[AnalysisPresenter query:NSCalendarUnitWeekOfMonth completion:^(NSArray<AnalysisPresenter *> *presenters) {
			[self scheduleNotification:presenters completion:^(BOOL success) {
				[GCD main:^{
					if (completion)
						completion(YES);
				}];
			}];
		}];
	}
}

- (void)updateQuickActions {
	[UIApplication sharedApplication].shortcutItems = @[ [[UIApplicationShortcutItem alloc] initWithType:GLOBAL.asleep ? GUI_WAKE_UP : GUI_FALL_ASLEEP localizedTitle:GLOBAL.asleep ? [Localization wakeUp] : [Localization fallAsleep] localizedSubtitle:Nil icon:[UIApplicationShortcutIcon iconWithTemplateImageName:GLOBAL.asleep ? IMG_LUNA_SUN : IMG_LUNA_MOON] userInfo:Nil] ];
}

static id _instance;

+ (instancetype)instance {
	@synchronized(self) {
		if (!_instance)
			_instance = [self new];
	}
	
	return _instance;
}

@end

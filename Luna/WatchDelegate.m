//
//  SessionDelegate.m
//  Sleep Diary
//
//  Created by Alexander Ivanov on 02.10.15.
//  Copyright © 2015 Alexander Ivanov. All rights reserved.
//

#import "WatchDelegate.h"
#import "AlarmPickerController.h"
#import "Global.h"
#import "Widget.h"

#import "NSObject+Convenience.h"
#import "UIApplication+Convenience.h"
#import "UIViewController+Convenience.h"
#import "Dispatch+Convenience.h"
#import "UserNotifications+Convenience.h"

@implementation WatchDelegate
/*
- (NSDictionary *)messageWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate duration:(NSTimeInterval)duration wakeUpDate:(NSDate *)wakeUpDate fallAsleepDate:(NSDate *)fallAsleepDate {
	NSMutableDictionary *replyInfo = [NSMutableDictionary new];
	replyInfo[KEY_ASLEEP] = @(GLOBAL.asleep);
	replyInfo[KEY_TIMER_START] = [startDate serialize];
	replyInfo[KEY_TIMER_END] = [endDate serialize];
	replyInfo[KEY_DURATION] = @(duration);
	replyInfo[GUI_WAKE_UP] = [wakeUpDate serialize];
	replyInfo[GUI_FALL_ASLEEP] = [fallAsleepDate serialize];
	replyInfo[KEY_SLEEP_DURATION] = @(GLOBAL.sleepDuration);

	return replyInfo;
}

- (void)message:(void(^)(NSDictionary *message))handler {
	[AnalysisPresenter query:NSCalendarUnitDay completion:^(NSArray<AnalysisPresenter *> *presenters) {
		[UNUserNotificationCenter getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> *requests) {
			handler([self messageWithStartDate:presenters.firstObject.startDate endDate:presenters.firstObject.endDate duration:presenters.firstObject.duration wakeUpDate:[requests firstObject:^BOOL(UNNotificationRequest *obj) {
				return [obj.identifier isEqualToString:GUI_WAKE_UP];
			}].nextTriggerDate fallAsleepDate:[requests firstObject:^BOOL(UNNotificationRequest *obj) {
				return [obj.identifier isEqualToString:GUI_FALL_ASLEEP];
			}].nextTriggerDate]);
		}];
	}];
}
*/
- (void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *,id> *)message replyHandler:(void (^)(NSDictionary<NSString *,id> * _Nonnull))replyHandler {
	if ([GUI_WAKE_UP isEqualToString:message[STR_UNDERSCORE]])
		[UNUserNotificationCenter getPendingNotificationRequestWithIdentifier:GUI_WAKE_UP completionHandler:^(UNNotificationRequest *request) {
			replyHandler(@{ GUI_WAKE_UP : [request.nextTriggerDate serialize] ?: STR_EMPTY });
		}];
	else if ([GUI_FALL_ASLEEP isEqualToString:message[STR_UNDERSCORE]])
		[UNUserNotificationCenter getPendingNotificationRequestWithIdentifier:GUI_FALL_ASLEEP completionHandler:^(UNNotificationRequest *request) {
			replyHandler(@{ GUI_FALL_ASLEEP : [request.nextTriggerDate serialize] ?: STR_EMPTY });
		}];
	else if ([[[Settings class] description] isEqualToString:message[STR_UNDERSCORE]]) {
		NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:6];
		dic[STR_UNDERSCORE] = [[Settings class] description];
		dic[@"startDate"] = GLOBAL.startDate;
		dic[@"bedtimeAlert"] = @(GLOBAL.bedtimeAlert);
		dic[@"sleepDuration"] = @(GLOBAL.sleepDuration);
		dic[@"alarmWeekdays"] = GLOBAL.alarmWeekdays;
		dic[@"alarmTime"] = @(GLOBAL.alarmTime);
		dic[@"sleepLatency"] = @(GLOBAL.sleepLatency);
		replyHandler(dic);
	} else if (message[KEY_TIMER_START]) {
		GLOBAL.startDate = [NSDate deserialize:message[KEY_TIMER_START]];

		if (GLOBAL.asleep) {
//			[GLOBAL endSleeping:^(BOOL success) {
				[AlarmPickerController updateNotification:Nil];
				[WIDGET updateNotification:^(BOOL scheduled) {
//					[self message:^(NSDictionary *message) {
//						replyHandler(message);
//					}];

					[GCD main:^{
						[[UIApplication sharedApplication].rootViewController forwardSelector:@selector(setup) nextTarget:UIViewControllerNextTarget(YES)];
					}];
				}];
				[WIDGET updateQuickActions];
//			}];
		} else {
//			[GLOBAL startSleeping];

			[AlarmPickerController updateNotification:^(BOOL succcess) {
//				[self message:^(NSDictionary *message) {
//					replyHandler(message);
//				}];

				[GCD main:^{
					[[UIApplication sharedApplication].rootViewController forwardSelector:@selector(setup) nextTarget:UIViewControllerNextTarget(YES)];
				}];
			}];
			[WIDGET updateNotification:Nil];
			[WIDGET updateQuickActions];
		}
	} else
//		[self message:^(NSDictionary *message) {
			replyHandler(@{ KEY_TIMER_START : [GLOBAL.startDate serialize] ?: STR_EMPTY });
//		}];
}

- (void)sendMessage {
//	[self message:^(NSDictionary *message) {
		[self.reachableSession sendMessage:@{ KEY_TIMER_START : [GLOBAL.startDate serialize] ?: STR_EMPTY }];
//	}];
}

- (void)getActivitiesFromDate:(NSDate *)startDate toDate:(NSDate *)endDate handler:(void (^)(NSArray<CMMotionActivitySample *> *))handler {
	if (!startDate || !endDate || !handler)
		return;
	
	[self.reachableSession sendMessage:@{ STR_UNDERSCORE : HKMetadataKeySampleActivities, KEY_TIMER_START : startDate, KEY_TIMER_END : endDate } replyHandler:^(NSDictionary<NSString *,id> *replyMessage) {
		handler([CMMotionActivitySample samplesFromData:replyMessage[HKMetadataKeySampleActivities] date:startDate]);
	}];
}

@end

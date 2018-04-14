//
//  ExtensionDelegate.m
//  Watch Extension
//
//  Created by Alexander Ivanov on 08.04.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "ExtensionDelegate.h"

@interface ExtensionDelegate ()
@property (strong, nonatomic, readonly) Settings *settings;

@property (strong, nonatomic) HKObserverQuery *observer;

@property (strong, nonatomic) NSDictionary<NSDate *, AnalysisPresenter *> *presenters;
@property (assign, nonatomic) NSTimeInterval inBedDuration;
@property (assign, nonatomic) NSTimeInterval sleepDuration;
@property (strong, nonatomic) UIImage *image;
@end

@implementation ExtensionDelegate

__synthesize(Settings *, settings, [[Settings alloc] init])

- (NSDate *)startDate {
	return self.settings.startDate;
}

- (void)setStartDate:(NSDate *)startDate {
	if (self.settings.startDate && !startDate)
		[self.settings saveSampleWithStartDate:self.settings.startDate endDate:[NSDate date] completion:Nil];

	self.settings.startDate = startDate;
}

- (NSDate *)alarmDate {
	return [self.settings alertDate:self.presenters.allValues];
}

- (NSDate *)alertDate {
	return [self.settings alertDate:self.presenters.allValues];
}

- (UIImage *)image {
	return self.startDate ? [UIImage imageWithSize:CGSizeMake(IMG_BACK_SIZE, IMG_BACK_SIZE) opaque:NO scale:2.0 draw:^(CGContextRef context) {
		NSTimeInterval inBedDuration = fabs(self.startDate.timeIntervalSinceNow) + ([[NSDate date] timeComponent] > SEC_22_00_EVENING ? 0.0 : self.inBedDuration);

		CGRect frame = CGRectMake(0.0, 0.0, IMG_BACK_SIZE, IMG_BACK_SIZE);
		[[UIColor whiteColor] setStroke];
		[[UIBezierPath bezierPathWithArcFrame:frame width:12.0 start:0.0 end:inBedDuration / (self.settings.sleepDuration + self.settings.sleepLatency) lineCap:kCGLineCapRound lineJoin:kCGLineJoinRound] stroke];
	}] : _image;
}

- (void)setup {
//	NSDate *endDate = [NSDate date];
//	NSDate *startDate = [endDate addValue:-1 forComponent:NSCalendarUnitWeekOfMonth];
	self.observer = [AnalysisPresenter observe:NSCalendarUnitWeekOfMonth updateHandler:^(NSArray<AnalysisPresenter *> *presenters) {
//	self.observer = [HKDataSleepAnalysis observeSamplesWithStartDate:startDate endDate:Nil/*endDate*/ options:HKQueryOptionNone/*HKQueryOptionStrictEndDate*/ limit:HKObjectQueryNoLimit sort:@{ HKSampleSortIdentifierStartDate : @YES } updateHandler:^(NSArray<HKCategorySample *> *samples) {
		self.presenters = [presenters dictionaryWithKey:^id<NSCopying>(AnalysisPresenter *obj) {
			return [obj.endDate dateComponent];
		}];
/*		self.samples = [samples dictionaryWithKey:^id<NSCopying>(HKCategorySample *obj) {
			return obj.value == HKCategoryValueSleepAnalysisInBed || obj.value == HKCategoryValueSleepAnalysisAsleep ? obj.endDate.dateComponent : Nil;
		} value:^id(HKCategorySample *obj, id<NSCopying> key, id val) {
			NSMutableArray *arr = val ?: [NSMutableArray array];
			[arr addObject:obj];
			return arr;
		}];
*/
		NSDate *today = [NSDate today];
		self.inBedDuration = [self.presenters[today].allPresenters sum:^NSNumber *(AnalysisPresenter *obj) {
			return obj.allSamples.firstObject.value == HKCategoryValueSleepAnalysisInBed ? @(obj.duration) : Nil;
		}];
		self.sleepDuration = [self.presenters[today].allPresenters sum:^NSNumber *(AnalysisPresenter *obj) {
			return obj.allSamples.firstObject.value == HKCategoryValueSleepAnalysisAsleep ? @(obj.duration) : Nil;
		}];

		self.image = self.startDate ? Nil : [UIImage imageWithSize:CGSizeMake(IMG_BACK_SIZE, IMG_BACK_SIZE) opaque:NO scale:2.0 draw:^(CGContextRef context) {
			CGRect frame = CGRectMake(0.0, 0.0, IMG_BACK_SIZE, IMG_BACK_SIZE);
			[[UIColor color:RGB_LIGHT_TINT] setStroke];
			[[UIBezierPath bezierPathWithArcFrame:frame width:12.0 start:0.0 end:self.inBedDuration / (self.settings.sleepDuration + self.settings.sleepLatency) lineCap:kCGLineCapRound lineJoin:kCGLineJoinRound] stroke];

			frame = CGRectInset(frame, 12.0, 12.0);
			[[UIColor color:RGB_DARK_TINT] setStroke];
			[[UIBezierPath bezierPathWithArcFrame:frame width:12.0 start:0.0 end:self.sleepDuration / self.settings.sleepDuration lineCap:kCGLineCapRound lineJoin:kCGLineJoinRound] stroke];
		}];

		sel([WKExtension sharedExtension].visibleInterfaceController, setup);

		[[CLKComplicationServer sharedInstance] reloadTimeline:Nil];
	}];

	[WCSessionDelegate instance].didReceiveMessage = ^(NSDictionary<NSString *,id> *message, void (^replyHandler)(NSDictionary<NSString *,id> *)) {
		if ([message[STR_UNDERSCORE] isEqualToString:HKMetadataKeySampleActivities]) {
			[CMMotionActivitySample queryActivityStartingFromDate:message[KEY_TIMER_START] toDate:message[KEY_TIMER_END] within:self.settings.sleepLatency withHandler:^(NSArray<CMMotionActivitySample *> *activities) {
				NSData *data = [CMMotionActivitySample samplesToData:activities date:message[KEY_TIMER_START]];
				replyHandler(data ? @{ HKMetadataKeySampleActivities : data } : @{ });
			}];
		} else {
			NSDate *date = [NSDate deserialize:message[KEY_TIMER_START]];
			if (NSDateIsEqualToDate(self.startDate, date))
				return;

			self.startDate = date;

			[GCD main:^{
				sel([WKExtension sharedExtension].visibleInterfaceController, setup);
			}];

			[[CLKComplicationServer sharedInstance] reloadTimeline:Nil];
		}
	};

	[[WCSessionDelegate instance].reachableSession sendMessage:@{ STR_UNDERSCORE : [[Settings class] description] } replyHandler:^(NSDictionary<NSString *,id> *replyMessage) {
		if (!replyMessage)
			return;

		if (!self.settings.startDate)
			self.settings.startDate = replyMessage[@"startDate"];

		self.settings.bedtimeAlert = [replyMessage[@"bedtimeAlert"] boolValue];
		self.settings.sleepDuration = [replyMessage[@"sleepDuration"] doubleValue];
		self.settings.alarmWeekdays = replyMessage[@"alarmWeekdays"];
		self.settings.alarmTime = [replyMessage[@"alarmTime"] doubleValue];
		self.settings.sleepLatency = [replyMessage[@"sleepLatency"] doubleValue];
	}];
}

- (void)applicationDidFinishLaunching {
    // Perform any final initialization of your application.

	[HKDataSleepAnalysis requestAuthorizationToShare:YES andRead:YES completion:^(BOOL success) {
		if (success)
			[self setup];
	}];

	[[WCSessionDelegate instance].reachableSession sendMessage:@{ STR_UNDERSCORE : STR_EMPTY } replyHandler:^(NSDictionary<NSString *,id> *replyMessage) {

	}];
}

- (void)applicationDidBecomeActive {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillResignActive {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, etc.
}

- (void)handleBackgroundTasks:(NSSet<WKRefreshBackgroundTask *> *)backgroundTasks {
    // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
    for (WKRefreshBackgroundTask * task in backgroundTasks) {
        // Check the Class of each task to decide how to process it
        if ([task isKindOfClass:[WKApplicationRefreshBackgroundTask class]]) {
            // Be sure to complete the background task once you’re done.
            WKApplicationRefreshBackgroundTask *backgroundTask = (WKApplicationRefreshBackgroundTask*)task;
            [backgroundTask setTaskCompletedWithSnapshot:NO];
        } else if ([task isKindOfClass:[WKSnapshotRefreshBackgroundTask class]]) {
            // Snapshot tasks have a unique completion call, make sure to set your expiration date
            WKSnapshotRefreshBackgroundTask *snapshotTask = (WKSnapshotRefreshBackgroundTask*)task;
            [snapshotTask setTaskCompletedWithDefaultStateRestored:YES estimatedSnapshotExpiration:[NSDate distantFuture] userInfo:nil];
        } else if ([task isKindOfClass:[WKWatchConnectivityRefreshBackgroundTask class]]) {
            // Be sure to complete the background task once you’re done.
            WKWatchConnectivityRefreshBackgroundTask *backgroundTask = (WKWatchConnectivityRefreshBackgroundTask*)task;
            [backgroundTask setTaskCompletedWithSnapshot:NO];
        } else if ([task isKindOfClass:[WKURLSessionRefreshBackgroundTask class]]) {
            // Be sure to complete the background task once you’re done.
            WKURLSessionRefreshBackgroundTask *backgroundTask = (WKURLSessionRefreshBackgroundTask*)task;
            [backgroundTask setTaskCompletedWithSnapshot:NO];
        } else {
            // make sure to complete unhandled task types
            [task setTaskCompletedWithSnapshot:NO];
        }
    }
}

@end

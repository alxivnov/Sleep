//
//  AppDelegate.m
//  Luna
//
//  Created by Alexander Ivanov on 02.02.15.
//  Copyright (c) 2015 Alexander Ivanov. All rights reserved.
//

//#import <Fabric/Fabric.h>
//#import <Crashlytics/Crashlytics.h>

#import "AppDelegate.h"
#import "Global.h"
#import "WatchDelegate.h"
#import "Widget.h"

//#import "UIViewController+Answers.h"

#import "NSObject+Convenience.h"
#import "SKInAppPurchase.h"
#import "UIViewController+Convenience.h"
#import "CoreLocation+Convenience.h"
#import "UserNotifications+Convenience.h"

//	17.7.21.900

@interface AppDelegate () <UNUserNotificationCenterDelegate, CLLocationManagerDelegate>
@property (strong, nonatomic) HKObserverQuery *observer;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
//	if (!IS_DEBUGGING)
//		[Fabric with:@[[Crashlytics class]]];

//	[CLLocationManager locationServicesEnabled];
	[CLLocationManager defaultManager].delegate = self;

	[SKInAppPurchase purchasesWithProductIdentifiers:@[ APP_PURCHASE_ID_1, APP_PURCHASE_ID_2, APP_PURCHASE_ID_3 ]];
	
	[[WatchDelegate instance] session];
	// Override point for customization after application launch.

	if (launchOptions[UIApplicationLaunchOptionsShortcutItemKey])
		[application.rootViewController.lastViewController forwardSelector:@selector(application:performActionForShortcutItem:completionHandler:) withObject:application withObject:launchOptions[UIApplicationLaunchOptionsShortcutItemKey] withObject:Nil nextTarget:UIViewControllerNextTarget(YES)];
	
	NSDateComponents * comp = [NSDateComponents dateComponentsWithYear:2015 month:2 day:5];
	[@(ceil([[NSDate now] timeIntervalSinceDate:comp.date] / (24.0 * 60.0 * 60.0))) log:@"Days"];
	
	self.observer = [AnalysisPresenter observe:NSCalendarUnitWeekOfMonth updateHandler:^(NSArray<AnalysisPresenter *> *presenters) {
		[application.rootViewController forwardSelector:@selector(reloadData)];
	}];

	return YES;
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
	[application.rootViewController.lastViewController forwardSelector:@selector(application:performActionForShortcutItem:completionHandler:) withObject:application withObject:shortcutItem withObject:completionHandler nextTarget:UIViewControllerNextTarget(YES)];
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
	return [[app.rootViewController.lastViewController forwardSelector:@selector(application:openURL:options:) withObject:app withObject:url withObject:options nextTarget:UIViewControllerNextTarget(YES)] boolValue];
}

- (void)applicationWillResignActive:(UIApplication *)application {
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	
	[application.rootViewController.lastViewController forwardSelector:@selector(endLogging)];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	
	[application.rootViewController.lastViewController forwardSelector:@selector(startLogging)];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

	[application.rootViewController forwardSelector:@selector(setup) nextTarget:UIViewControllerNextTarget(YES)];
}

- (void)applicationWillTerminate:(UIApplication *)application {
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application handleWatchKitExtensionRequest:(NSDictionary *)userInfo reply:(void (^)(NSDictionary *))reply {
	[[WatchDelegate instance] session:[WatchDelegate instance].session didReceiveMessage:userInfo replyHandler:reply];
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
	if (completionHandler)
		completionHandler(UNNotificationPresentationOptionAll);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
	if (!response.actionIdentifier)
		return;

	[UNUserNotificationCenter removeDeliveredNotificationWithIdentifier:response.notification.request.identifier];

	if ([response.actionIdentifier isEqualToString:GUI_FALL_ASLEEP] && [response.notification.request.content.categoryIdentifier isEqualToString:GUI_FALL_ASLEEP])
		[[[UIApplication sharedApplication].rootViewController presentRootViewController] forwardSelector:@selector(handleActionWithIdentifier:forLocalNotification:) withObject:response.actionIdentifier withObject:response.notification nextTarget:UIViewControllerNextTarget(YES)];

	completionHandler();
}

//- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
//	[Answers logCustomEventWithName:@"Memory Warning" customAttributes:@{ @"VC" : [[application.rootViewController.lastViewController class] description], @"model" : [UIDevice currentDevice].model, @"version" : [UIDevice currentDevice].systemVersion }];
//}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
	[[UIApplication sharedApplication].rootViewController forwardSelector:@selector(locationManager:didChangeAuthorizationStatus:) withObject:manager withObject:@(status) nextTarget:UIViewControllerNextTarget(NO)];
}

@end

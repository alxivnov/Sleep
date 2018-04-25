//
//  ViewController.m
//  Luna
//
//  Created by Alexander Ivanov on 02.02.15.
//  Copyright (c) 2015 Alexander Ivanov. All rights reserved.
//

#import "ViewController.h"
#import "AlarmController.h"
#import "AnalysisController.h"
#import "AnalysisPresenter.h"
#import "Global.h"
#import "Localization.h"
#import "WatchDelegate.h"
#import "Widget.h"
#import "HKCategorySample+JSON.h"

#import "UIBezierPath+Convenience.h"
#import "UIRateController+Answers.h"
#import "UIViewController+Answers.h"

#import "Dispatch+Convenience.h"
#import "NSArray+Convenience.h"
#import "NSCalendar+Convenience.h"
#import "NSObject+Convenience.h"
#import "NSTimer+Convenience.h"
#import "NSFormatter+Convenience.h"
#import "UIAlertController+Convenience.h"

@import NotificationCenter;

@interface ViewController ()
@end

@implementation ViewController

- (IBAction)healthKitButtonAction:(UIButton *)sender {
//	[self requestAuthorization];
}

- (IBAction)notificationsButtonAction:(UIButton *)sender {
	[WIDGET requestRegistration:^(BOOL granted) {
		[GCD main:^{
			[self setup];
		}];
	}];
}

- (void)viewDidLoad {
	[super viewDidLoad];

//	[AlarmController updateNotification];
	
//	[self setup];

//	[HKAuth requestAuthorization];



//	[[NCWidgetController widgetController] setHasContent:YES forWidgetWithBundleIdentifier:APP_WIDGET_ID];
}

- (NSString *)loggingName {
	return @"Main";
}

- (NSDictionary<NSString *,id> *)loggingCustomAttributes {
	WCSession *defaultSession = [WCSession isSupported] ? [WCSession defaultSession] : Nil;
	
	return @{ @"WCSession" : defaultSession.isReachable ? @"reachable" : defaultSession.isWatchAppInstalled ? @"app installed" : defaultSession.isPaired ? @"paired" : defaultSession ? @"supported" : @"not supported" };
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	[self startLogging];



	if (![UIRateController instance].view)
		return;

	[NSRateController instance].appIdentifier = APP_ID_LUNA;
	[NSRateController instance].affiliateInfo = GLOBAL.affiliateInfo;
	[NSRateController instance].recipient = STR_EMAIL;

	[UIRateController instance].view.backgroundColor = self.view.backgroundColor;
	[UIRateController instance].view.tintColor = [UIColor whiteColor];

	[[UIRateController instance] setupLogging:^(NSRateControllerState state) {
		if (state == NSRateControllerStateMailYes || state == NSRateControllerStateMailNo || state == NSRateControllerStateRateYes || state == NSRateControllerStateRateNo)
			[[UIApplication sharedApplication].rootViewController forwardSelector:@selector(setup) nextTarget:UIViewControllerNextTarget(YES)];
	}];
}
/*
- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	[self setup];
}
*/
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	
	[self endLogging];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
}

@end

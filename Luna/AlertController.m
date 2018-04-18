//
//  AlertController.m
//  Sleep Diary
//
//  Created by Alexander Ivanov on 18/04/16.
//  Copyright © 2016 Alexander Ivanov. All rights reserved.
//

#import "AlertController.h"
#import "ActivityController.h"
#import "Global.h"
#import "Widget.h"
#import "Localization.h"

#import "UIBezierPath+Convenience.h"
#import "UIButton+Convenience.h"

#import "NSArray+Convenience.h"
#import "NSCalendar+Convenience.h"
#import "NSObject+Convenience.h"
#import "UIViewController+Convenience.h"
#import "Dispatch+Convenience.h"
#import "UserNotifications+Convenience.h"

@interface AlertController ()

@property (weak, nonatomic) IBOutlet UIButton *alertButton;
@end

@implementation AlertController

- (NSNumber *)buttonShapes {
	return [self.alertButton.titleLabel.attributedText attributesAtIndex:0 effectiveRange:Nil][NSUnderlineStyleAttributeName];
}

- (void)setupAlertButton:(NSArray<AnalysisPresenter *> *)presenters {
	[UNUserNotificationCenter getPendingNotificationRequestsWithIdentifier:GUI_FALL_ASLEEP completionHandler:^(NSArray<UNNotificationRequest *> *requests) {
		[GCD main:^{
			self.alertButton.selected = requests.firstObject != Nil;
			[self.alertButton setTitle:[Localization goToSleep:requests.firstObject ? requests.firstObject.nextTriggerDate : [GLOBAL alertDate:presenters]]];
		}];
	}];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)alertButtonAction:(UIButton *)sender {
	sender.selected = !sender.selected;
	[sender setTitle:sender.selected ? [Localization notificationEnabled] : [Localization notificationDisabled]];

	[AnalysisPresenter query:NSCalendarUnitWeekOfMonth completion:^(NSArray<AnalysisPresenter *> *presenters) {
		if (sender.selected)
			[WIDGET scheduleNotification:presenters];
		else
			[UNUserNotificationCenter removePendingNotificationRequestWithIdentifier:GUI_FALL_ASLEEP];

		[GCD queue:GCD_MAIN after:1.0 block:^{
			[self setupAlertButton:presenters];
		}];
	}];
}

@end

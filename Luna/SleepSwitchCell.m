//
//  SleepSwitchCell.m
//  Sleep Diary
//
//  Created by Alexander Ivanov on 19.04.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "SleepSwitchCell.h"

#import "Global.h"
#import "Widget.h"
#import "Localization.h"

@implementation SleepSwitchCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code

	[self.accessorySwitch addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setupAlertButton:(NSArray<AnalysisPresenter *> *)presenters {
	[UNUserNotificationCenter getPendingNotificationRequestsWithIdentifier:GUI_FALL_ASLEEP completionHandler:^(NSArray<UNNotificationRequest *> *requests) {
		[GCD main:^{
			self.textLabel.text = [Localization goToSleep:requests.firstObject ? requests.firstObject.nextTriggerDate : [GLOBAL alertDate:presenters]];
			self.detailTextLabel.text = requests.firstObject ? [Localization notificationEnabled] : [Localization notificationDisabled];
			self.imageView.highlighted = requests.firstObject != Nil;
			self.accessorySwitch.on = requests.firstObject != Nil;
		}];
	}];
}

- (IBAction)switchAction:(UISwitch *)sender {
	BOOL on = sender.on;

	[AnalysisPresenter query:NSCalendarUnitWeekOfMonth completion:^(NSArray<AnalysisPresenter *> *presenters) {
		if (on)
			[WIDGET scheduleNotification:presenters];
		else
			[UNUserNotificationCenter removePendingNotificationRequestWithIdentifier:GUI_FALL_ASLEEP];

		[GCD queue:GCD_MAIN after:1.0 block:^{
			[self setupAlertButton:presenters];
		}];
	}];
}

@end

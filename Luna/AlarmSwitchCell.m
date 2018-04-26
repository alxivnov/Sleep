//
//  AlarmSwitchCell.m
//  Sleep Diary
//
//  Created by Alexander Ivanov on 26.04.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "AlarmSwitchCell.h"

#import "Global.h"
#import "Widget.h"
#import "Localization.h"

#import "UITableViewCell+Convenience.h"

@implementation AlarmSwitchCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code

//	[self.accessorySwitch addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];

	[self removeSeparators];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setupAlarmButton:(NSArray<AnalysisPresenter *> *)presenters {
	[UNUserNotificationCenter getPendingNotificationRequestsWithIdentifier:GUI_WAKE_UP completionHandler:^(NSArray<UNNotificationRequest *> *requests) {
		[GCD main:^{
			self.textLabel.text = [Localization wakeUp:requests.firstObject ? requests.firstObject.nextTriggerDate : [GLOBAL alarmDate:presenters]];
			self.detailTextLabel.text = requests.firstObject ? [Localization alarmEnabled] : [Localization alarmDisabled];
			self.imageView.highlighted = requests.firstObject != Nil;
			self.accessorySwitch.on = requests.firstObject != Nil;

			[self removeSeparators];
		}];
	}];
}

- (IBAction)switchAction:(UISwitch *)sender {
/*
	BOOL on = sender.on;

	[AnalysisPresenter query:NSCalendarUnitWeekOfMonth completion:^(NSArray<AnalysisPresenter *> *presenters) {
		if (on)
			[WIDGET scheduleNotification:presenters completion:Nil];
		else
			[UNUserNotificationCenter removePendingNotificationRequestWithIdentifier:GUI_FALL_ASLEEP];

		[GCD queue:GCD_MAIN after:1.0 block:^{
			[self setupAlertButton:presenters];
		}];
	}];
*/
}

@end

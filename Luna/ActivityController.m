//
//  ActivityController.m
//  Sleep Diary
//
//  Created by Alexander Ivanov on 22.04.16.
//  Copyright © 2016 Alexander Ivanov. All rights reserved.
//

#import "ActivityController.h"
#import "ActivityVisualizer.h"
#import "AlarmPickerController.h"
#import "Global.h"
#import "Localization.h"
#import "Widget.h"
#import "HKCategorySample+JSON.h"
#import "SleepButtonCell.h"
#import "SleepSwitchCell.h"
#import "AlarmSwitchCell.h"

#import "NSArray+Convenience.h"
#import "NSBundle+Convenience.h"
#import "NSCalendar+Convenience.h"
#import "NSFormatter+Convenience.h"
#import "NSObject+Convenience.h"
#import "NSURLSession+Convenience.h"
#import "UIAlertController+Convenience.h"
#import "UITableView+Convenience.h"
#import "UIView+Convenience.h"
#import "CoreLocation+Convenience.h"
#import "MessageUI+Convenience.h"
#import "UserNotifications+Convenience.h"

@interface ActivityController ()

@end

@implementation ActivityController

- (BOOL)showSwitch {
	return self.startDate.isToday;
}

- (BOOL)showActivity {
	return self.samples.firstObject.allSamples != Nil || self.showButton;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return (self.showButton ? self.showSwitch ? 2 : 1 : 0) + (self.showActivity ? /*self.navigationController.navigationBar.barTintColor*/self.samples.count ? 2 : 1 : 0) + [super numberOfSectionsInTableView:tableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (self.showButton) {
		if (section == 0)
			return 1;

		if (self.showSwitch) {
			if (section == 1)
				return 1;

			section--;
		}

		section--;
	}

	return self.showActivity && section == 0
		? (self.samples.count ? 3 : 1)
		: self.showActivity && section == 2
			? 1
			: [super tableView:tableView numberOfRowsInSection:section];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.showButton && (indexPath.section == 0 || (self.showSwitch && indexPath.section == 1)))
		[cell removeSeparators];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSInteger section = indexPath.section;

	if (self.showButton) {
		if (section == 0) {
			SleepButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Button Cell" forIndexPath:indexPath];
			[cell.button addTarget:self action:@selector(startStopButtonTouchDown:) forControlEvents:UIControlEventTouchDown];
			[cell.button addTarget:self action:@selector(startStopButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];

			[cell setup:self.samples];
			return cell;
		}

		if (self.showSwitch) {
			if (section == 1) {
				if (GLOBAL.asleep) {
					AlarmSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Alarm Cell" forIndexPath:indexPath];
					cell.accessorySwitch.onTintColor = [UIColor color:HEX_NCS_YELLOW];
					[cell setupAlarmButton:self.samples];
					return cell;
				} else {
					SleepSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Alert Cell" forIndexPath:indexPath];
					cell.accessorySwitch.onTintColor = [UIColor color:RGB_DARK_TINT];
					[cell setupAlertButton:self.samples];
					return cell;
				}
			}

			section--;
		}

		section--;
	}

	if (self.showActivity) {
		if (section == 0) {
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:self.samples.count ? (indexPath.row == 0 ? @"Scale Cell" : indexPath.row == 2 ? GUI_BASIC_CELL_ID : GUI_CUSTOM_CELL_ID) : (![HKDataSleepAnalysis isAuthorized] ? @"Health Cell" : @"Empty State Cell") forIndexPath:indexPath];

			if (self.samples.count && indexPath.row == 1) {
				ActivityVisualizer *visualizer = [cell subview:UISubviewKindOfClass(ActivityVisualizer)];

				visualizer.zoom = 0.5 * (GLOBAL.scale ? 2.0 : 1.0);

				if (visualizer.startDate && visualizer.endDate)
					return cell;

				AnalysisPresenter *presenter = cls(AnalysisPresenter, self.samples.firstObject);
				NSDate *startDate = [presenter.endDate dateComponent];
				NSDate *endDate = [startDate addValue:1 forComponent:NSCalendarUnitDay];

				if (/*self.navigationController.navigationBar.barTintColor*/YES) {
					[visualizer loadWithStartDate:startDate endDate:endDate completion:^{
						[UNUserNotificationCenter getPendingNotificationRequestsWithIdentifier:GUI_FALL_ASLEEP completionHandler:^(NSArray<UNNotificationRequest *> *requests) {
							visualizer.fallAsleep = requests.firstObject.nextTriggerDate;
						}];

						[GCD main:^{
							[visualizer scrollRectToVisibleDate:[NSDate date] animated:YES];
						}];
					}];

					visualizer.location = [CLLocationManager defaultManager].location;
				} else {
					NSMutableArray *samples = [NSMutableArray arrayWithCapacity:self.samples.count];
					for (AnalysisPresenter *presenter in self.samples)
						[samples addObjectsFromArray:presenter.allSamples];

					[visualizer setSamples:samples startDate:startDate endDate:endDate];

					[visualizer scrollRectToVisibleDate:startDate animated:YES];
				}
			}

			return cell;
		} else if (section == 2) {
			return [tableView dequeueReusableCellWithIdentifier:@"Mail Cell" forIndexPath:indexPath];
		}
	}

	return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	if (self.showButton) {
		if (section == 0)
			return Nil;

		if (self.showSwitch) {
			if (section == 1)
				return Nil;

			section--;
		}

		section--;
	}

	return section == 2 && self.showActivity ? [Localization mailFooter] : [super tableView:tableView titleForFooterInSection:section];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSInteger section = indexPath.section;

	if (self.showButton) {
		if (section == 0) {
			return;
		}

		if (self.showSwitch) {
			if (section == 1)
				return;

			section--;
		}

		section--;
	}

	if (self.showActivity && section == 0)
		return;

	AnalysisPresenter *sample = idx(self.samples, indexPath.row);
	if (sample.allSamples)
		[(ActivityVisualizer *)[[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:(self.showButton ? 1 : 0) + (self.showSwitch ? 1 : 0)]] subview:UISubviewKindOfClass(ActivityVisualizer)] scrollRectToStartDate:sample.startDate endDate:sample.endDate animated:self.showActivity && section == 2 ? NO : YES];

	if (self.showActivity && section == 2) {
		[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];

		UIImage *screenshot = [self.view snapshotImageAfterScreenUpdates:YES];

		NSData *json = [NSJSONSerialization dataWithJSONObject:@{ @"samples" : [self.samples map:^id(AnalysisPresenter *obj) {
			return [obj.allSamples.firstObject json];
		}] }];

		[self presentMailComposeWithRecipients:arr_(STR_EMAIL) subject:[NSBundle bundleDisplayNameAndShortVersion] body:Nil attachments:json && screenshot ? @{ @"data.txt" : json, @"screenshot.jpg" : [screenshot jpegRepresentation] } : Nil completionHandler:Nil];

		[tableView deselectRowAtIndexPath:indexPath animated:YES];

		return;
	}

	[super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	NSInteger section = indexPath.section;

	if (self.showButton) {
		if (section == 0) {
			return NO;
		}

		if (self.showSwitch) {
			if (section == 1)
				return NO;

			section--;
		}

		section--;
	}

	if (self.showActivity && (section == 0 || section == 2))
		return NO;

	return [super tableView:tableView canEditRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	NSInteger section = indexPath.section;

	if (self.showButton) {
		if (section == 0) {
			return;
		}

		if (self.showSwitch) {
			if (section == 1)
				return;

			section--;
		}

		section--;
	}

	if (self.showActivity && (section == 0 || section == 2))
		return;

	if (editingStyle != UITableViewCellEditingStyleDelete)
		return;

	AnalysisPresenter *presenter = idx(self.samples, indexPath.row);

	[self presentAlertWithTitle:[Localization deleteSample] message:presenter.text cancelActionTitle:[Localization cancel] destructiveActionTitle:[Localization delete] otherActionTitles:Nil completion:^(UIAlertController *instance, NSInteger index) {
		if (index != UIAlertActionDestructive)
			return;

		ActivityVisualizer *visualizer = [[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:(self.showButton ? 1 : 0) + (self.showSwitch ? 1 : 0)]] subview:UISubviewKindOfClass(ActivityVisualizer)];

		HKCategorySample *sample = presenter.allSamples.firstObject;
		if (sample.value == HKCategoryValueSleepAnalysisAsleep)
			visualizer.sleepSamples = [visualizer.sleepSamples query:^BOOL(HKCategorySample *obj) {
				return ![obj.startDate isEqualToDate:sample.startDate] && ![obj.endDate isEqualToDate:sample.endDate];
			}];
		else
			visualizer.inBedSamples = [visualizer.inBedSamples query:^BOOL(HKCategorySample *obj) {
				return ![obj.startDate isEqualToDate:sample.startDate] && ![obj.endDate isEqualToDate:sample.endDate];
			}];

		[idx(self.samples, indexPath.row) deleteSamples:^(BOOL success) {
			if (!success)
				return;

			[self setSamples:[self.samples arrayByRemovingObjectAtIndex:indexPath.row] animated:NO];

			[GCD main:^{
				[tableView beginUpdates];

				[tableView deleteRowAtIndexPath:indexPath];

				if (!self.showActivity) {
					[tableView deleteSection:indexPath.section - 1];

					[tableView deleteSection:indexPath.section + 1];
				}

				[tableView footerViewForSection:indexPath.section].textLabel.text = [self tableView:tableView titleForFooterInSection:indexPath.section];
//				[tableView reloadSection:indexPath.section];

				if (self.showButton)
					[cls(SleepButtonCell, [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]]) setup:self.samples];

				[tableView endUpdates];
			}];
		}];

		[AlarmPickerController updateNotification:Nil];
		[WIDGET updateNotification:Nil];
		[WIDGET updateQuickActions];
	}];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSInteger section = indexPath.section;

	if (self.showButton) {
		if (section == 0) {
			return 320.0;
		}

		if (self.showSwitch) {
			if (section == 1)
				return 56.0;

			section--;
		}

		section--;
	}

	if (self.showActivity && section == 0)
		return indexPath.row == 1 ? 128.0 * (GLOBAL.scale ? 2.0 : 1.0) : (self.samples.count ? 22.0 : 128.0);

	return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	if (!self.startDate || !self.endDate)
		return;

	[AnalysisPresenter query:NSCalendarUnitWeekday startDate:self.startDate endDate:self.endDate completion:^(NSArray<AnalysisPresenter *> *presenters) {
		[self setSamples:presenters animated:YES];
	}];

	[CMMotionActivitySample queryActivityStartingFromDate:self.startDate toDate:self.endDate within:2.0 * TIME_HOUR withHandler:^(NSArray<CMMotionActivitySample *> *activities) {
		NSTimeInterval time = [activities sum:^NSNumber *(CMMotionActivitySample *obj) {
			return obj.type == CMMotionActivityTypeWalking || obj.type == CMMotionActivityTypeRunning || obj.type == CMMotionActivityTypeCycling ? @(obj.duration) : Nil;
		}];
		[GCD main:^{
			self.leftBarButtonItem.title = activities.count ? [Localization activity:time] : Nil;
		}];
	}];

	[[CLLocationManager defaultManager] requestAuthorization:NO];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
	ActivityVisualizer *visualizer = [[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:(self.showButton ? 1 : 0) + (self.showSwitch ? 1 : 0)]] subview:UISubviewKindOfClass(ActivityVisualizer)];

	visualizer.location = manager.location;
}

- (IBAction)scaleButtonAction:(UIButton *)sender {
	[self.tableView beginUpdates];
	GLOBAL.scale = !GLOBAL.scale;
	[self.tableView endUpdates];

	ActivityVisualizer *visualizer = [[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:self.showSwitch ? 2 : 1]] subview:UISubviewKindOfClass(ActivityVisualizer)];
	visualizer.zoom = 0.5 * (GLOBAL.scale ? 2.0 : 1.0);

	[sender setTitle:[NSString stringWithFormat:@"%dX", GLOBAL.scale ? 2 : 1] forState:UIControlStateNormal];

//	[self.tableView reloadRow:1 inSection:0];
}

@end

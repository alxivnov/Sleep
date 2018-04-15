//
//  ActivityController.m
//  Sleep Diary
//
//  Created by Alexander Ivanov on 22.04.16.
//  Copyright © 2016 Alexander Ivanov. All rights reserved.
//

#import "ActivityController.h"
#import "ActivityVisualizer.h"
#import "AlarmController.h"
#import "Global.h"
#import "Localization.h"
#import "Widget.h"
#import "HKCategorySample+JSON.h"

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

- (BOOL)showActivity {
	return self.samples.firstObject.allSamples != Nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return (self.showActivity ? /*self.navigationController.navigationBar.barTintColor*/YES ? 2 : 1 : 0) + [super numberOfSectionsInTableView:tableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.showActivity && section == 0
		? 3
		: self.showActivity && section == 2
			? 1
			: [super tableView:tableView numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.showActivity) {
		if (indexPath.section == 0) {
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:indexPath.row == 0 ? @"Scale Cell" : indexPath.row == 2 ? GUI_BASIC_CELL_ID : GUI_CUSTOM_CELL_ID forIndexPath:indexPath];

			if (indexPath.row == 1) {
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
		} else if (indexPath.section == 2) {
			return [tableView dequeueReusableCellWithIdentifier:@"Mail Cell" forIndexPath:indexPath];
		}
	}

	return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	return section == 2 && self.showActivity ? [Localization mailFooter] : Nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.showActivity && indexPath.section == 0)
		return;

	AnalysisPresenter *sample = idx(self.samples, indexPath.row);
	if (sample.allSamples)
		[(ActivityVisualizer *)[[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]] subview:UISubviewKindOfClass(ActivityVisualizer)] scrollRectToStartDate:sample.startDate endDate:sample.endDate animated:self.showActivity && indexPath.section == 2 ? NO : YES];

	if (self.showActivity && indexPath.section == 2) {
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
	if (self.showActivity && (indexPath.section == 0 || indexPath.section == 2))
		return NO;

	return [super tableView:tableView canEditRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.showActivity && (indexPath.section == 0 || indexPath.section == 2))
		return;

	if (editingStyle != UITableViewCellEditingStyleDelete)
		return;

	AnalysisPresenter *presenter = idx(self.samples, indexPath.row);

	[self presentAlertWithTitle:[Localization deleteSample] message:presenter.text cancelActionTitle:[Localization cancel] destructiveActionTitle:[Localization delete] otherActionTitles:Nil completion:^(UIAlertController *instance, NSInteger index) {
		if (index != UIAlertActionDestructive)
			return;

		ActivityVisualizer *visualizer = [[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]] subview:UISubviewKindOfClass(ActivityVisualizer)];

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
					[tableView deleteSection:0];

					[tableView deleteSection:2];
				}

				[tableView endUpdates];
			}];
		}];

		[AlarmController updateNotification:Nil];
		[WIDGET updateNotification:Nil];
		[WIDGET updateQuickActions];
	}];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.showActivity && indexPath.section == 0)
		return indexPath.row == 1 ? 128.0 * (GLOBAL.scale ? 2.0 : 1.0) : 22.0;

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
	ActivityVisualizer *visualizer = [[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]] subview:UISubviewKindOfClass(ActivityVisualizer)];

	visualizer.location = manager.location;
}

- (IBAction)scaleButtonAction:(UIButton *)sender {
	[self.tableView beginUpdates];
	GLOBAL.scale = !GLOBAL.scale;
	[self.tableView endUpdates];

	ActivityVisualizer *visualizer = [[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]] subview:UISubviewKindOfClass(ActivityVisualizer)];
	visualizer.zoom = 0.5 * (GLOBAL.scale ? 2.0 : 1.0);

	[sender setTitle:[NSString stringWithFormat:@"%dX", GLOBAL.scale ? 2 : 1] forState:UIControlStateNormal];

//	[self.tableView reloadRow:1 inSection:0];
}

@end

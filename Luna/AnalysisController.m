//
//  PressureController.m
//  Sleep Diary
//
//  Created by Alexander Ivanov on 14.07.15.
//  Copyright © 2015 Alexander Ivanov. All rights reserved.
//

#import "AnalysisController.h"
#import "AnalysisPresenter.h"
#import "IntervalController.h"
#import "Global.h"
#import "Localization.h"
#import "StatisticsController.h"

#import "Dispatch+Convenience.h"
#import "NSArray+Convenience.h"
#import "NSObject+Convenience.h"
#import "UIAlertController+Convenience.h"
#import "UIApplication+Convenience.h"
#import "UIBezierPath+Convenience.h"
#import "UIColor+Convenience.h"
#import "UIImage+Convenience.h"
#import "UILabel+Convenience.h"
#import "UIScrollView+Convenience.h"
#import "UITableView+Convenience.h"
#import "UITableViewCell+Convenience.h"
#import "UIViewController+Convenience.h"

#define GUI_SLEEP_CYCLE 5400.0

#define IMG_DISCLOSURE @"disclosure"

@interface AnalysisController () <UITableViewSwipeAccessoryButton>

@end

@implementation AnalysisController

- (void)setSamples:(NSArray<AnalysisPresenter *> *)samples animated:(BOOL)animated {
	_samples = [samples sortedArrayUsingComparator:^NSComparisonResult(AnalysisPresenter *obj1, AnalysisPresenter *obj2) {
		return obj1.isOwn && obj2.isOwn
			? NSOrderedSame
			: obj1.isOwn
				? NSOrderedAscending
				: obj2.isOwn
					? NSOrderedDescending
					: NSOrderedSame;
	}];
	_avg = [_samples vAvg:^NSNumber *(AnalysisPresenter *obj) {
        return obj.allSamples && !IS_ASLEEP(obj.allSamples.firstObject.value) ? Nil : @(obj.duration);
	}];
	_sum = [_samples vSum:^NSNumber *(AnalysisPresenter *obj) {
		return obj.allSamples && !IS_ASLEEP(obj.allSamples.firstObject.value) ? Nil : @(obj.duration);
	}];

	[GCD main:^{
		if (animated)
			[self.tableView reloadData];
	}];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

	if ([[UIApplication sharedApplication].rootViewController forwardSelector:@selector(buttonShapes) nextTarget:UIViewControllerNextTarget(YES)])
		for (UIBarButtonItem *item in self.toolbarItems)
			item.enabled = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.samples.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	AnalysisPresenter *sample = idx(self.samples, indexPath.row);

	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:GUI_CELL_ID forIndexPath:indexPath];

	cell.textLabel.text = sample.text;
	cell.detailTextLabel.text = sample.detailText;

	UIColor *color = sample.allPresenters
        ? [sample.duration < self.avg
			? [UIColor color:HEX_NCS_RED]
			: [UIColor color:HEX_NCS_BLUE] colorWithAlphaComponent:(sample.cycleCount + 1.0) / 6.0]
		: sample.allSamples.firstObject.value == CategoryValueSleepAnalysisAsleepCore
			? [UIColor color:RGB_CORE]
			: sample.allSamples.firstObject.value == CategoryValueSleepAnalysisAsleepDeep
				? [UIColor color:RGB_DEEP]
				: sample.allSamples.firstObject.value == CategoryValueSleepAnalysisAsleepREM
					? [UIColor color:RGB_REM]
					: sample.allSamples.firstObject.value == CategoryValueSleepAnalysisAsleepUnspecified
						? [UIColor color:RGB_DARK_TINT]
						: [UIColor color:HEX_IOS_GRAY];
	NSTimeInterval start = (sample.allPresenters ? 0.0 : [[self.samples arrayWithCount:indexPath.row] vSum:^NSNumber *(AnalysisPresenter *obj) {
		return sample.allSamples.firstObject.value == obj.allSamples.firstObject.value ? @(obj.duration) : Nil;
	}]);
	NSTimeInterval end = start + sample.duration;
	cell.imageView.image = [UIImage imageWithSize:CGSizeMake(22.0, 22.0) draw:^(CGContextRef context) {
		CGContextSetStrokeColorWithColor(context, color.CGColor);

		[[UIBezierPath bezierPathWithArcFrame:CGRectMake(0.0, 0.0, 22.0, 22.0) width:-(64.0 / 580.0) start:start / GLOBAL.sleepDuration end:end / GLOBAL.sleepDuration lineCap:kCGLineCapRound lineJoin:kCGLineJoinRound] stroke];
	}];

//	UIAccessoryView *view = [[UIAccessoryView alloc] initWithFrame:cell.bounds];
//	[view setItems:[NSArray arrayWithObject:[sample.accessoryText labelWithSize:CGSizeMake(36.0, cell.bounds.size.height) options:NSSizeGreaterThan attributes:@{ NSForegroundColorAttributeName : [UIColor color:HEX_IOS_DARK_GRAY] }] /*withObject:sample.allPresenters ? @(-16.0) : Nil */withObject:sample.allPresenters ? [[UIImage originalImage:IMG_DISCLOSURE] imageView] : Nil] adjustWidth:YES];
//	cell.accessoryView = view;
    cell.accessoryViews = [NSArray arrayWithObject:[sample.accessoryText labelWithSize:CGSizeZero/*CGSizeMake(36.0, cell.bounds.size.height)*/ options:NSSizeGreaterThan attributes:@{ NSForegroundColorAttributeName : [UIColor color:HEX_IOS_DARK_GRAY], NSFontAttributeName : [UIFont monospacedDigitSystemFontOfSize:cell.textLabel.font.pointSize weight:UIFontWeightRegular ] }] /*withObject:sample.allPresenters ? @(-16.0) : Nil */withObject:sample.allPresenters ? ({ UIImageView *view = [[UIImage systemImageNamed:@"chevron.right"] imageView:UIViewContentModeCenter]; view.tintColor = [UIColor systemGrayColor]; view; }) : Nil];

	cell.textLabel.textColor = sample.isOwn ? [UIColor whiteColor] : [UIColor lightGrayColor];

	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	AnalysisPresenter *sample = idx(self.samples, indexPath.row);

	if (sample.allPresenters) {
		UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];

		AnalysisController *vc = [[UIStoryboard mainStoryboard] instantiateViewControllerWithIdentifier:@"activity"];
		[vc setSamples:sample.allPresenters animated:NO];
		vc.leftBarButtonItem.title = Nil;
		vc.navigationItem.title = [cell.detailTextLabel.text uppercaseString];
		[self.navigationController pushViewController:vc animated:YES];
	} else if (IS_DEBUGGING) {
		NSArray<CMMotionActivitySample *> *samples = [CMMotionActivitySample samplesFromString:sample.allSamples.firstObject.metadata[HKMetadataKeySampleActivities] date:sample.startDate];
		if (samples) {
			StatisticsController *vc = [[UIStoryboard mainStoryboard] instantiateViewControllerWithIdentifier:@"statistics"];
			vc.samples = samples;
			[self.navigationController pushViewController:vc animated:YES];
		}
	}

	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return idx(self.samples, indexPath.row).canDeleteSamples;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle != UITableViewCellEditingStyleDelete)
		return;

	AnalysisPresenter *sample = idx(self.samples, indexPath.row);

	[self presentAlertWithTitle:[Localization deleteSample] message:sample.text cancelActionTitle:[Localization cancel] destructiveActionTitle:[Localization delete] otherActionTitles:Nil completion:^(UIAlertController *instance, NSInteger index) {
		if (index != UIAlertActionDestructive)
			return;
		
		[sample deleteSamples:^(BOOL success) {
			if (!success)
				return;

			[self setSamples:[self.samples arrayByRemovingObjectAtIndex:indexPath.row] animated:NO];

			[GCD main:^{
				[tableView deleteRowAtIndexPath:indexPath];
			}];
		}];
	}];
}

- (IBAction)cancel:(UIStoryboardSegue *)segue {

}

- (NSString *)tableView:(UITableView *)tableView titleForSwipeAccessoryButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
	return idx(self.samples, indexPath.row).allSamples.firstObject.value == HKCategoryValueSleepAnalysisInBed ? [Localization change] : Nil;
}

- (void)tableView:(UITableView *)tableView swipeAccessoryButtonPushedForRowAtIndexPath:(NSIndexPath *)indexPath {
	UIViewController *vc = [[UIStoryboard mainStoryboard] instantiateViewControllerWithIdentifier:GUI_INTERVAL];

	sel_(vc.lastViewController, setSample:, self.samples[indexPath.row]);

	[self presentViewController:vc animated:YES completion:^{
		[tableView deselectRowAtIndexPath:indexPath animated:NO];
	}];
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (![self tableView:tableView canEditRowAtIndexPath:indexPath])
		return Nil;

	__block AnalysisController *__self = self;
	return [NSArray arrayWithObject:[UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:[Localization delete] handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
		[__self tableView:__self.tableView commitEditingStyle:UITableViewCellEditingStyleDelete forRowAtIndexPath:indexPath];
	}] withObject:[self tableView:tableView titleForSwipeAccessoryButtonForRowAtIndexPath:indexPath] ? [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:[self tableView:tableView titleForSwipeAccessoryButtonForRowAtIndexPath:indexPath] handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
		[__self tableView:__self.tableView swipeAccessoryButtonPushedForRowAtIndexPath:indexPath];
	}] : Nil];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return section == 0 && _samples.count && [_samples any:^BOOL(AnalysisPresenter *obj) {
		return obj.allPresenters != Nil;
	}] ? [Localization average:_avg] : Nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	return section == 1 && _samples.count && ![_samples any:^BOOL(AnalysisPresenter *obj) {
		return obj.allPresenters != Nil;
	}] ? [Localization total:_sum] : Nil;
}

@end

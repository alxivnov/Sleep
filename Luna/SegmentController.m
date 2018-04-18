//
//  SegmentController.m
//  Sleep Diary
//
//  Created by Alexander Ivanov on 09/03/16.
//  Copyright © 2016 Alexander Ivanov. All rights reserved.
//

#import "SegmentController.h"
#import "AnalysisPresenter.h"
#import "Global.h"
#import "Widget.h"
#import "AlarmController.h"

#import "NSFormatter+Convenience.h"
#import "UITableView+Convenience.h"

#define KEY_SELECTED_SEGMENT_INDEX @"AnalysisController.segment.selectedSegmentIndex"

@interface SegmentController ()
@property (strong, nonatomic, readonly) NSDateIntervalFormatter *formatter;

@property (weak, nonatomic) IBOutlet UISegmentedControl *segment;

@property (strong, nonatomic) IBOutlet UIView *emptyState0;
@property (strong, nonatomic) IBOutlet UIView *emptyState1;
@end

@implementation SegmentController

__synthesize(NSDateIntervalFormatter *, formatter, [[NSDateIntervalFormatter alloc] initWithDateStyle:NSDateIntervalFormatterMediumStyle timeStyle:NSDateIntervalFormatterNoStyle])

- (void)setup:(NSInteger)index {
	[AnalysisPresenter query:index == 1 ? NSCalendarUnitMonth : index == 2 ? NSCalendarUnitYear : NSCalendarUnitWeekOfMonth completion:^(NSArray<AnalysisPresenter *> *presenters) {
		[self setSamples:presenters animated:YES];
	}];

	NSDate *date = [NSDate date];
	self.navigationItem.title = index == 1 ? [[NSDateFormatter defaultFormatter] monthSymbolForDate:date] : index == 2 ? [date descriptionWithFormat:@"yyyy" calendar:Nil] : [self.formatter stringFromDate:[date addValue:-1 forComponent:NSCalendarUnitWeekOfYear] toDate:date];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.

	self.navigationItem.leftBarButtonItems.firstObject.enabled = GLOBAL.isAuthorized.boolValue;

	self.segment.selectedSegmentIndex = [[[NSUserDefaults standardUserDefaults] objectForKey:KEY_SELECTED_SEGMENT_INDEX] integerValue];

	[self setup:self.segment.selectedSegmentIndex];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSInteger numberOfRowsInSection = [super tableView:tableView numberOfRowsInSection:section];

	self.tableView.emptyState = self.showActivity ? Nil : numberOfRowsInSection == 0 ? self.emptyState0 : numberOfRowsInSection == 1 ? self.emptyState1 : Nil;

	return numberOfRowsInSection;
}

- (IBAction)save:(UIStoryboardSegue *)segue {
	[AlarmController updateNotification:Nil];
	[WIDGET updateNotification:Nil];
	[WIDGET updateQuickActions];

	[self setup:self.segment.selectedSegmentIndex];
}

- (IBAction)addAction:(UIBarButtonItem *)sender {
	[self performSegueWithIdentifier:GUI_INTERVAL sender:sender];
}

- (IBAction)segmentValueChanged:(UISegmentedControl *)sender {
	[self setup:sender.selectedSegmentIndex];

	[[NSUserDefaults standardUserDefaults] setObject:@(sender.selectedSegmentIndex) forKey:KEY_SELECTED_SEGMENT_INDEX];
}

@end

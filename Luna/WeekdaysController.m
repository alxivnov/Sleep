//
//  WeekdaysController.m
//  Sleep Diary
//
//  Created by Alexander Ivanov on 18.04.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "WeekdaysController.h"

#import "Global.h"
#import "AnalysisPresenter.h"

#import "UIBezierPath+Convenience.h"
#import "UIButton+Convenience.h"
#import "UIViewController+Convenience.h"

#import "SleepButtonCell.h"
#import "SleepSwitchCell.h"
#import "AlarmSwitchCell.h"

@interface WeekdaysController ()
@property (weak, nonatomic) IBOutlet UIButton *sunButton;
@property (weak, nonatomic) IBOutlet UIButton *monButton;
@property (weak, nonatomic) IBOutlet UIButton *tueButton;
@property (weak, nonatomic) IBOutlet UIButton *wedButton;
@property (weak, nonatomic) IBOutlet UIButton *thuButton;
@property (weak, nonatomic) IBOutlet UIButton *friButton;
@property (weak, nonatomic) IBOutlet UIButton *satButton;

@property (strong, nonatomic) NSArray<AnalysisPresenter *> *weekdays;
@property (strong, nonatomic) NSArray<UIButton *> *weekButtons;
@property (strong, nonatomic) NSArray<CAShapeLayer *> *weekLayers;
@end

@implementation WeekdaysController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

	[self setupAlertView:Nil];
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

- (NSArray<UIButton *> *)weekButtons {
	if (!_weekButtons)
		_weekButtons = @[ self.sunButton, self.monButton, self.tueButton, self.wedButton, self.thuButton, self.friButton, self.satButton ];

	return _weekButtons;
}

- (void)setWeekdays:(NSArray<AnalysisPresenter *> *)weekdays {
	if ([_weekdays isEqualToArray:weekdays block:^BOOL(AnalysisPresenter *obj, AnalysisPresenter *otherObj) {
		return [obj.startDate isEqualToDate:otherObj.startDate];
	}])
		return;

	_weekdays = weekdays;

	NSArray *weekLayers = [weekdays map:^id(AnalysisPresenter *obj) {
		NSTimeInterval duration = obj.duration;
		NSUInteger cycleCount = obj.cycleCount;

		return [[UIBezierPath bezierPathWithArcFrame:CGRectMake(0.0, 0.0, 40.0, 40.0)/*self.weekButtons.firstObject.bounds*/ width:-(64.0 / 580.0) start:0.0 end:duration / GLOBAL.sleepDuration lineCap:kCGLineCapRound lineJoin:kCGLineJoinRound] layerWithStrokeColors:@[ [[UIColor color:RGB_DARK_TINT] colorWithAlphaComponent:(cycleCount + 1.0) / 6.0] ] fillColor:Nil lineWidth:4.0];
#warning Remove constant!
	}];

	self.weekLayers = weekLayers;
}

- (void)setWeekLayers:(NSArray<CAShapeLayer *> *)weekLayers {
	for (CAShapeLayer *layer in _weekLayers)
		[layer removeFromSuperlayer];

	_weekLayers = weekLayers;

	for (NSUInteger index = 0; index < self.weekButtons.count && index < weekLayers.count; index++) {
		[self.weekButtons[index].layer addSublayer:weekLayers[index]];

		//		[weekLayers[index] addAnimationWithDuration:CAAnimationDurationM fromValue:@0 toValue:@1 forKey:CALayerKeyStrokeEnd];
	}
}

- (void)setup {
	[self setupAlertView:Nil];
}

- (void)setupAlertView:(void(^)(BOOL))completion {
	NSDate *now = [NSDate date];
	NSDate *today = [now dateComponent];
	NSUInteger weekday = [now weekday];
	NSUInteger firstWeekday = [NSDate firstWeekday];
	if (firstWeekday == 1 && weekday == 0)
		weekday = 7;

	[AnalysisPresenter query:NSCalendarUnitWeekOfMonth completion:^(NSArray<AnalysisPresenter *> *presenters) {
		NSDictionary<NSDate *, AnalysisPresenter *> *days = [presenters dictionaryWithKey:^id<NSCopying>(AnalysisPresenter *obj) {
			return [obj.endDate dateComponent];
		}];

		NSArray<AnalysisPresenter *> *weekdays = [NSArray arrayFromCount:7 block:^id(NSUInteger index) {
			return days[[today addValue:firstWeekday - weekday + index forComponent:NSCalendarUnitDay]] ?: [AnalysisPresenter new];
		}];

		NSTimeInterval inBed = [days[today].allPresenters sum:^NSNumber *(AnalysisPresenter *obj) {
			return obj.allSamples.firstObject.value == HKCategoryValueSleepAnalysisInBed ? @(obj.duration) : Nil;
		}];
		[GCD main:^{
			for (NSUInteger index = 0; index < self.weekButtons.count; index++) {
				NSUInteger day = index + firstWeekday;
				self.weekButtons[index].enabled = day <= weekday;

				if (day >= self.weekButtons.count)
					day -= self.weekButtons.count;
				[self.weekButtons[index] setTitle:[NSCalendar currentCalendar].shortWeekdaySymbols[day].uppercaseString];

			}

			UITableViewController *vc = cls(UITableViewController, self.viewControllers.firstObject);
			if ([self.weekdays isEqualToArray:weekdays block:^BOOL(AnalysisPresenter *obj, AnalysisPresenter *otherObj) {
				return [obj.startDate isEqualToDate:otherObj.startDate];
			}]) {
				SleepButtonCell *buttonCell = cls(SleepButtonCell, [vc.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]]);
				[buttonCell setSleepDuration:days[today].duration inBedDuration:inBed cycleCount:presenters.firstObject.cycleCount animated:YES];

				UITableViewCell *cell = [vc.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
				[cls(SleepSwitchCell, cell) setupAlertButton:presenters];
				[cls(AlarmSwitchCell, cell) setupAlarmButton:presenters];

				self.navigationItem.prompt = vc.navigationItem.prompt;

			} else {
				self.weekdays = weekdays;

				self.dates = [NSArray arrayFromCount:weekday - firstWeekday + 1 block:^id(NSUInteger index) {
					return [today addValue:firstWeekday - weekday + index forComponent:NSCalendarUnitDay];
				}];

				[vc.tableView reloadData];
			}

			if (completion)
				completion(presenters.count > 0);
		}];
	}];
}

- (IBAction)weekdayButtonAction:(UIButton *)sender {
	NSUInteger index = [self.weekButtons indexOfObject:sender];

	[self setCurrentPage:index animated:YES completion:Nil];
}

@end

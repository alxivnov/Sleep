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

@property (weak, nonatomic) IBOutlet UIButton *alertButton;
@end

@implementation AlertController

- (NSNumber *)buttonShapes {
	return [self.alertButton.titleLabel.attributedText attributesAtIndex:0 effectiveRange:Nil][NSUnderlineStyleAttributeName];
}

- (NSArray<UIButton *> *)weekButtons {
	if (!_weekButtons)
		_weekButtons = @[ self.sunButton, self.monButton, self.tueButton, self.wedButton, self.thuButton, self.friButton, self.satButton ];

	return _weekButtons;
}

- (void)setWeekdays:(NSArray<AnalysisPresenter *> *)weekdays {
	if ([_weekdays isEqualToArray:weekdays block:^BOOL(AnalysisPresenter *obj, AnalysisPresenter *otherObj) {
		return obj.duration == otherObj.duration;
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
			[self setSleepDuration:days[today].duration inBedDuration:inBed cycleCount:presenters.firstObject.cycleCount animated:YES];

			for (NSUInteger index = 0; index < self.weekButtons.count; index++) {
				NSUInteger day = index + firstWeekday;
				self.weekButtons[index].enabled = day <= weekday;

				if (day >= self.weekButtons.count)
					day -= self.weekButtons.count;
				[self.weekButtons[index] setTitle:[NSCalendar currentCalendar].shortWeekdaySymbols[day].uppercaseString];

			}
			self.weekdays = weekdays;

			[self setupAlertButton:presenters];

			if (completion)
				completion(presenters.count > 0);
		}];
	}];
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

- (IBAction)weekdayButtonAction:(UIButton *)sender {
	NSUInteger index = [self.weekButtons indexOfObject:sender];

	UINavigationController *navigationController = [[UIStoryboard mainStoryboard] instantiateViewControllerWithIdentifier:@"activities"];
	sel_(navigationController.topViewController, setWeekday:, @(index));
	[self presentViewController:navigationController animated:YES completion:Nil];
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

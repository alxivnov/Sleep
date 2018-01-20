//
//  TodayViewController.m
//  Widget
//
//  Created by Alexander Ivanov on 06.04.15.
//  Copyright (c) 2015 Alexander Ivanov. All rights reserved.
//

#import "TodayViewController.h"
#import "AnalysisPresenter.h"
#import "Global.h"

#import "Dispatch+Convenience.h"
#import "NSCalendar+Convenience.h"
#import "NSFormatter+Convenience.h"
#import "NSTimer+Convenience.h"
#import "NSURL+Convenience.h"
#import "UIGestureRecognizer+Convenience.h"
#import "UIView+Convenience.h"

@import NotificationCenter;

@interface TodayViewController () <NCWidgetProviding>
@property (weak, nonatomic) IBOutlet UIImageView *image;
@property (weak, nonatomic) IBOutlet UILabel *label;

@property (assign, nonatomic) NSTimeInterval duration;

@property (strong, nonatomic, readonly) NSSelectorTimer *timer;
@end

@implementation TodayViewController

- (NSTimeInterval)duration {
	if (GLOBAL.asleep) {
		NSDate *now = [NSDate date];

		NSTimeInterval duration = [now timeIntervalSinceDate:GLOBAL.startDate];

		return now.timeComponent > 22.0 * TIME_HOUR ? duration : _duration + duration;
	} else {
		return _duration;
	}
}

__synthesize(NSSelectorTimer *, timer, [NSSelectorTimer create:^{
	self.label.text = [[NSDateComponentsFormatter hhmmssFormatter] stringFromTimeInterval:self.duration];
} interval:1.0])

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view from its nib.

	[self.view addTapWithTarget:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    // Perform any setup necessary in order to update the view.
    
    // If an error is encountered, use NCUpdateResultFailed
    // If there's no update required, use NCUpdateResultNoData
    // If there's an update, use NCUpdateResultNewData

	if (GLOBAL.asleep) {
		self.image.highlighted = YES;

		self.label.textColor = [UIColor whiteColor];

		self.timer.enabled = YES;
	} else {
		self.image.highlighted = NO;

		self.label.textColor = [UIColor lightTextColor];

		self.timer.enabled = NO;
	}

	[AnalysisPresenter query:NSCalendarUnitDay completion:^(NSArray<AnalysisPresenter *> *presenters) {
		self.duration = presenters.firstObject.duration;

		[GCD main:^{
			self.label.text = [[NSDateComponentsFormatter hhmmssFormatter] stringFromTimeInterval:self.duration];

			completionHandler(NCUpdateResultNewData);
		}];
	}];
}

- (UIEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(UIEdgeInsets)defaultMarginInsets {
	defaultMarginInsets.left = 0.0;
	defaultMarginInsets.bottom = 0.0;
	
	return defaultMarginInsets;
}

- (void)tap:(UIGestureRecognizer *)sender {
	[self.view blink:[UIColor lightTextColor] duration:-1.0 completion:Nil];
	
	NSURL *url = [NSURL urlWithScheme:URL_SCHEME andParameters:Nil];
	
	[[self extensionContext] openURL:url completionHandler:Nil];
}

@end

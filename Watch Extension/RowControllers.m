//
//  RowControllers.m
//  Watch Extension
//
//  Created by Alexander Ivanov on 17.04.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "RowControllers.h"


@interface ButtonRowController ()
@property (strong, nonatomic, readonly) ExtensionDelegate *delegate;
@end


@implementation ButtonRowController

- (ExtensionDelegate *)delegate {
	return [WKExtension sharedExtension].delegate;
}

- (void)setup {
	[self.group setBackgroundImageNamed:self.delegate.startDate ? IMG_BACK_FILL : IMG_BACK_LINE];

	[self.image setImage:self.delegate.image];

	if (self.delegate.startDate) {
		[self.timer setDate:self.delegate.startDate];
		[self.timer start];
	} else {
		[self.timer setInterval:self.delegate.sleepDuration];
		[self.timer stop];
	}
	[self.timer setTextColor:self.delegate.startDate ? [UIColor whiteColor] : [UIColor color:RGB_LIGHT_TINT]];

	[self.label setText:self.delegate.startDate ? loc(@"wake up") : loc(@"bedtime")];
	[self.label setTextColor:self.delegate.startDate ? [UIColor lightGrayColor] : [UIColor color:RGB_DARK_TINT]];
}

- (IBAction)buttonAction {
	self.delegate.startDate = self.delegate.startDate ? Nil : [NSDate date];

	[self setup];

	[[CLKComplicationServer sharedInstance] reloadTimeline:Nil];

	[[WCSessionDelegate instance].reachableSession sendMessage:@{ KEY_TIMER_START : [self.delegate.startDate serialize] ?: STR_EMPTY } replyHandler:^(NSDictionary<NSString *, id> *replyMessage) {
		NSDate *date = [NSDate deserialize:replyMessage[KEY_TIMER_START]];
		if (eql(self.delegate.startDate, date))
			return;

		self.delegate.startDate = date;

		[GCD main:^{
			[self setup];
		}];

		[[CLKComplicationServer sharedInstance] reloadTimeline:Nil];
	}];
}

@end


@implementation InBedRowController

- (void)setPresenter:(AnalysisPresenter *)presenter {
	[self.textLabel setText:presenter.text];
	[self.detailTextLabel setText:presenter.accessoryText];
}

- (void)setSample:(HKCategorySample *)sample {
	[self.textLabel setText:[NSString stringWithFormat:@"%@ - %@", [sample.startDate descriptionForTime:NSDateFormatterShortStyle], [sample.endDate descriptionForTime:NSDateFormatterShortStyle]]];
	[self.detailTextLabel setText:[[NSDateComponentsFormatter hhmmFormatter] stringFromTimeInterval:sample.duration]];
}

@end


@implementation SleepRowController

- (void)setPresenter:(AnalysisPresenter *)presenter {
	[self.textLabel setText:presenter.text];
	[self.detailTextLabel setText:presenter.accessoryText];
}

- (void)setSample:(HKCategorySample *)sample {
	[self.textLabel setText:[NSString stringWithFormat:@"%@ - %@", [sample.startDate descriptionForTime:NSDateFormatterShortStyle], [sample.endDate descriptionForTime:NSDateFormatterShortStyle]]];
	[self.detailTextLabel setText:[[NSDateComponentsFormatter hhmmFormatter] stringFromTimeInterval:sample.duration]];
}

@end


@implementation ImageRowController

- (void)setDate:(NSDate *)date {
	[self.textLabel setText:[date descriptionForTime:NSDateFormatterShortStyle]];
}

@end

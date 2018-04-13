//
//  InterfaceController.m
//  Watch Extension
//
//  Created by Alexander Ivanov on 08.04.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "InterfaceController.h"

#import "ExtensionDelegate.h"

#warning Autodetect

#warning Phone update on wake up from watch
#warning Phone update on first fall asleep from watch

#warning Fix freeze on switching to Samples scane

#warning Alarm/Alert in Sunrise

@interface InterfaceController ()
@property (strong, nonatomic, readonly) ExtensionDelegate *delegate;

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceGroup *group;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceImage *image;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceTimer *timer;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *label;
@end


@implementation InterfaceController

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

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // Configure interface objects here.
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];

	[self setup];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

- (IBAction)buttonAction {
	self.delegate.startDate = self.delegate.startDate ? Nil : [NSDate date];

	[self setup];

	[[CLKComplicationServer sharedInstance] reloadTimeline:Nil];

	[[WCSessionDelegate instance].reachableSession sendMessage:@{ KEY_TIMER_START : [self.delegate.startDate serialize] ?: STR_EMPTY } replyHandler:^(NSDictionary<NSString *, id> *replyMessage) {
		NSDate *date = [NSDate deserialize:replyMessage[KEY_TIMER_START]];
		if (NSDateIsEqualToDate(self.delegate.startDate, date))
			return;

		self.delegate.startDate = date;

		[GCD main:^{
			[self setup];
		}];

		[[CLKComplicationServer sharedInstance] reloadTimeline:Nil];
	}];
}

@end




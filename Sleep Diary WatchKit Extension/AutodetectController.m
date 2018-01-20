//
//  AutodetectController.m
//  Sleep Diary
//
//  Created by Alexander Ivanov on 19.12.16.
//  Copyright © 2016 Alexander Ivanov. All rights reserved.
//

#import "AutodetectController.h"
#import "Defaults.h"
#import "Global.h"
#import "Localization.h"

#import "NSCalendar+Convenience.h"
#import "NSFormatter+Convenience.h"

@interface AutodetectController ()
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *headlineLabel;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *intervalLabel;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *durationLabel;

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceButton *saveButton;

@property (strong, nonatomic) NSDate *startDate;
@property (strong, nonatomic) NSDate *endDate;
@end

@implementation AutodetectController

- (void)awakeWithContext:(id)context {
	[super awakeWithContext:context];

	NSArray<NSDate *> *dates = cls(NSArray, context);
	self.startDate = idx(dates, 0);
	self.endDate = idx(dates, 1);

	[self.intervalLabel setText:[NSString stringWithFormat:@"%@ - %@", [self.startDate descriptionForTime:NSDateFormatterShortStyle], [self.endDate descriptionForTime:NSDateFormatterShortStyle]]];
	[self.durationLabel setText:[[NSDateComponentsFormatter hhmmFormatter] stringFromTimeInterval:[self.endDate timeIntervalSinceDate:self.startDate]]];

	[self.saveButton setEnabled:self.startDate && self.endDate];

	[self.headlineLabel setText:[Localization wereYouAsleep]];
	[self.saveButton setTitle:[Localization save]];
	[self setTitle:[Localization cancel]];
}

- (IBAction)saveAction {
	[Defaults saveSampleWithStartDate:self.startDate endDate:self.endDate sleepLatency:GLOBAL.sleepLatency adaptive:NO completion:^(BOOL success) {
		[self dismissController];
	}];
}

- (IBAction)cancelAction {
	[self dismissController];
}

@end

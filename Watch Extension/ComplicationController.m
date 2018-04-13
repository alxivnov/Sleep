//
//  ComplicationController.m
//  Watch Extension
//
//  Created by Alexander Ivanov on 08.04.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "ComplicationController.h"

#import "ExtensionDelegate.h"

#define STR_FORMAT @"%@, %@: %@"

#define IMG_MOON_LINE_18	@"moon-line-128"
#define IMG_MOON_FILL_18	@"moon-fill-128"

@interface ComplicationController ()
@property (strong, nonatomic, readonly) ExtensionDelegate *delegate;
@end

@implementation ComplicationController

- (ExtensionDelegate *)delegate {
	return [WKExtension sharedExtension].delegate;
}

#pragma mark - Timeline Configuration

- (void)getSupportedTimeTravelDirectionsForComplication:(CLKComplication *)complication withHandler:(void(^)(CLKComplicationTimeTravelDirections directions))handler {
//	handler(CLKComplicationTimeTravelDirectionForward|CLKComplicationTimeTravelDirectionBackward);
	handler(CLKComplicationTimeTravelDirectionNone);
}

- (void)getTimelineStartDateForComplication:(CLKComplication *)complication withHandler:(void(^)(NSDate * __nullable date))handler {
    handler(nil);
}

- (void)getTimelineEndDateForComplication:(CLKComplication *)complication withHandler:(void(^)(NSDate * __nullable date))handler {
    handler(nil);
}

- (void)getPrivacyBehaviorForComplication:(CLKComplication *)complication withHandler:(void(^)(CLKComplicationPrivacyBehavior privacyBehavior))handler {
    handler(CLKComplicationPrivacyBehaviorShowOnLockScreen);
}

#pragma mark - Timeline Population

- (void)getCurrentTimelineEntryForComplication:(CLKComplication *)complication withHandler:(void(^)(CLKComplicationTimelineEntry * __nullable))handler {
    // Call the handler with the current timeline entry
//	handler(nil);

	CLKComplicationTemplate *template = [CLKComplicationTemplate createWithFamily:complication.family member:CLKComplicationFamilyMemberStackImage];

	NSDate *today = [NSDate date].dateComponent;
/*	NSArray<HKCategorySample *> *samples = [self.delegate.samples[today] query:^BOOL(HKCategorySample *obj) {
		return obj.value == HKCategoryValueSleepAnalysisAsleep;
	}];
*/
	if (template) {
		if (self.delegate.startDate) {
			CLKTextProvider *text = [CLKRelativeDateTextProvider textProviderWithDate:self.delegate.startDate style:CLKRelativeDateStyleTimer units:NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond];
			NSDate *date = [self.delegate alarmDate];
			if (complication.family == CLKComplicationFamilyUtilitarianLarge && date)
				[template setText:[CLKTextProvider textProviderWithFormat:STR_FORMAT, text, loc(@"wake up"), [date descriptionForTime:NSDateFormatterShortStyle]]];
			else
				[template setText:text];

			[template setImage:[UIImage image:IMG_MOON_FILL_18] tintColor:Nil];

			handler([CLKComplicationTimelineEntry entryWithDate:self.delegate.startDate complicationTemplate:template]);
		} else if (self.delegate.presenters.count) {
			NSString *text = [[NSDateComponentsFormatter hhmmFormatter] stringFromTimeInterval:self.delegate.sleepDuration];
			NSDate *date = [self.delegate alertDate];
			if (complication.family == CLKComplicationFamilyUtilitarianLarge && date)
				[template setText:[CLKTextProvider textProviderWithFormat:STR_FORMAT, text, loc(@"bedtime"), [date descriptionForTime:NSDateFormatterShortStyle]]];
			else
				[template setText:[CLKSimpleTextProvider textProviderWithText:text]];

			[template setImage:[UIImage image:IMG_MOON_LINE_18] tintColor:Nil];

			handler(text ? [CLKComplicationTimelineEntry entryWithDate:self.delegate.presenters[today].endDate complicationTemplate:template] : Nil);
		}
	} else {
		handler(Nil);
	}
}

- (void)getTimelineEntriesForComplication:(CLKComplication *)complication beforeDate:(NSDate *)date limit:(NSUInteger)limit withHandler:(void(^)(NSArray<CLKComplicationTimelineEntry *> * __nullable entries))handler {
    // Call the handler with the timeline entries prior to the given date
    handler(nil);
}

- (void)getTimelineEntriesForComplication:(CLKComplication *)complication afterDate:(NSDate *)date limit:(NSUInteger)limit withHandler:(void(^)(NSArray<CLKComplicationTimelineEntry *> * __nullable entries))handler {
    // Call the handler with the timeline entries after to the given date
    handler(nil);
}

#pragma mark - Placeholder Templates

- (void)getLocalizableSampleTemplateForComplication:(CLKComplication *)complication withHandler:(void(^)(CLKComplicationTemplate * __nullable complicationTemplate))handler {
    // This method will be called once per supported complication, and the results will be cached
//	handler(nil);

	CLKComplicationTemplate *template = [CLKComplicationTemplate createWithFamily:complication.family member:CLKComplicationFamilyMemberStackImage];

	[template setText:@"7:15" shortText:Nil];
	[template setImage:[UIImage image:IMG_MOON_FILL_18] tintColor:Nil];

	handler(template);
}

@end

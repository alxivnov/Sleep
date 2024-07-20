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

#define IMG_MOON_LINE_16	@"moon-line-16"
#define IMG_MOON_FILL_16	@"moon-fill-16"
#define IMG_MOON_LINE_128	@"moon-line-128"
#define IMG_MOON_FILL_128	@"moon-fill-128"

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

	CLKComplicationTemplate *template = [CLKComplicationTemplate createWithFamily:complication.family member:complication.family == CLKComplicationFamilyGraphicCircular ? CLKComplicationFamilyMemberRingImage : CLKComplicationFamilyMemberStackImage];

	NSDate *today = [NSDate date].dateComponent;
/*	NSArray<HKCategorySample *> *samples = [self.delegate.samples[today] query:^BOOL(HKCategorySample *obj) {
		return IS_ASLEEP(obj.value);
	}];
*/
	if (template) {
		float duration = self.delegate.sleepDuration / 8.0 / 60.0 / 60.0;
		
		if (self.delegate.startDate) {
			CLKTextProvider *text = [CLKRelativeDateTextProvider textProviderWithDate:self.delegate.startDate style:CLKRelativeDateStyleTimer units:NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond];
			NSDate *date = [self.delegate alarmDate];
			if (complication.family == CLKComplicationFamilyUtilitarianLarge && date)
				[template setText:[CLKTextProvider textProviderWithFormat:STR_FORMAT, text, loc(@"wake up"), [date descriptionForTime:NSDateFormatterShortStyle]]];
			else
				[template setText:text];
			
			[template setFill:duration tintColor:[UIColor color:RGB_DARK_TINT]];
			[template setImage:[UIImage image:IMG_MOON_FILL_16] tintColor:[UIColor color:RGB_DARK_TINT]];

			handler([CLKComplicationTimelineEntry entryWithDate:self.delegate.startDate complicationTemplate:template]);
		} else /*if (self.delegate.presenters.count)*/ {
			NSString *text = [[NSDateComponentsFormatter hhmmFormatter] stringFromTimeInterval:self.delegate.sleepDuration];
			NSDate *date = [self.delegate alertDate];
			if (complication.family == CLKComplicationFamilyUtilitarianLarge && date)
				[template setText:[CLKTextProvider textProviderWithFormat:STR_FORMAT, text, loc(@"bedtime"), [date descriptionForTime:NSDateFormatterShortStyle]]];
			else
				[template setText:[CLKSimpleTextProvider textProviderWithText:text]];
			
			[template setFill:duration tintColor:[UIColor color:RGB_DARK_TINT]];
			[template setImage:[UIImage image:IMG_MOON_LINE_16] tintColor:[UIColor color:RGB_DARK_TINT]];

			handler(/*text ? */[CLKComplicationTimelineEntry entryWithDate:self.delegate.presenters[today].endDate ?: [NSDate date] complicationTemplate:template]/* : Nil*/);
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

	CLKComplicationTemplate *template = [CLKComplicationTemplate createWithFamily:complication.family member:complication.family == CLKComplicationFamilyGraphicCircular ? CLKComplicationFamilyMemberRingImage : CLKComplicationFamilyMemberStackImage];

	[template setText:@"7:15" shortText:Nil];
	[template setFill:7.25 / 8.0 tintColor:[UIColor color:RGB_DARK_TINT]];
	[template setImage:[UIImage image:IMG_MOON_FILL_16] tintColor:[UIColor color:RGB_DARK_TINT]];

	handler(template);
}

@end

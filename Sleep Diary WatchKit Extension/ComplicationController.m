//
//  ComplicationController.m
//  Sleep Diary
//
//  Created by Alexander Ivanov on 02/06/16.
//  Copyright © 2016 Alexander Ivanov. All rights reserved.
//

#import "ComplicationController.h"
#import "AnalysisPresenter.h"
#import "Defaults.h"
#import "Global+Notifications.h"
#import "Localization.h"

#import "NSCalendar+Convenience.h"
#import "NSFormatter+Convenience.h"
#import "NSObject+Convenience.h"
#import "ClockKit+Convenience.h"

#define DATA [Defaults instance]

@interface ComplicationController ()
@property (strong, nonatomic, readonly) UIImage *moonFill;
@property (strong, nonatomic, readonly) UIImage *moonLine;
@end

@implementation ComplicationController

__synthesize(UIImage *, moonFill, [UIImage imageNamed:IMG_MOON_FILL])
__synthesize(UIImage *, moonLine, [UIImage imageNamed:IMG_MOON_LINE])
/*
- (void)setupIfNeeded:(void(^)(MessageCache *cache))handler {
	MessageCache *cache = [MessageCache instance];

	if (handler && cache.startDate)
		handler(cache);
	else
		[[PhoneDelegate instance].reachableSession sendMessage:@{ } replyHandler:^(NSDictionary<NSString *,id> *replyMessage) {
			[cache loadDictionary:replyMessage];

			if (handler)
				handler(cache);
		}];
}
*/
- (void)getSupportedTimeTravelDirectionsForComplication:(CLKComplication *)complication withHandler:(void (^)(CLKComplicationTimeTravelDirections))handler {
	handler(CLKComplicationTimeTravelDirectionNone);
}

- (void)getCurrentTimelineEntryForComplication:(CLKComplication *)complication withHandler:(void (^)(CLKComplicationTimelineEntry * _Nullable))handler {
	CLKComplicationTemplate *template = [CLKComplicationTemplate createWithFamily:complication.family member:CLKComplicationFamilyMemberStackImage];

	if (template)
		[AnalysisPresenter query:NSCalendarUnitWeekOfMonth completion:^(NSArray<AnalysisPresenter *> *presenters) {
			if (DATA.asleep) {
				CLKTextProvider *text = [CLKRelativeDateTextProvider textProviderWithDate:DATA.startDate style:CLKRelativeDateStyleTimer units:NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond];
				NSDate *date = [GLOBAL alarmDate:presenters];
				if (complication.family == CLKComplicationFamilyUtilitarianLarge && date)
					[template setText:[CLKTextProvider textProviderWithFormat:[Localization watchWakeUp], text, [date descriptionForTime:NSDateFormatterShortStyle]]];
				else
					[template setText:text];

				[template setImage:self.moonFill tintColor:Nil];

				handler([CLKComplicationTimelineEntry entryWithDate:DATA.startDate complicationTemplate:template]);
			} else {
				NSString *text = [[NSDateComponentsFormatter hhmmFormatter] stringFromTimeInterval:presenters.firstObject.duration];
				NSDate *date = [GLOBAL alertDate:presenters];
				if (complication.family == CLKComplicationFamilyUtilitarianLarge && date)
					[template setText:[CLKTextProvider textProviderWithFormat:[Localization watchBedtime], text, [date descriptionForTime:NSDateFormatterShortStyle]]];
				else
					[template setText:[CLKSimpleTextProvider textProviderWithText:text]];

				[template setImage:self.moonLine tintColor:Nil];

				handler(text ? [CLKComplicationTimelineEntry entryWithDate:presenters.firstObject.endDate complicationTemplate:template] : Nil);
			}
		}];
	else
		handler(Nil);

}

- (void)getPlaceholderTemplateForComplication:(CLKComplication *)complication withHandler:(void (^)(CLKComplicationTemplate * _Nullable))handler {
	CLKComplicationTemplate *template = [CLKComplicationTemplate createWithFamily:complication.family member:CLKComplicationFamilyMemberStackImage];

	[template setText:@"7:15" shortText:Nil];
	[template setImage:self.moonFill tintColor:Nil];

	handler(template);
}

@end

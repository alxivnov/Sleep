//
//  Localization.m
//  Sleep Diary
//
//  Created by Alexander Ivanov on 29.04.15.
//  Copyright (c) 2015 Alexander Ivanov. All rights reserved.
//

#import "Localization.h"

#import "NSCalendar+Convenience.h"
#import "NSFormatter+Convenience.h"
#import "NSObject+Convenience.h"

@implementation Localization

+ (NSString *)change {
	return NSLocalizedString(@"Change", Nil);
}

+ (NSString *)delete {
	return NSLocalizedString(@"Delete", Nil);
}

+ (NSString *)save {
	return NSLocalizedString(@"Save", Nil);
}

+ (NSString *)deleteSample {
	return NSLocalizedString(@"Delete sample?", Nil);
}

+ (NSString *)fallAsleep {
	return NSLocalizedString(@"Fall asleep", Nil);
}

+ (NSString *)wakeUp {
	return NSLocalizedString(@"Wake up", Nil);
}

+ (NSString *)goToSleep {
	return NSLocalizedString(@"Go to sleep!", Nil);
}

+ (NSString *)goToSleepBody {
	return NSLocalizedString(@"It's time to go to bed.", Nil);
}

+ (NSString *)wakeUpNow {
	return NSLocalizedString(@"Wake up now!", Nil);
}

+ (NSString *)wakeUpNowBody {
	return NSLocalizedString(@"It's time to wake up.", Nil);
}

+ (NSString *)wakeUp:(NSDate *)date {
	return date ? [NSString stringWithFormat:NSLocalizedString(@"Wake up at %@", Nil), [date descriptionForTime:NSDateFormatterShortStyle]] : Nil;
}

+ (NSString *)alarmDisabled {
	return NSLocalizedString(@"Alarm disabled", Nil);
}

+ (NSString *)alarmEnabled {
	return NSLocalizedString(@"Alarm enabled", Nil);
}

+ (NSString *)goToSleep:(NSDate *)date {
	return date ? [NSString stringWithFormat:NSLocalizedString(@"Go to sleep at %@", Nil), [date descriptionForTime:NSDateFormatterShortStyle]] : Nil;
}

+ (NSString *)notification:(NSDate *)date {
	return date ? [NSString stringWithFormat:NSLocalizedString(@"Notification at %@.", Nil), [date descriptionForDate:date.isToday ? NSDateFormatterNoStyle : NSDateFormatterShortStyle andTime:NSDateFormatterShortStyle]] : NSLocalizedString(@"Notification disabled.", Nil);;
}

+ (NSString *)notificationDisabled {
	return NSLocalizedString(@"Bedtime alert disabled", Nil);
}

+ (NSString *)notificationEnabled {
	return NSLocalizedString(@"Bedtime alert enabled", Nil);
}

+ (NSString *)noAlarm {
	return NSLocalizedString(@"No alarm", Nil);
}

+ (NSString *)alarm {
	return NSLocalizedString(@"Alarm", Nil);
}

+ (NSString *)yes {
	return NSLocalizedString(@"Yes", Nil);
}

+ (NSString *)no {
	return NSLocalizedString(@"No", Nil);
}

+ (NSString *)cancel {
	return NSLocalizedString(@"Cancel", Nil);
}

+ (NSString *)ok {
	return NSLocalizedString(@"OK", Nil);
}

+ (NSString *)thankYou {
	return NSLocalizedString(@"Thank You", Nil);
}

+ (NSString *)feedbackMessage {
	return NSLocalizedString(@"Do you want to tell me about your experience with this app?", Nil);
}

+ (NSString *)activity:(NSTimeInterval)time {
	NSString *string = NSLocalizedString(@"Movement", Nil);
	return time ? [NSString stringWithFormat:@"%@: %@", string, [[NSDateComponentsFormatter hhmmFormatter] stringFromTimeInterval:time]] : string;
}

+ (NSString *)average:(NSTimeInterval)time {
	NSString *string = NSLocalizedString(@"Average", Nil);
	return time ? [NSString stringWithFormat:@"%@: %@", string, [[NSDateComponentsFormatter hhmmFormatter] stringFromTimeInterval:time]] : string;
}

+ (NSString *)total:(NSTimeInterval)time {
	NSString *string = NSLocalizedString(@"Total", Nil);
	return /*time ? */[NSString stringWithFormat:@"%@: %@", string, [[NSDateComponentsFormatter hhmmFormatter] stringFromTimeInterval:time]]/* : string*/;
}

+ (NSString *)starts:(NSTimeInterval)time {
	NSString *string = NSLocalizedString(@"Starts", Nil);
	return time ? [NSString stringWithFormat:@"%@: %@", string, [[NSDateComponentsFormatter hhmmFormatter] stringFromTimeInterval:time]] : string;
}

+ (NSString *)ends:(NSTimeInterval)time {
	NSString *string = NSLocalizedString(@"Ends", Nil);
	return time ? [NSString stringWithFormat:@"%@: %@", string, [[NSDateComponentsFormatter hhmmFormatter] stringFromTimeInterval:time]] : string;
}

+ (NSString *)duration:(NSTimeInterval)time {
	NSString *string = NSLocalizedString(@"Duration", Nil);
	return time ? [NSString stringWithFormat:@"%@: %@", string, [[NSDateComponentsFormatter hhmmFormatter] stringFromTimeInterval:time]] : string;
}

+ (NSString *)allowNotifications {
	return NSLocalizedString(@"Allow Notifications", Nil);
}

+ (NSString *)allowSendNotifications {
	return NSLocalizedString(@"To use alarm clock allow \"Sleep Diary\" to send you notifications in the Settings.", Nil);
}

+ (NSString *)allowReadAndWriteData {
	return NSLocalizedString(@"To use \"Sleep Diary\" allow it to read and write Sleep Analysis data in the Health app's Sources tab.", Nil);
}

+ (NSString *)watchBedtime {
	return NSLocalizedString(@"%@, bedtime: %@", Nil);
}

+ (NSString *)watchWakeUp {
	return NSLocalizedString(@"%@, wake up: %@", Nil);
}

+ (NSString *)asleep {
	return NSLocalizedString(@"Asleep", Nil);
}

+ (NSString *)inBed {
	return NSLocalizedString(@"In bed", Nil);
}

+ (NSString *)wereYouAsleep {
	return NSLocalizedString(@"Were you asleep?", Nil);
}

+ (NSString *)mailFooter {
	return NSLocalizedString(@"Please, write what you feel is wrong or right with the data.", Nil);
}

@end

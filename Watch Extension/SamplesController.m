//
//  SamplesController.m
//  Watch Extension
//
//  Created by Alexander Ivanov on 17.04.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "SamplesController.h"

#import "ExtensionDelegate.h"
#import "RowControllers.h"


@interface SamplesController ()
@property (strong, nonatomic, readonly) ExtensionDelegate *delegate;

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceTable *table;

@property (strong, nonatomic) NSArray<HKCategorySample *> *samples;
@end


@implementation SamplesController

- (ExtensionDelegate *)delegate {
	return [WKExtension sharedExtension].delegate;
}

- (void)setup {
	[self.table setRowTypes:[self.samples map:^id(HKCategorySample *obj) {
		return obj.value == HKCategoryValueSleepAnalysisInBed ? ROW_ID_IN_BED : ROW_ID_ASLEEP;
	}]];
	for (NSUInteger index = 0; index < self.samples.count; index++)
		[[self.table rowControllerAtIndex:index] setSample:self.samples[index]];

	[self.table insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:self.samples.count] withRowType:@"Save"];
//	[self.table insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:self.samples.count + 1] withRowType:@"Cancel"];
}

- (void)awakeWithContext:(id)context {
	[super awakeWithContext:context];

	// Configure interface objects here.

	self.samples = context;
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

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {
	NSUInteger index = rowIndex - table.numberOfRows;

	if (index == -1) {
		[[HKHealthStore defaultStore] saveObjects:self.samples completion:^(BOOL success) {
			[GCD main:^{
				[self dismissController];
			}];
		}];
	} else {
		HKCategorySample *sample = self.samples[rowIndex];
		[self presentAlertControllerWithTitle:loc(@"Remove sample?") message:[NSString stringWithFormat:@"%@ - %@", [sample.startDate descriptionForTime:NSDateFormatterShortStyle], [sample.endDate descriptionForTime:NSDateFormatterShortStyle]] preferredStyle:WKAlertControllerStyleActionSheet actions:@[ [WKAlertAction actionWithTitle:loc(@"Delete") style:WKAlertActionStyleDestructive handler:^{
			self.samples = [self.samples arrayByRemovingObject:sample];
		}], [WKAlertAction actionWithTitle:loc(@"Cancel") style:WKAlertActionStyleCancel handler:^{

		}] ]];
	}
}

@end

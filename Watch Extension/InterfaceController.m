//
//  InterfaceController.m
//  Watch Extension
//
//  Created by Alexander Ivanov on 08.04.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "InterfaceController.h"

#import "ExtensionDelegate.h"
#import "RowControllers.h"

// Sometimes app crashes on activation
// Sometimes app does not load sunrise


#define STR_SAMPLES @"samples"


@interface InterfaceController ()
@property (strong, nonatomic, readonly) ExtensionDelegate *delegate;

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceTable *table;
@end


@implementation InterfaceController

- (ExtensionDelegate *)delegate {
	return [WKExtension sharedExtension].delegate;
}

- (void)setup {
	if (self.table.numberOfRows < 1)
		[self.table setRowTypes:@[ ROW_ID_BUTTON ]];
	[[self.table rowControllerAtIndex:0] setup];

	NSDate *now = [NSDate date];
	NSDate *today = [now dateComponent];
	AnalysisPresenter *presenter = self.delegate.presenters[today];
	NSArray<AnalysisPresenter *> *presenters = [presenter.allPresenters query:^BOOL(AnalysisPresenter *obj) {
		return obj.allSamples.firstObject.value == HKCategoryValueSleepAnalysisInBed || obj.allSamples.firstObject.value == HKCategoryValueSleepAnalysisAsleep;
	}];
	if (self.table.numberOfRows > 1)
		[self.table removeRowsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, self.table.numberOfRows - 1)]];
	for (NSUInteger index = 0; index < presenters.count; index++) {
		AnalysisPresenter *obj = presenters[index];

		[self.table insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:index + 1] withRowType:obj.allSamples.firstObject.value == HKCategoryValueSleepAnalysisInBed ? ROW_ID_IN_BED : ROW_ID_ASLEEP];
		[[self.table rowControllerAtIndex:index + 1] setPresenter:obj];
	}

	[self.delegate detect:^(NSArray<HKCategorySample *> *samples) {
		if (samples.count)
			[GCD main:^{
				[self presentControllerWithName:STR_SAMPLES context:samples];
			}];
	}];
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

@end




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

@property (assign, nonatomic) BOOL detecting;

@property (assign, nonatomic) BOOL didActivate;
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
		return obj.allSamples.firstObject.value == HKCategoryValueSleepAnalysisInBed || IS_ASLEEP(obj.allSamples.firstObject.value);
	}];
	NSUInteger count = presenters.count + 1;
	if (self.table.numberOfRows > count)
		[self.table removeRowsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(count, self.table.numberOfRows - count)]];
	else if (self.table.numberOfRows < count)
		[self.table insertRowsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(self.table.numberOfRows, count - self.table.numberOfRows)] withRowType:ROW_ID_ASLEEP];
	for (NSUInteger index = 0; index < presenters.count; index++) {
		AnalysisPresenter *obj = presenters[index];

//		[self.table insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:index + 1] withRowType:obj.allSamples.firstObject.value == HKCategoryValueSleepAnalysisInBed ? ROW_ID_IN_BED : ROW_ID_ASLEEP];
		[[self.table rowControllerAtIndex:index + 1] setPresenter:obj];
	}
}

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // Configure interface objects here.
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    
    self.didActivate = YES;
}

- (void)didAppear {
	[super didAppear];
	
    if (!self.didActivate)
        return;
    
    self.didActivate = NO;

	[self setup];

//	NSArray *samples = @[ [HKDataSleepAnalysis sampleWithStartDate:[[NSDate date] addValue:-1 forComponent:NSCalendarUnitHour] endDate:[NSDate date] value:HKCategoryValueSleepAnalysisInBed metadata:Nil], [HKDataSleepAnalysis sampleWithStartDate:[[NSDate date] addValue:-1 forComponent:NSCalendarUnitHour] endDate:[NSDate date] value:CategoryValueSleepAnalysisAsleepUnspecified metadata:Nil] ];
	if (self.detecting)
		return;

	self.detecting = YES;

	[self.delegate detectFromUI:[WKExtension sharedExtension].applicationState == WKApplicationStateActive completion:^(NSArray<HKCategorySample *> *samples) {
		if (samples.count)
			[GCD main:^{
				[self presentControllerWithName:STR_SAMPLES context:samples];
			}];

		self.detecting = NO;
	}];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {
	NSArray<AnalysisPresenter *> *presenters = [self.delegate.presenters[[[NSDate date] dateComponent]].allPresenters query:^BOOL(AnalysisPresenter *obj) {
		return obj.allSamples.firstObject.value == HKCategoryValueSleepAnalysisInBed || IS_ASLEEP(obj.allSamples.firstObject.value);
	}];

	AnalysisPresenter *presenter = presenters[rowIndex - 1];
	[self presentAlertControllerWithTitle:loc(@"Delete sample?") message:presenter.text preferredStyle:WKAlertControllerStyleActionSheet actions:@[ [WKAlertAction actionWithTitle:loc(@"Delete") style:WKAlertActionStyleDestructive handler:^{
		[[HKHealthStore defaultStore] deleteObjects:presenter.allSamples completion:Nil];
	}], [WKAlertAction actionWithTitle:loc(@"Cancel") style:WKAlertActionStyleCancel handler:^{
		
	}] ]];
}

@end




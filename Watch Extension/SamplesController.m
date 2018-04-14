//
//  SamplesController.m
//  Watch Extension
//
//  Created by Alexander Ivanov on 08.04.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "SamplesController.h"

#import "ExtensionDelegate.h"


#define ROW_ID_IN_BED @"In Bed"
#define ROW_ID_ASLEEP @"Asleep"


@interface DetailRowController : NSObject
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *textLabel;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *detailTextLabel;
@end


@implementation DetailRowController

- (void)setPresenter:(AnalysisPresenter *)presenter {
	[self.textLabel setText:presenter.text];
	[self.detailTextLabel setText:presenter.accessoryText];
}

@end


@interface SamplesController ()
@property (strong, nonatomic, readonly) ExtensionDelegate *delegate;

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceTable *table;
@end


@implementation SamplesController

- (ExtensionDelegate *)delegate {
	return [WKExtension sharedExtension].delegate;
}

- (void)setup {
	NSDate *today = [NSDate date].dateComponent;
	NSArray<AnalysisPresenter *> *presenters = self.delegate.presenters[today].allPresenters;
	[self.table setRowTypes:[presenters map:^id(AnalysisPresenter *obj) {
		return obj.allSamples.firstObject.value == HKCategoryValueSleepAnalysisInBed ? ROW_ID_IN_BED : obj.allSamples.firstObject.value == HKCategoryValueSleepAnalysisAsleep ? ROW_ID_ASLEEP : Nil;
	}]];
	for (NSUInteger index = 0; index < self.table.numberOfRows && index < presenters.count; index++)
		 [[self.table rowControllerAtIndex:index] setPresenter:presenters[index]];
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




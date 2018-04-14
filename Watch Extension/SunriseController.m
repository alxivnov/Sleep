//
//  SunriseController.m
//  Watch Extension
//
//  Created by Alexander Ivanov on 10.04.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "SunriseController.h"

#import "ExtensionDelegate.h"

#import "EDSunriseSet.h"


#define ROW_ID_SUNRISE @"Sunrise"
#define ROW_ID_SUNSET @"Sunset"


@interface ImageRowController : NSObject
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceImage *image;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *textLabel;
@end


@implementation ImageRowController

- (void)setDate:(NSDate *)date {
	[self.textLabel setText:[date descriptionForTime:NSDateFormatterShortStyle]];
}

@end


@interface SunriseController () <CLLocationManagerDelegate>
@property (strong, nonatomic, readonly) ExtensionDelegate *delegate;

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceTable *table;

@property (strong, nonatomic) NSDate *wakeUp;
@property (strong, nonatomic) NSDate *goToBed;
@end

@implementation SunriseController

- (ExtensionDelegate *)delegate {
	return [WKExtension sharedExtension].delegate;
}

- (void)setupSunrise:(NSDate *)sunrise sunset:(NSDate *)sunset {
	if (sunrise && sunset) {
		if ([sunset isGreaterThan:sunrise]) {
			if (!self.table.numberOfRows)
				[self.table setRowTypes:@[ ROW_ID_SUNRISE, ROW_ID_SUNSET ]];

			[[self.table rowControllerAtIndex:0] setDate:sunrise];
			[[self.table rowControllerAtIndex:1] setDate:sunset];
		} else {
			if (!self.table.numberOfRows)
				[self.table setRowTypes:@[ ROW_ID_SUNSET, ROW_ID_SUNRISE ]];

			[[self.table rowControllerAtIndex:0] setDate:sunset];
			[[self.table rowControllerAtIndex:1] setDate:sunrise];
		}
	}
}

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    // Configure interface objects here.

//	NSLog(@"authorizationStatus: %d", [CLLocationManager authorizationStatus]);
//	NSLog(@"locationServicesEnabled: %d", [CLLocationManager locationServicesEnabled]);

	[CLLocationManager defaultManager].delegate = self;

	if (IS_DEBUGGING)
		[self setTitle:[NSBundle bundleVersion]];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];

	[[CLLocationManager defaultManager] requestWhenInUseAuthorization];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
//	NSLog(@"didChangeAuthorizationStatus: %d", status);

	[manager requestLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
//	[locations log:@"didUpdateLocations:"];

	CLLocation *location = locations.lastObject;
	if (!location)
		return;

	EDSunriseSet *today = [EDSunriseSet sunrisesetWithDate:[NSDate date] timezone:[NSCalendar currentCalendar].timeZone latitude:location.coordinate.latitude longitude:location.coordinate.longitude];
	NSDate *sunrise = today.sunrise;
	NSDate *sunset = today.sunset;
	if (sunrise.isPast) {
		EDSunriseSet *tomorrow = [EDSunriseSet sunrisesetWithDate:[today.date addValue:1 forComponent:NSCalendarUnitDay] timezone:[NSCalendar currentCalendar].timeZone latitude:location.coordinate.latitude longitude:location.coordinate.longitude];
		sunrise = tomorrow.sunrise;

		if (sunset.isPast)
			sunset = tomorrow.sunset;
	}

	[self setupSunrise:sunrise sunset:sunset];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	[error log:@"didFailWithError:"];
}

@end




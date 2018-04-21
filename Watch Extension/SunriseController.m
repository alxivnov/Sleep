//
//  SunriseController.m
//  Watch Extension
//
//  Created by Alexander Ivanov on 10.04.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "SunriseController.h"

#import "ExtensionDelegate.h"
#import "RowControllers.h"

#import "EDSunriseSet.h"


#define ROW_ID_SUNRISE @"Sunrise"
#define ROW_ID_SUNSET @"Sunset"
#define ROW_ID_WAKE_UP @"Wake Up"
#define ROW_ID_GO_TO_BED @"Go to Bed"


@interface SunriseController () <CLLocationManagerDelegate>
@property (strong, nonatomic, readonly) ExtensionDelegate *delegate;

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceTable *table;

@property (strong, nonatomic) CLLocation *location;
@end

@implementation SunriseController

- (ExtensionDelegate *)delegate {
	return [WKExtension sharedExtension].delegate;
}

- (CLLocation *)location {
	return [CLLocation locationFromString:[[NSUserDefaults standardUserDefaults] objectForKey:@"location"]];
}

- (void)setLocation:(CLLocation *)location {
	[[NSUserDefaults standardUserDefaults] setObject:location.locationString forKey:@"location"];
}

- (void)setup:(CLLocation *)location {
	if (location)
		self.location = location;
	else
		location = self.location;

	NSMutableArray<NSDictionary *> *dates = [NSMutableArray arrayWithCapacity:3];

	if (location) {
		EDSunriseSet *today = [EDSunriseSet sunrisesetWithDate:[NSDate date] timezone:[NSCalendar currentCalendar].timeZone latitude:location.coordinate.latitude longitude:location.coordinate.longitude];
		NSDate *sunrise = today.sunrise;
		NSDate *sunset = today.sunset;
		if (sunrise.isPast) {
			EDSunriseSet *tomorrow = [EDSunriseSet sunrisesetWithDate:[today.date addValue:1 forComponent:NSCalendarUnitDay] timezone:[NSCalendar currentCalendar].timeZone latitude:location.coordinate.latitude longitude:location.coordinate.longitude];
			sunrise = tomorrow.sunrise;

			if (sunset.isPast)
				sunset = tomorrow.sunset;
		}

		[dates addObject:@{ @"date" : sunrise, @"type" : ROW_ID_SUNRISE }];
		[dates addObject:@{ @"date" : sunset, @"type" : ROW_ID_SUNSET }];
	}

	NSDate *date = self.delegate.startDate ? [self.delegate alarmDate] : [self.delegate alertDate];
	if (date)
		[dates addObject:@{ @"date" : date, @"type" : self.delegate.startDate ? ROW_ID_WAKE_UP : ROW_ID_GO_TO_BED }];

	[dates sortUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
		return [obj1[@"date"] compare:obj2[@"date"]];
	}];

	[self.table setRowTypes:[dates map:^id(NSDictionary *obj) {
		return obj[@"type"];
	}]];
	for (NSUInteger index = 0; index < dates.count && index < self.table.numberOfRows; index++)
		 [[self.table rowControllerAtIndex:index] setDate:dates[index][@"date"]];
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

	CLLocation *location = [CLLocationManager defaultManager].location;

	[self setup:location];

	if (!location)
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

	[self setup:location];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	[error log:@"didFailWithError:"];
}

@end




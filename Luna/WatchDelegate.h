//
//  SessionDelegate.h
//  Sleep Diary
//
//  Created by Alexander Ivanov on 02.10.15.
//  Copyright © 2015 Alexander Ivanov. All rights reserved.
//

#import "WatchConnectivity+Convenience.h"

#import "CMMotionActivitySample.h"

@interface WatchDelegate : WCSessionDelegate

- (void)sendMessage;

- (void)getActivitiesFromDate:(NSDate *)startDate toDate:(NSDate *)endDate handler:(void (^)(NSArray<CMMotionActivitySample *> *activities))handler;

@end

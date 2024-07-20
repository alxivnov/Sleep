//
//  RowControllers.h
//  Watch Extension
//
//  Created by Alexander Ivanov on 17.04.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

#import "ExtensionDelegate.h"


@interface ButtonRowController : NSObject
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceGroup *group;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceImage *image;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceTimer *timer;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *label;

- (void)setup;
@end


@interface InBedRowController : NSObject
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *textLabel;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *detailTextLabel;

- (void)setPresenter:(AnalysisPresenter *)presenter;

- (void)setSample:(HKCategorySample *)sample;
@end


@interface SleepRowController : NSObject
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *textLabel;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *detailTextLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *accessoryView;

- (void)setPresenter:(AnalysisPresenter *)presenter;

- (void)setSample:(HKCategorySample *)sample;
@end


@interface ImageRowController : NSObject
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceImage *image;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *textLabel;

- (void)setDate:(NSDate *)date;
@end

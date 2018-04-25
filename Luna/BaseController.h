//
//  BaseController.h
//  Sleep Diary
//
//  Created by Alexander Ivanov on 14.04.16.
//  Copyright © 2016 Alexander Ivanov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BaseController : UIViewController

- (void)setSleepDuration:(NSTimeInterval)sleepDuration inBedDuration:(NSTimeInterval)inBedDuration cycleCount:(NSUInteger)cycleCount animated:(BOOL)animated;

@end

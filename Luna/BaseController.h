//
//  BaseController.h
//  Sleep Diary
//
//  Created by Alexander Ivanov on 14.04.16.
//  Copyright © 2016 Alexander Ivanov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BaseController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UIView *todayView;

@property (weak, nonatomic) IBOutlet UIButton *aboutButton;
@property (weak, nonatomic) IBOutlet UIButton *pressureButton;
@property (weak, nonatomic) IBOutlet UIButton *settingsButton;

- (void)setSleepDuration:(NSTimeInterval)sleepDuration inBedDuration:(NSTimeInterval)inBedDuration cycleCount:(NSUInteger)cycleCount animated:(BOOL)animated;

@end

//
//  SleepButtonCell.h
//  Sleep Diary
//
//  Created by Alexander Ivanov on 19.04.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AnalysisPresenter.h"

@interface SleepButtonCell : UITableViewCell

- (void)setup:(NSArray<AnalysisPresenter *> *)presenters;

- (void)setSleepDuration:(NSTimeInterval)sleepDuration inBedDuration:(NSTimeInterval)inBedDuration cycleCount:(NSUInteger)cycleCount animated:(BOOL)animated;

@end

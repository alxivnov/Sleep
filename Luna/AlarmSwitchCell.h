//
//  AlarmSwitchCell.h
//  Sleep Diary
//
//  Created by Alexander Ivanov on 26.04.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AnalysisPresenter.h"

@interface AlarmSwitchCell : UITableViewCell

- (void)setupAlarmButton:(NSArray<AnalysisPresenter *> *)presenters;

@end

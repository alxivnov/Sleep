//
//  SleepSwitchCell.h
//  Sleep Diary
//
//  Created by Alexander Ivanov on 19.04.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AnalysisPresenter.h"

#import "UITableViewCell+Convenience.h"
#import "UserNotifications+Convenience.h"

@interface SleepSwitchCell : UITableViewCell

- (void)setupAlertButton:(NSArray<AnalysisPresenter *> *)presenters;

@end

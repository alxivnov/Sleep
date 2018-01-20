//
//  IntervalController.h
//  Sleep Diary
//
//  Created by Alexander Ivanov on 24.02.15.
//  Copyright (c) 2015 Alexander Ivanov. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AnalysisPresenter.h"

@interface IntervalController : UITableViewController

@property (strong, nonatomic) AnalysisPresenter *sample;

@end

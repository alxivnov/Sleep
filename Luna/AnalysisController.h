//
//  PressureController.h
//  Sleep Diary
//
//  Created by Alexander Ivanov on 14.07.15.
//  Copyright © 2015 Alexander Ivanov. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AnalysisPresenter.h"

@interface AnalysisController : UITableViewController <UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *leftBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *rightBarButtonItem;


@property (strong, nonatomic, readonly) NSArray<AnalysisPresenter *> *samples;
@property (assign, nonatomic, readonly) NSTimeInterval avg;
@property (assign, nonatomic, readonly) NSTimeInterval sum;
- (void)setSamples:(NSArray<AnalysisPresenter *> *)samples animated:(BOOL)animated;

@end

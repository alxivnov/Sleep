//
//  ActivityController.h
//  Sleep Diary
//
//  Created by Alexander Ivanov on 22.04.16.
//  Copyright © 2016 Alexander Ivanov. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AnalysisController.h"

@interface ActivityController : AnalysisController

@property (strong, nonatomic) NSDate *startDate;
@property (strong, nonatomic) NSDate *endDate;

@property (assign, nonatomic) BOOL showButton;
@property (assign, nonatomic, readonly) BOOL showSwitch;

@property (assign, nonatomic, readonly) BOOL showActivity;

@end

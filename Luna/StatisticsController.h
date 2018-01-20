//
//  StatisticsController.h
//  Sleep Diary
//
//  Created by Alexander Ivanov on 04.06.17.
//  Copyright © 2017 Alexander Ivanov. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CMMotionActivitySample.h"

@interface StatisticsController : UITableViewController
@property (strong, nonatomic) NSArray<CMMotionActivitySample *> *samples;
@end

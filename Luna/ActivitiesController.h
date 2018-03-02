//
//  ActivitiesController.h
//  Sleep Diary
//
//  Created by Alexander Ivanov on 01.10.16.
//  Copyright © 2016 Alexander Ivanov. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UIPageViewController+Convenience.h"

@interface ActivitiesController : UIPagingController <UIPageViewControllerDelegate>

@property (assign, nonatomic) NSNumber *weekday;

@end

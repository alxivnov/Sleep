//
//  WeekdaysController.h
//  Sleep Diary
//
//  Created by Alexander Ivanov on 18.04.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "ActivitiesController.h"

@interface WeekdaysController : ActivitiesController

- (void)setupAlertView:(void(^)(BOOL))completion;

@end

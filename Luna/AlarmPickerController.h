//
//  AlarmPickerController.h
//  Sleep Diary
//
//  Created by Alexander Ivanov on 26.04.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "SleepButtonController.h"

@interface AlarmPickerController : SleepButtonController

+ (void)updateNotification:(void(^)(BOOL success))completion;

@end

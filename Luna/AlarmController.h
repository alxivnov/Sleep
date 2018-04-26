//
//  AlarmController.h
//  Sleep Diary
//
//  Created by Alexander Ivanov on 29.11.15.
//  Copyright © 2015 Alexander Ivanov. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UIDatePicker+Convenience.h"

@interface AlarmController : UIViewController

@property (strong, nonatomic) UIDatePickerController *pickerController;

@end

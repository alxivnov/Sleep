//
//  AlertController.h
//  Sleep Diary
//
//  Created by Alexander Ivanov on 18/04/16.
//  Copyright © 2016 Alexander Ivanov. All rights reserved.
//

#import "BaseController.h"

@interface AlertController : BaseController

@property (strong, nonatomic, readonly) NSNumber *buttonShapes;

@property (strong, nonatomic) IBOutlet UIView *alertView;

- (void)setupAlertView:(void(^)(BOOL hasData))completion;

@end

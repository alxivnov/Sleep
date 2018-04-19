//
//  AlertController.m
//  Sleep Diary
//
//  Created by Alexander Ivanov on 18/04/16.
//  Copyright © 2016 Alexander Ivanov. All rights reserved.
//

#import "AlertController.h"
#import "ActivityController.h"
#import "Global.h"
#import "Widget.h"
#import "Localization.h"

#import "UIBezierPath+Convenience.h"
#import "UIButton+Convenience.h"

#import "NSArray+Convenience.h"
#import "NSCalendar+Convenience.h"
#import "NSObject+Convenience.h"
#import "UIViewController+Convenience.h"
#import "Dispatch+Convenience.h"
#import "UserNotifications+Convenience.h"

@interface AlertController ()

@property (weak, nonatomic) IBOutlet UIButton *alertButton;
@end

@implementation AlertController

- (NSNumber *)buttonShapes {
	return [self.alertButton.titleLabel.attributedText attributesAtIndex:0 effectiveRange:Nil][NSUnderlineStyleAttributeName];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

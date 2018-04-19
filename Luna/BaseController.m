//
//  BaseController.m
//  Sleep Diary
//
//  Created by Alexander Ivanov on 14.04.16.
//  Copyright © 2016 Alexander Ivanov. All rights reserved.
//

#import "BaseController.h"
#import "Global.h"

#import "UIBezierPath+Convenience.h"

#import "QuartzCore+Convenience.h"
#import "UIColor+Convenience.h"
#import "UIImage+Convenience.h"

#define IMG_BUTTON_HIGHLIGHTED @"Luna-Button-Highlighted"

@interface BaseController ()

@end

@implementation BaseController


- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	
//	[self.startButton setBackgroundImage:[UIImage originalImage:IMG_BUTTON_HIGHLIGHTED] forState:UIControlStateSelected | UIControlStateHighlighted ];
//	[self.startButton setTitle:[self.startButton titleForState:UIControlStateSelected] forState:UIControlStateSelected | UIControlStateHighlighted];

//	[self.startButton setTitleColor:[UIColor color:RGB_DARK_TINT] forState:UIControlStateNormal];
//	[self.startButton setTitleColor:[UIColor lightTextColor] forState:UIControlStateSelected];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

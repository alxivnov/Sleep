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
@property (strong, nonatomic) CAShapeLayer *sleepDurationLayer;
@property (assign, nonatomic) NSTimeInterval sleepDuration;
@end

@implementation BaseController

- (void)setSleepDurationLayer:(CAShapeLayer *)sleepDurationLayer {
	[_sleepDurationLayer removeFromSuperlayer];

	[self.startButton.layer addSublayer:sleepDurationLayer];

	_sleepDurationLayer = sleepDurationLayer;
}

- (void)setSleepDuration:(NSTimeInterval)sleepDuration cycleCount:(NSUInteger)cycleCount animated:(BOOL)animated {
//	if (!animated)
//		sleepDuration += 60.0 * 60.0;

	if (_sleepDuration == sleepDuration)
		return;

	CGPathRef path = self.sleepDurationLayer.path;

	self.sleepDurationLayer = [[UIBezierPath bezierPathWithArcFrame:self.startButton.bounds width:-(64.0 / 580.0) start:0.0 end:fmin(1.0, sleepDuration / GLOBAL.sleepDuration) lineCap:kCGLineCapRound lineJoin:kCGLineJoinRound] layerWithStrokeColors:@[ [GLOBAL.tintColor colorWithAlphaComponent:(cycleCount + 1.0) / 6.0], RGB(23, 23, 23) ]];

	if (animated) {
		if (path)
			[self.sleepDurationLayer addAnimationFromValue:(__bridge id)(path) toValue:(__bridge id)(self.sleepDurationLayer.path) forKey:CALayerKeyPath];
		else
			[self.sleepDurationLayer addAnimationFromValue:_sleepDuration <= 0.0 || sleepDuration <= 0.0 ? @0 : @(fmin(1.0, _sleepDuration / sleepDuration)) toValue:@1 forKey:CALayerKeyStrokeEnd];
	}

	_sleepDuration = sleepDuration;
}


- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	
	[self.startButton setBackgroundImage:[UIImage originalImage:IMG_BUTTON_HIGHLIGHTED] forState:UIControlStateSelected | UIControlStateHighlighted ];
	[self.startButton setTitle:[self.startButton titleForState:UIControlStateSelected] forState:UIControlStateSelected | UIControlStateHighlighted];
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

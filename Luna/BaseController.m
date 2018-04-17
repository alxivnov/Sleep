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
@property (strong, nonatomic) CAShapeLayer *inBedDurationLayer;
@property (assign, nonatomic) NSTimeInterval sleepDuration;
@property (assign, nonatomic) NSTimeInterval inBedDuration;
@end

@implementation BaseController

- (void)setSleepDurationLayer:(CAShapeLayer *)sleepDurationLayer {
	[_sleepDurationLayer removeFromSuperlayer];

	[self.startButton.layer addSublayer:sleepDurationLayer];

	_sleepDurationLayer = sleepDurationLayer;
}

- (void)setInBedDurationLayer:(CAShapeLayer *)inBedDurationLayer {
	[_inBedDurationLayer removeFromSuperlayer];

	[self.startButton.layer addSublayer:inBedDurationLayer];

	_inBedDurationLayer = inBedDurationLayer;
}

- (void)setSleepDuration:(NSTimeInterval)sleepDuration inBedDuration:(NSTimeInterval)inBedDuration cycleCount:(NSUInteger)cycleCount animated:(BOOL)animated {
//	if (!animated)
//		sleepDuration += 60.0 * 60.0;

	if (_sleepDuration == sleepDuration && _inBedDuration == inBedDuration)
		return;

	CGPathRef sleepPath = self.sleepDurationLayer.path;
	CGPathRef inBedPath = self.inBedDurationLayer.path;

	CGFloat width = fmin(self.startButton.bounds.size.width, self.startButton.bounds.size.height) * (64.0 / 580.0);
	self.inBedDurationLayer = [[UIBezierPath bezierPathWithArcFrame:self.startButton.bounds width:width start:0.0 end:fmin(1.0, inBedDuration / (GLOBAL.sleepDuration + GLOBAL.sleepLatency)) lineCap:kCGLineCapRound lineJoin:kCGLineJoinRound] layerWithStrokeColors:@[ [[UIColor color:RGB_LIGHT_TINT] colorWithAlphaComponent:(cycleCount + 1.0) / 6.0]/*, RGB(23, 23, 23)*/ ]];
	self.sleepDurationLayer = [[UIBezierPath bezierPathWithArcFrame:CGRectInset(self.startButton.bounds, width, width) width:width start:0.0 end:fmin(1.0, sleepDuration / GLOBAL.sleepDuration) lineCap:kCGLineCapRound lineJoin:kCGLineJoinRound] layerWithStrokeColors:@[ [[UIColor color:RGB_DARK_TINT] colorWithAlphaComponent:(cycleCount + 1.0) / 6.0]/*, RGB(23, 23, 23)*/ ]];

	if (animated) {
		if (inBedPath)
			[self.inBedDurationLayer addAnimationFromValue:(__bridge id)(inBedPath) toValue:(__bridge id)(self.inBedDurationLayer.path) forKey:CALayerKeyPath];
		else
			[self.inBedDurationLayer addAnimationFromValue:_inBedDuration <= 0.0 || inBedDuration <= 0.0 ? @0 : @(fmin(1.0, _inBedDuration / inBedDuration)) toValue:@1 forKey:CALayerKeyStrokeEnd];

		if (sleepPath)
			[self.sleepDurationLayer addAnimationFromValue:(__bridge id)(sleepPath) toValue:(__bridge id)(self.sleepDurationLayer.path) forKey:CALayerKeyPath];
		else
			[self.sleepDurationLayer addAnimationFromValue:_sleepDuration <= 0.0 || sleepDuration <= 0.0 ? @0 : @(fmin(1.0, _sleepDuration / sleepDuration)) toValue:@1 forKey:CALayerKeyStrokeEnd];
}

	[self.startButton setTitle:[[NSDateComponentsFormatter hhmmssFormatter] stringFromTimeInterval:sleepDuration ?: inBedDuration] forState:UIControlStateNormal];

	_inBedDuration = inBedDuration;
	_sleepDuration = sleepDuration;
}


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

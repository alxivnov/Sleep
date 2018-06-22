//
//  SleepButtonCell.m
//  Sleep Diary
//
//  Created by Alexander Ivanov on 19.04.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "SleepButtonCell.h"

#import "Global.h"

#import "QuartzCore+Convenience.h"
#import "UIBezierPath+Convenience.h"

@interface SleepButtonCell ()
@property (strong, nonatomic) CAShapeLayer *sleepDurationLayer;
@property (strong, nonatomic) CAShapeLayer *inBedDurationLayer;
@property (assign, nonatomic) NSTimeInterval sleepDuration;
@property (assign, nonatomic) NSTimeInterval inBedDuration;
@end

@implementation SleepButtonCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setSleepDurationLayer:(CAShapeLayer *)sleepDurationLayer {
	[_sleepDurationLayer removeFromSuperlayer];

	[self.button.layer addSublayer:sleepDurationLayer];

	_sleepDurationLayer = sleepDurationLayer;
}

- (void)setInBedDurationLayer:(CAShapeLayer *)inBedDurationLayer {
	[_inBedDurationLayer removeFromSuperlayer];

	[self.button.layer addSublayer:inBedDurationLayer];

	_inBedDurationLayer = inBedDurationLayer;
}

- (void)setSleepDuration:(NSTimeInterval)sleepDuration inBedDuration:(NSTimeInterval)inBedDuration cycleCount:(NSUInteger)cycleCount animated:(BOOL)animated {
//	if (!animated)
//		sleepDuration += 60.0 * 60.0;

	if (_sleepDuration == sleepDuration && _inBedDuration == inBedDuration)
		return;

	CGPathRef sleepPath = self.sleepDurationLayer.path;
	CGPathRef inBedPath = self.inBedDurationLayer.path;

	CGFloat width = fmin(self.button.bounds.size.width, self.button.bounds.size.height) * (64.0 / 580.0);
	self.inBedDurationLayer = [[UIBezierPath bezierPathWithArcFrame:self.button.bounds width:width start:0.0 end:fmin(1.0, inBedDuration / (GLOBAL.sleepDuration + GLOBAL.sleepLatency)) lineCap:kCGLineCapRound lineJoin:kCGLineJoinRound] layerWithStrokeColors:@[ /*[*/[UIColor color:RGB_LIGHT_TINT]/* colorWithAlphaComponent:(cycleCount + 1.0) / 6.0]*//*, RGB(23, 23, 23)*/ ]];
	self.sleepDurationLayer = [[UIBezierPath bezierPathWithArcFrame:CGRectInset(self.button.bounds, width + 2.0, width + 2.0) width:width start:0.0 end:fmin(1.0, sleepDuration / GLOBAL.sleepDuration) lineCap:kCGLineCapRound lineJoin:kCGLineJoinRound] layerWithStrokeColors:@[ /*[*/[UIColor color:RGB_DARK_TINT]/* colorWithAlphaComponent:(cycleCount + 1.0) / 6.0]*//*, RGB(23, 23, 23)*/ ]];

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

	[self.button setTitle:[[NSDateComponentsFormatter hhmmssFormatter] stringFromTimeInterval:sleepDuration ?: inBedDuration] forState:UIControlStateNormal];

	_inBedDuration = inBedDuration;
	_sleepDuration = sleepDuration;
}

- (void)setup:(NSArray<AnalysisPresenter *> *)presenters {
	NSTimeInterval sleep = [presenters sum:^NSNumber *(AnalysisPresenter *obj) {
		return obj.allSamples.firstObject.value == HKCategoryValueSleepAnalysisAsleep ? @(obj.duration) : Nil;
	}];
	NSTimeInterval inBed = [presenters sum:^NSNumber *(AnalysisPresenter *obj) {
		return obj.allSamples.firstObject.value == HKCategoryValueSleepAnalysisInBed ? @(obj.duration) : Nil;
	}];
	[self setSleepDuration:sleep inBedDuration:inBed cycleCount:0.0 animated:YES];

//	self.button.enabled = presenters.lastObject.endDate.isToday;
}

@end

//
//  ActivityVisualizer.m
//  Sleep Diary
//
//  Created by Alexander Ivanov on 31.05.16.
//  Copyright © 2016 Alexander Ivanov. All rights reserved.
//

#import "ActivityVisualizer.h"
#import "Global.h"

#import "EDSunriseSet.h"

#import "Accelerate+Convenience.h"
#import "CoreGraphics+Convenience.h"
#import "CoreLocation+Convenience.h"
#import "QuartzCore+Convenience.h"
#import "HKActiveEnergy+CMMotionActivitySample.h"
#import "NSArray+Convenience.h"
#import "NSFormatter+Convenience.h"
#import "NSObject+Convenience.h"
#import "UIColor+Convenience.h"
#import "UIImage+Convenience.h"

#define RGB_LIGHT_PURPLE 0xD675DA
#define RGB_DARK_PURPLE 0xAB3DAB
#define RGB_LIGHT_VIOLET 0x6C69D1
#define RGB_DARK_VIOLET 0x3F3AAB

@interface ActivityVisualizer () <UIScrollViewDelegate>
@property (assign, nonatomic) NSTimeInterval duration;
@property (assign, nonatomic) CGFloat pointsPerSecond;

@property (strong, nonatomic, readonly) CAShapeLayer *inBedLayer;
@property (strong, nonatomic, readonly) CAShapeLayer *sleepLayer;
@property (strong, nonatomic, readonly) CAShapeLayer *stepsLayer;
@property (strong, nonatomic, readonly) CAShapeLayer *heartLayer;
@property (strong, nonatomic, readonly) CAShapeLayer *alertLayer;
@property (strong, nonatomic, readonly) CAShapeLayer *activityLayer;
@property (strong, nonatomic, readonly) UIImageView *timeView;
@property (strong, nonatomic, readonly) UIImageView *scaleView;
@property (strong, nonatomic, readonly) UIImageView *sunriseView;
@property (strong, nonatomic, readonly) UIImageView *sunsetView;

@property (strong, nonatomic) NSDate *startDate;
@property (strong, nonatomic) NSDate *endDate;
@end

@implementation ActivityVisualizer

__property(NSTimeInterval, duration, [self.endDate timeIntervalSinceDate:self.startDate])
//__property(CGFloat, pointsPerSecond, self.contentSize.width / self.duration)

- (CGFloat)pointsPerSecond {
	return self.contentSize.width / self.duration;
}

__synthesize(CAShapeLayer *, inBedLayer, ({ CAShapeLayer *x = [CAShapeLayer new]; [self.layer addSublayer:x]; x; }))
__synthesize(CAShapeLayer *, sleepLayer, ({ CAShapeLayer *x = [CAShapeLayer new]; [self.layer addSublayer:x]; x; }))
__synthesize(CAShapeLayer *, stepsLayer, ({ CAShapeLayer *x = [CAShapeLayer new]; [self.layer addSublayer:x]; x.fillColor = [UIColor color:HEX_NCS_YELLOW].CGColor; x; }))
__synthesize(CAShapeLayer *, heartLayer, ({ CAShapeLayer *x = [CAShapeLayer new]; [self.layer addSublayer:x]; x.fillColor = Nil; x.strokeColor = [UIColor color:HEX_NCS_RED].CGColor; x; }))
__synthesize(CAShapeLayer *, alertLayer, ({ CAShapeLayer *x = [CAShapeLayer new]; [self.layer addSublayer:x]; x.fillColor = [UIColor color:HEX_IOS_GRAY].CGColor; x; }))
__synthesize(CAShapeLayer *, activityLayer, ({ CAShapeLayer *x = [CAShapeLayer new]; [self.layer addSublayer:x]; x.fillColor = [UIColor color:HEX_NCS_BLUE].CGColor; x; }))
__synthesize(UIImageView *, timeView, ({ UIImageView *x = [[UIImageView alloc] initWithFrame:CGRectMakeWithSize(self.contentSize)]; [self addSubview:x]; x; }))
__synthesize(UIImageView *, scaleView, ({ UIImageView *x = [[UIImageView alloc] initWithFrame:CGRectMake(self.contentOffset.x, self.bounds.origin.y, self.bounds.size.width, self.contentSize.height)]; [self addSubview:x]; x; }))
__synthesize(UIImageView *, sunriseView, ({ UIImageView *x = [[UIImageView alloc] initWithImage:[UIImage imageNamed:IMG_SUNRISE]]; [self addSubview:x]; x; }))
__synthesize(UIImageView *, sunsetView, ({ UIImageView *x = [[UIImageView alloc] initWithImage:[UIImage imageNamed:IMG_SUNSET]]; [self addSubview:x]; x; }))

@synthesize sleepLatency = _sleepLatency;

- (NSNumber *)sleepLatency {
	return _sleepLatency ?: @(GLOBAL.sleepLatency);
}

- (void)setSleepLatency:(NSNumber *)sleepLatency {
	if (NSNumberIsEqualToNumber(_sleepLatency, sleepLatency))
		return;

	_sleepLatency = sleepLatency;

	self.activities = self.activities;
}

- (CGFloat)x:(NSDate *)date {
	return [date timeIntervalSinceDate:self.startDate] * self.pointsPerSecond;
}

- (CGFloat)y:(double)fraction {
	return self.contentSize.height - fraction * self.contentSize.height;
}

- (CAShapeLayer *)layerWithRect:(CGRect)rect fillColor:(UIColor *)color {
	CAShapeLayer *layer = [CAShapeLayer layerWithPath:^(CGMutablePathRef path) {
		CGPathAddRect(path, Nil, CGRectMake(0.0, 0.0, rect.size.width, rect.size.height));
	} fillColor:color.CGColor];
	layer.frame = rect;
	return layer;
}

+ (void)layer:(CALayer *)superlayer setSublayers:(NSArray<__kindof CALayer *> *)layers animated:(BOOL)animated {
	NSArray<CALayer *> *remove = [superlayer.sublayers query:^BOOL(CALayer *sublayer) {
		return ![layers any:^BOOL(CAShapeLayer *layer) {
			return CGRectEqualToRect(sublayer.frame, layer.frame);
		}];
	}];

	NSArray<CAShapeLayer *> *add = [layers query:^BOOL(CAShapeLayer *layer) {
		return ![superlayer.sublayers any:^BOOL(CALayer *sublayer) {
			return CGRectEqualToRect(layer.frame, sublayer.frame);
		}];
	}];

	for (CALayer *sublayer in remove)
		[sublayer removeFromSuperlayer];

	for (NSInteger index = 0; index < add.count; index++) {
		CAShapeLayer *layer = add[index];

		[superlayer addSublayer:layer];

		if (animated)
			[layer addAnimationFromValue:@0.0 toValue:@1.0 forKey:CALayerKeyOpacity duration:0.0 beginTime:0.025 * index];
	}
}

- (void)setInBedSamples:(NSArray<HKCategorySample *> *)samples {
	_inBedSamples = samples;

	UIColor *color = [UIColor color:HEX_IOS_LIGHT_GRAY];

	NSArray<CAShapeLayer *> *layers = [samples map:^id(HKCategorySample *obj) {
		CGFloat x = [self x:obj.startDate];
		CGFloat y = 0.0;
		CGFloat width = [self x:obj.endDate] - x;
		CGFloat height = self.contentSize.height;

		return [self layerWithRect:CGRectMake(x, y, width, height) fillColor:color];
	}];

	[GCD main:^{
		[[self class] layer:self.inBedLayer setSublayers:layers animated:NO];
	}];
}

- (void)setSleepSamples:(NSArray<HKCategorySample *> *)samples {
	_sleepSamples = samples;

	UIColor *color = RGB(63, 58, 171);

	NSMutableArray<CAShapeLayer *> *layers = [NSMutableArray new];
//	UIImage *image = [self imageWithColor:Nil draw:^(CGContextRef context) {
		CGFloat cycleWidth = 1.5 * 60.0 * 60.0 * self.pointsPerSecond;
		NSUInteger cycleCount = 0;

		for (HKCategorySample *sample in samples) {
			NSArray<CMMotionActivitySample *> *activities = sample.duration > cycleWidth ? [CMMotionActivitySample samplesFromString:sample.metadata[@"activities"] date:sample.startDate] : Nil;

			if (activities.count) {
				activities = [activities sortedArrayUsingComparator:^NSComparisonResult(CMMotionActivitySample *obj1, CMMotionActivitySample *obj2) {
					return [@(obj2.duration) compare:@(obj1.duration)];
				}];

				cycleCount = floor([activities sum:^NSNumber *(CMMotionActivitySample *obj) {
					return @(obj.duration);
				}] / (1.5 * 60.0 * 60.0));

				for (NSUInteger index = 0; index < activities.count; index++) {
					CMMotionActivitySample *activity = activities[index];

					CGFloat x = [self x:activity.startDate];
					CGFloat y = 0.0;
					CGFloat width = [self x:activity.endDate] - x;
					CGFloat height = self.contentSize.height;

					[layers addObject:[self layerWithRect:CGRectMake(x, y, width, height) fillColor:[UIColor color:index < cycleCount && [activity.startDate timeIntervalSinceDate:sample.startDate] > 60.0 * 60.0 ? RGB_DARK_PURPLE : RGB_LIGHT_VIOLET]]];
				}
			} else {
				CGFloat x = [self x:sample.startDate];
				CGFloat y = 0.0;
				CGFloat width = [self x:sample.endDate] - x;
				CGFloat height = self.contentSize.height;

				NSUInteger index = 0;
				NSUInteger count = floor(width / cycleWidth);
				for (; index < count; index++)
					[layers addObject:[self layerWithRect:CGRectMake(x + index * cycleWidth, y, cycleWidth, height) fillColor:[color colorWithAlphaComponent:0.5 + 0.05 * cycleCount++]]];

				[layers addObject:[self layerWithRect:CGRectMake(x + index * cycleWidth, y, width - index * cycleWidth, height) fillColor:[color colorWithAlphaComponent:0.5 + 0.05 * cycleCount]]];
			}
		}
//	}];

	[GCD main:^{
		[[self class] layer:self.sleepLayer setSublayers:layers animated:YES];
	}];
}

- (void)setStepsSamples:(NSArray<HKQuantitySample *> *)samples {
	_stepsSamples = samples;

	CGMutablePathRef path = CGPathCreateMutable();
	double max = 1000.0;/*[samples max:^NSNumber *(HKQuantitySample *obj) {
		return @(obj.count);
	}];
	max = fmax(max, 1000.0);*/
//	double logMax = log(max);

	for (HKQuantitySample *sample in samples) {
//		double logCount = log(sample.count);

		CGFloat x = [self x:sample.startDate];
		CGFloat y = [self y:/*logCount / logMax*/sample.count / max];
		CGFloat width = sample.duration * self.pointsPerSecond;
		CGFloat height = self.contentSize.height - y;

		CGPathAddRect(path, NULL, CGRectMake(x, y, width, height));
	}

	[GCD main:^{
		self.stepsLayer.path = path;

		CGPathRelease(path);

		[self.stepsLayer addAnimationFromValue:[NSValue valueWithCGRect:CGRectMake(self.stepsLayer.bounds.origin.x, self.stepsLayer.bounds.origin.y, self.stepsLayer.bounds.size.width, 0.0)] toValue:[NSValue valueWithCGRect:self.stepsLayer.bounds] forKey:CALayerKeyBounds];
	}];
}

- (void)setHeartSamples:(NSArray<HKQuantitySample *> *)samples {
	_heartSamples = samples;

	CGMutablePathRef path = CGPathCreateMutable();
	CGPathMoveToPoint(path, Nil, [self x:samples.firstObject.endDate], [self y:samples.firstObject.countPerMinute / 200.0]);
	for (NSUInteger index = 1; index < samples.count; index++)
		CGPathAddLineToPoint(path, Nil, [self x:samples[index].endDate], [self y:samples[index].countPerMinute / 200.0]);

	[GCD main:^{
		self.heartLayer.path = path;

		CGPathRelease(path);

		[self.heartLayer addAnimationFromValue:@1 toValue:@0 forKey:CALayerKeyStrokeStart];
	}];
}

- (void)setFallAsleep:(NSDate *)fallAsleep {
	_fallAsleep = [self.startDate isLessThanOrEqual:fallAsleep] && [self.endDate isGreaterThanOrEqual:fallAsleep] ? fallAsleep : Nil;

	if (_fallAsleep) {
		CGMutablePathRef path = CGPathCreateMutable();
		CGPathAddRect(path, NULL, CGRectMake([self x:_fallAsleep], 0.0, self.sleepLatency.doubleValue * self.pointsPerSecond, self.contentSize.height));

		[GCD main:^{
			self.alertLayer.path = path;

			CGPathRelease(path);
		}];
	} else {
		[GCD main:^{
			self.alertLayer.path = NULL;
		}];
	}
}

- (void)setActivities:(NSArray<CMMotionActivitySample *> *)activities {
	_activities = activities;

	CGMutablePathRef from = CGPathCreateMutable();

	CGMutablePathRef path = CGPathCreateMutable();
	NSArray<NSNumber *> *quartiles = [activities quartiles:^NSNumber *(CMMotionActivitySample *obj) {
		return obj.type == CMMotionActivityTypeStationary && obj.confidence == CMMotionActivityConfidenceHigh ? @(obj.duration) : Nil;
	}];

//	NSLog(@"avg: %f", avg / 60.0);
	for (CMMotionActivitySample *activity in activities) {
		CGFloat x = [self x:activity.startDate];
		CGFloat y = [self y:(activity.type == CMMotionActivityTypeAutomotive ? 6 : activity.type == CMMotionActivityTypeCycling ? 5 : activity.type == CMMotionActivityTypeRunning ? 4 : activity.type == CMMotionActivityTypeWalking ? 3 : activity.type == CMMotionActivityTypeStationary ? 2 : 1) / 7.0];
		CGFloat width = [self x:activity.endDate] - x;
		CGFloat height = activity.confidence == CMMotionActivityConfidenceHigh ? 4.0 : activity.confidence == CMMotionActivityConfidenceMedium ? 2.0 : 1.0;
		if (activity.duration >= quartiles[3].doubleValue)
			height *= 4.0;
		else if (activity.duration >= quartiles[2].doubleValue)
			height *= 3.0;
		else if (activity.duration >= quartiles[1].doubleValue)
			height *= 2.0;

		CGPathAddRoundedRect(path, NULL, CGRectMake(x, y - height / 2.0, width, height), fmin(width / 2.0, height / 2.0), height / 2.0);

		height /= 100.0;
//		width /= 100.0;
		CGPathAddRoundedRect(from, NULL, CGRectMake(x, y - height / 2.0, width, height), fmin(width / 2.0, height / 2.0), height / 2.0);
	}

	[GCD main:^{
		self.activityLayer.path = path;

		[self.activityLayer addAnimationFromValue:(__bridge id)(from) toValue:(__bridge id)(path) forKey:CALayerKeyPath];

		CGPathRelease(from);
		CGPathRelease(path);
	}];
}

- (void)setTimeInterval:(NSTimeInterval)timeInterval {
	_timeInterval = timeInterval;

	UIColor *color = [UIColor color:HEX_IOS_DARK_GRAY];
	UIImage *image = [UIImage imageWithSize:self.contentSize draw:^(CGContextRef context) {
		CGContextSetFillColorWithColor(context, color.CGColor);

		NSUInteger start = 3600 - (NSUInteger)[self.startDate timeComponent] % 3600;
		for (NSTimeInterval index = start; index < self.duration; index += 3600.0) {
			NSDate *date = [self.startDate dateByAddingTimeInterval:index];
			CGFloat x = [self x:date];
			CGContextAddRect(context, CGRectMake(x, self.contentSize.height - 8.0, 1.0, 8.0));
			CGContextDrawPath(context, kCGPathFill);

			if ((NSUInteger)(index - start) % (NSUInteger)timeInterval != 0)
				continue;

			NSString *string = [date descriptionForTime:NSDateFormatterShortStyle];
			CGSize size = [string sizeWithAttributes:Nil];
			x -= size.width / 2.0;
			if (x > 0.0 && x + size.width < self.contentSize.width)
				[string drawAtPoint:CGPointMake(x, self.contentSize.height - 24.0) withAttributes:@{ NSForegroundColorAttributeName : color }];
		}
	}];
	
	[GCD main:^{
		self.timeView.image = image;
	}];
}

- (void)setScale:(NSDictionary<NSNumber *, NSNumber *> *)scale {
	_scale = scale;

	UIColor *stepsColor = [UIColor color:HEX_IOS_YELLOW];
	UIColor *heartColor = [UIColor color:HEX_IOS_RED];
	UIImage *image = [UIImage imageWithSize:CGSizeMake(self.bounds.size.width, self.contentSize.height)/*self.bounds.size*/ draw:^(CGContextRef context) {
		for (NSNumber *key in scale.allKeys) {
			NSString *string = [key description];
			CGSize size = [string sizeWithAttributes:Nil];
			CGFloat y = [self y:key.doubleValue / 200.0] - size.height / 2.0;
			[string drawAtPoint:CGPointMake(/*12.0*/4.0, y) withAttributes:@{ NSForegroundColorAttributeName : heartColor }];

			NSNumber *val = scale[key];

			string = [val description];
			size = [string sizeWithAttributes:Nil];
			y = [self y:val.doubleValue / 1000.0] - size.height / 2.0;
			[string drawAtPoint:CGPointMake(self.bounds.size.width - size.width - /*12.0*/4.0, y) withAttributes:@{ NSForegroundColorAttributeName : stepsColor }];
		}
	}];

	[GCD main:^{
		self.scaleView.image = image;
	}];
}

- (void)setLocation:(CLLocation *)location {
//	if (CLLocationIsEqualToLocation(_location, location))
//		return;

	_location = location;

	if (location) {
		EDSunriseSet *x = [EDSunriseSet sunrisesetWithDate:self.startDate timezone:[NSCalendar currentCalendar].timeZone latitude:location.coordinate.latitude longitude:location.coordinate.longitude];
		self.sunriseView.frame = CGRectSetOrigin(self.sunriseView.frame, CGPointMake([self x:x.sunrise] - self.sunriseView.frame.size.width / 2.0, self.contentSize.height - self.sunriseView.frame.size.height));
		self.sunsetView.frame = CGRectSetOrigin(self.sunsetView.frame, CGPointMake([self x:x.sunset] - self.sunriseView.frame.size.width / 2.0, self.contentSize.height - self.sunriseView.frame.size.height));
	}

	self.sunriseView.hidden = location == Nil;
	self.sunsetView.hidden = location == Nil;
}

- (void)setupContentSize {
	self.contentSize = CGSizeMake([self.endDate timeIntervalSinceDate:self.startDate] / 60.0 * self.zoom, self.zoom == 1.0 ? 255.0 : 127.0/*self.bounds.size.height*/);
#warning Remove constant!
	self.inBedLayer.frame = CGRectMakeWithSize(self.contentSize);
	self.sleepLayer.frame = CGRectMakeWithSize(self.contentSize);

	self.alertLayer.frame = CGRectMakeWithSize(self.contentSize);
	self.activityLayer.frame = CGRectMakeWithSize(self.contentSize);

	self.stepsLayer.frame = CGRectMakeWithSize(self.contentSize);
	self.heartLayer.frame = CGRectMakeWithSize(self.contentSize);
	
	self.timeView.frame = CGRectMakeWithSize(self.contentSize);
	self.scaleView.frame = CGRectMake(self.contentOffset.x, self.bounds.origin.y, self.bounds.size.width, self.contentSize.height);

	self.inBedSamples = self.inBedSamples;
	self.sleepSamples = self.sleepSamples;
	self.stepsSamples = self.stepsSamples;
	self.heartSamples = self.heartSamples;
	self.fallAsleep = self.fallAsleep;
	self.activities = self.activities;
	self.timeInterval = self.zoom == 1.0 ? TIME_HOUR : 2 * TIME_HOUR;
	self.scale = self.zoom == 1.0 ? @{ @20 : @100, @40 : @200, @60 : @300, @80 : @400, @100 : @500, @120 : @600, @140 : @700, @160 : @800, @180 : @900  } : @{ @20 : @100, @60 : @300, @100 : @500, @140 : @700, @180 : @900 };

	self.location = self.location;
}

- (void)setZoom:(double)zoom {
	if (_zoom == zoom)
		return;

	_zoom = zoom;

	if (self.startDate && self.endDate)
		[self setupContentSize];
}

- (void)setSamples:(NSArray<HKCategorySample *> *)samples startDate:(NSDate *)startDate endDate:(NSDate *)endDate {
	if (startDate && endDate) {
		self.startDate = startDate;
		self.endDate = endDate;

		[self setupContentSize];
	}

	NSDictionary<NSNumber *, NSArray<HKCategorySample *> *> *dic = [samples dictionaryWithKey:^id<NSCopying>(HKCategorySample *obj) {
		return @(obj.value == HKCategoryValueSleepAnalysisAsleep);
	} value:^id(HKCategorySample *obj, id<NSCopying> key, id val) {
		NSMutableArray<HKCategorySample *> *arr = val ?: [NSMutableArray new];
		[arr addObject:obj];
		return arr;
	}];
	self.inBedSamples = dic[@NO];
	self.sleepSamples = dic[@YES];

	NSMutableArray<CMMotionActivitySample *> *activities = [NSMutableArray array];
	for (HKCategorySample *sample in samples)
		if (sample.metadata[HKMetadataKeySampleActivities])
			[activities addObjectsFromArray:[CMMotionActivitySample samplesFromString:sample.metadata[HKMetadataKeySampleActivities] date:sample.startDate]];
		else if (sample.metadata[HKMetadataKeyActivities])
			[activities addObjectsFromArray:[CMMotionActivitySample samplesFromString:sample.metadata[HKMetadataKeyActivities] date:Nil]];
	if (activities.count)
		self.activities = activities;
	else
		[HKActiveEnergy queryActivityStartingFromDate:self.startDate toDate:self.endDate /*within:2.0 * TIME_HOUR*/ withHandler:^(NSArray<CMMotionActivitySample *> *activities) {
			self.activities = activities;
		}];
}

- (void)loadWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate completion:(void (^)(void))completion {
	if (!startDate || !endDate)
		return;

	self.startDate = startDate;
	self.endDate = endDate;

	[self setupContentSize];

	__block BOOL sleep, steps, heart = NO;

	[[HKHealthStore defaultStore] requestAuthorizationToShare:Nil read:@[ [HKDataSleepAnalysis identifier], [HKStepCount identifier], [HKHeartRate identifier], [HKActiveEnergy identifier] ] completion:^(BOOL success) {
		[HKDataSleepAnalysis querySamplesWithStartDate:self.startDate endDate:self.endDate options:HKQueryOptionStrictEndDate limit:HKObjectQueryNoLimit sort:@{ HKSampleSortIdentifierStartDate : @YES } completion:^(NSArray<HKCategorySample *> *samples) {
			[self setSamples:samples startDate:Nil endDate:Nil];

			sleep = YES;

			if (sleep && steps && heart)
				if (completion)
					completion();
		}];

		[HKStepCount querySamplesWithStartDate:self.startDate endDate:self.endDate options:HKQueryOptionStrictEndDate limit:HKObjectQueryNoLimit sort:@{ HKSampleSortIdentifierEndDate : @NO } completion:^(NSArray<HKQuantitySample *> *samples) {
			self.stepsSamples = samples;

			steps = YES;

			if (sleep && steps && heart)
				if (completion)
					completion();
		}];

		void (^heartCompletion)(NSArray<HKQuantitySample *> *) = ^(NSArray<HKQuantitySample *> *samples) {
			self.heartSamples = samples;

			heart = YES;

			if (sleep && steps && heart)
				if (completion)
					completion();
		};
		[HKHeartRate querySamplesWithStartDate:self.startDate endDate:self.endDate options:HKQueryOptionStrictEndDate limit:HKObjectQueryNoLimit sort:@{ HKSampleSortIdentifierEndDate : @NO } completion:^(NSArray<HKQuantitySample *> *samples) {
			if (samples.count && [samples.firstObject.startDate timeIntervalSinceDate:self.startDate] > TIME_MINUTE)
				[HKHeartRate querySamplesWithStartDate:[self.startDate dateByAddingTimeInterval:0.0 - TIME_HOUR] endDate:self.startDate options:HKQueryOptionStrictEndDate limit:HKObjectQueryNoLimit sort:@{ HKSampleSortIdentifierEndDate : @NO } completion:^(NSArray<HKQuantitySample *> *previousSamples) {
					heartCompletion(previousSamples.count ? [samples arrayByAddingObject:previousSamples.firstObject] : samples);
				}];
			else
				heartCompletion(samples);
		}];
	}];
}

- (void)loadWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate {
	[self loadWithStartDate:startDate endDate:endDate completion:Nil];
}

- (void)scrollRectToStartDate:(NSDate *)startDate endDate:(NSDate *)endDate animated:(BOOL)animated {
	if ([self.startDate isGreaterThan:startDate])
		startDate = self.startDate;
	else if ([self.endDate isLessThan:startDate])
		startDate = self.endDate;

	if (endDate) {
		if ([self.startDate isGreaterThan:endDate])
			endDate = self.startDate;
		else if ([self.endDate isLessThan:endDate])
			endDate = self.endDate;
	}

	if ([endDate isEqualToDate:startDate])
		endDate = Nil;

	CGFloat x = [self x:startDate];
	CGRect rect = endDate ? CGRectMake(x, 0.0, [self x:endDate] - x, self.contentSize.height) : self.contentOffset.x < x ? CGRectMake(x - 1.0, 0.0, 1.0, self.contentSize.height) : self.contentOffset.x > x ? CGRectMake(x, 0.0, 1.0, self.contentSize.height) : CGRectZero;

	if (CGRectIsZero(rect))
		return;

	[self scrollRectToVisible:rect animated:animated];
}

- (void)scrollRectToVisibleDate:(NSDate *)date animated:(BOOL)animated {
	if ([self.startDate isLessThanOrEqual:date] && [self.endDate isGreaterThanOrEqual:date])
		[self scrollRectToStartDate:date endDate:Nil animated:animated];
}

- (void)scrollRectToVisibleDate:(NSDate *)date {
	[self scrollRectToVisibleDate:date animated:NO];
}

- (void)dealloc {
	[self.inBedLayer removeFromSuperlayer];
	[self.sleepLayer removeFromSuperlayer];
	[self.stepsLayer removeFromSuperlayer];
	[self.heartLayer removeFromSuperlayer];
	[self.alertLayer removeFromSuperlayer];
	[self.activityLayer removeFromSuperlayer];
	[self.timeView removeFromSuperview];
	[self.scaleView removeFromSuperview];
	[self.sunriseView removeFromSuperview];
	[self.sunsetView removeFromSuperview];
}

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];

	if (self)
		self.delegate = self;

	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];

	if (self)
		self.delegate = self;

	return self;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	self.scaleView.frame = CGRectMake(self.contentOffset.x, self.bounds.origin.y, self.bounds.size.width, self.contentSize.height);
}

@end

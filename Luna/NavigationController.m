//
//  NavigationController.m
//  Sleep Diary
//
//  Created by Alexander Ivanov on 16.03.16.
//  Copyright © 2016 Alexander Ivanov. All rights reserved.
//

#import "NavigationController.h"
#import "AboutController.h"
#import "IntervalController.h"
#import "SettingsController.h"
#import "SegmentController.h"
#import "ActivitiesController.h"

#import "UIViewController+Answers.h"

#import "NSArray+Convenience.h"
#import "UIGestureRecognizer+Convenience.h"
#import "UIGestureTransition.h"
#import "UIViewController+Convenience.h"

@interface NavigationController () <UINavigationControllerDelegate>
@property (strong, nonatomic, readonly) UIPanTransition *transition;
@end

@implementation NavigationController

- (NSString *)loggingName {
	return [self.viewControllers any:^BOOL(__kindof UIViewController *obj) {
		return [obj isKindOfClass:[AboutController class]];
	}] ?  @"About" : [self.viewControllers any:^BOOL(__kindof UIViewController *obj) {
		return [obj isKindOfClass:[IntervalController class]];
	}] ?  @"Interval" : [self.viewControllers any:^BOOL(__kindof UIViewController *obj) {
		return [obj isKindOfClass:[SettingsController class]];
	}] ?  @"Settings" : [self.viewControllers any:^BOOL(__kindof UIViewController *obj) {
		return [obj isKindOfClass:[SegmentController class]];
	}] ?  @"Analisys" : [self.viewControllers any:^BOOL(__kindof UIViewController *obj) {
		return [obj isKindOfClass:[ActivitiesController class]];
	}] ?  @"Activity" : Nil;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	[self startLogging];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	
	[self endLogging];
}

__synthesize(UIPanTransition *, transition, [UIPanTransition gestureTransition:Nil])

- (void)viewDidLoad {
	[super viewDidLoad];

	if (self.modalPresentationStyle == UIModalPresentationFullScreen) {
		self.containingViewController.transitioningDelegate = self.transition;

		[self.navigationBar addPanWithTarget:self];

//		[cls(UIScrollView, self.lastViewController.view).panGestureRecognizer addTarget:self action:@selector(pan:)];

		self.delegate = self;
	}
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
	if (![viewController isKindOfClass:[ActivitiesController class]])
		[cls(UIScrollView, viewController.view).panGestureRecognizer addTarget:self action:@selector(pan:)];
}

- (void)pan:(UIPanGestureRecognizer *)sender {
	if (sender.state == UIGestureRecognizerStateBegan && 0.0 - cls(UIScrollView, sender.view).contentOffset.y >= cls(UIScrollView, sender.view).contentInset.top) {
		__block id <UIViewControllerTransitioningDelegate> transition = self.containingViewController.transitioningDelegate = [UIPanTransition gestureTransition:sender];

		[self.presentingViewController dismissViewControllerAnimated:YES completion:^{
			transition = self.containingViewController.transitioningDelegate = Nil;
		}];
	}
}

@end

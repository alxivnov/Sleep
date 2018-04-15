//
//  ActivitiesController.m
//  Sleep Diary
//
//  Created by Alexander Ivanov on 01.10.16.
//  Copyright © 2016 Alexander Ivanov. All rights reserved.
//

#import "ActivitiesController.h"
#import "ActivityController.h"
#import "Global.h"

#import "NSArray+Convenience.h"
#import "NSCalendar+Convenience.h"
#import "NSFormatter+Convenience.h"
#import "UIColor+Convenience.h"
#import "UIView+Convenience.h"
#import "UIViewController+Convenience.h"

@interface ActivitiesController ()
@property (strong, nonatomic) NSArray<NSDate *> *dates;
@end

@implementation ActivitiesController

__synthesize(NSArray *, dates, ({
	NSDate *now = [NSDate date];
	NSDate *today = [now dateComponent];
	NSUInteger weekday = [now weekday];
	NSUInteger firstWeekday = [NSDate firstWeekday];
	if (firstWeekday == 1 && weekday == 0)
		weekday = 7;

	[NSArray arrayFromCount:weekday - firstWeekday + 1 block:^id(NSUInteger index) {
		return [today addValue:firstWeekday - weekday + index forComponent:NSCalendarUnitDay];
	}];
}))

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view.

	self.delegate = self;

	self.view.backgroundColor = RGB(13, 13, 13);

	[UIPageControl appearance].currentPageIndicatorTintColor = GLOBAL.tintColor;
	[UIPageControl appearance].pageIndicatorTintColor = [UIColor lightGrayColor];

//	[self pageViewController:self didFinishAnimating:NO previousViewControllers:@[ ] transitionCompleted:YES];


	
	UIScrollView *scrollView = [self.view subview:UISubviewKindOfClass(UIScrollView)];
	scrollView.canCancelContentTouches = NO;
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

- (UIViewController *)viewControllerForIndex:(NSUInteger)index {
	NSDate *obj = idx(self.dates, index);
	if (!obj)
		return Nil;

	ActivityController *vc = [[UIStoryboard mainStoryboard] instantiateViewControllerWithIdentifier:@"activity"];
	vc.startDate = obj;
	vc.endDate = [obj addValue:1 forComponent:NSCalendarUnitDay];
	vc.navigationItem.title = [[obj descriptionForDate:NSDateFormatterMediumStyle] uppercaseString];

	vc.view.tag = index;
	[vc.tableView.panGestureRecognizer addTarget:self.navigationController action:@selector(pan:)];

	if (@available(iOS 11.0, *)) {

	} else {
		UIEdgeInsets inset = vc.tableView.contentInset;
		inset.top += [UIViewController statusBarHeight] + self.navigationController.navigationBar.frame.size.height;
		vc.tableView.contentInset = inset;
	}

	return vc;
}

- (NSUInteger)indexForViewController:(UIViewController *)viewController {
	return viewController.view.tag;
}

- (NSUInteger)currentPage {
	return self.viewControllers.count > 0 ? super.currentPage : self.weekday.unsignedIntegerValue;
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController {
	return self.dates.count;
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController {
	return [self indexForViewController:pageViewController.viewControllers.firstObject];
}

@end

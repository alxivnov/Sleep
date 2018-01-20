//
//  ActivitiesController.m
//  Sleep Diary
//
//  Created by Alexander Ivanov on 01.10.16.
//  Copyright © 2016 Alexander Ivanov. All rights reserved.
//

#import "ActivitiesController.h"
#import "ActivityController.h"

#import "NSArray+Convenience.h"
#import "NSCalendar+Convenience.h"
#import "NSFormatter+Convenience.h"
#import "UIView+Convenience.h"
#import "UIViewController+Convenience.h"

@interface ActivitiesController ()

@end

@implementation ActivitiesController

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view.

	self.delegate = self;

	self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];

	[UIPageControl appearance].currentPageIndicatorTintColor = self.navigationController.navigationBar.barTintColor;
	[UIPageControl appearance].pageIndicatorTintColor = [UIColor lightGrayColor];



	NSDate *now = [NSDate date];
	NSDate *today = [now dateComponent];
	NSUInteger weekday = [now weekday];
	NSUInteger firstWeekday = [NSDate firstWeekday];
	if (firstWeekday == 1 && weekday == 0)
		weekday = 7;

	NSArray<NSDate *> *dates = [NSArray arrayFromCount:weekday - firstWeekday + 1 block:^id(NSUInteger index) {
		return [today addValue:firstWeekday - weekday + index forComponent:NSCalendarUnitDay];
	}];

	self.pageViewControllers = [dates map:^id(NSDate *obj) {
		ActivityController *vc = [[UIStoryboard mainStoryboard] instantiateViewControllerWithIdentifier:@"activity"];
		vc.startDate = obj;
		vc.endDate = [obj addValue:1 forComponent:NSCalendarUnitDay];
		vc.navigationItem.title = [[obj descriptionForDate:NSDateFormatterMediumStyle] uppercaseString];

		if (@available(iOS 11.0, *)) {
			
		} else {
			UIEdgeInsets inset = vc.tableView.contentInset;
			inset.top += [UIViewController statusBarHeight] + self.navigationController.navigationBar.frame.size.height;
			vc.tableView.contentInset = inset;
		}

		return vc;
	}];
	self.currentPage = [self.weekday unsignedIntegerValue];



	[self pageViewController:self didFinishAnimating:NO previousViewControllers:@[ ] transitionCompleted:YES];


	
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

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed {
	if (!completed)
		return;

	self.navigationItem.title = self.viewControllers.firstObject.navigationItem.title;
	self.navigationItem.rightBarButtonItems = self.viewControllers.firstObject.navigationItem.rightBarButtonItems;
	self.toolbarItems = self.viewControllers.firstObject.toolbarItems;
}

@end

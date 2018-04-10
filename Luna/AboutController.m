//
//  AboutController.m
//  Sleep Diary
//
//  Created by Alexander Ivanov on 25.04.15.
//  Copyright (c) 2015 Alexander Ivanov. All rights reserved.
//

#import "AboutController.h"
#import "Global.h"
#import "Localization.h"

#import "UIRateController+Answers.h"

#import "Answers+Convenience.h"
#import "Affiliates+Convenience.h"
#import "MessageUI+Convenience.h"
#import "NSBundle+Convenience.h"
#import "NSObject+Convenience.h"
#import "SKInAppPurchase.h"
#import "UIActivityViewController+Convenience.h"
#import "UIAlertController+Convenience.h"
#import "UIApplication+Convenience.h"
#import "UIScrollView+Convenience.h"
#import "UITableView+Convenience.h"
#import "UIView+Convenience.h"

#import "WatchDelegate.h"

#define IMG_LUNA_ICON @"Luna-Icon-128"
#define IDX_PURCHASE 1

@interface AboutController ()
@property (strong, nonatomic, readonly) SKInAppPurchase *purchase1;
@property (strong, nonatomic, readonly) SKInAppPurchase *purchase2;
@property (strong, nonatomic, readonly) SKInAppPurchase *purchase3;
@end

@implementation AboutController

__synthesize(SKInAppPurchase *, purchase1, [SKInAppPurchase purchaseWithProductIdentifier:APP_PURCHASE_ID_1])
__synthesize(SKInAppPurchase *, purchase2, [SKInAppPurchase purchaseWithProductIdentifier:APP_PURCHASE_ID_2])
__synthesize(SKInAppPurchase *, purchase3, [SKInAppPurchase purchaseWithProductIdentifier:APP_PURCHASE_ID_3])

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	UITableViewCell *cell0 = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
	cell0.textLabel.text = [NSBundle bundleDisplayName];
	cell0.detailTextLabel.text = [NSBundle bundleShortVersionString];

	if (self.purchase1.localizedTitle) {
		UITableViewCell *purchaseCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:IDX_PURCHASE]];
		purchaseCell.textLabel.text = self.purchase1.localizedTitle;
		purchaseCell.detailTextLabel.text = self.purchase1.localizedPrice;
	}

	if (self.purchase2.localizedTitle) {
		UITableViewCell *purchaseCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:IDX_PURCHASE]];
		purchaseCell.textLabel.text = self.purchase2.localizedTitle;
		purchaseCell.detailTextLabel.text = self.purchase2.localizedPrice;
	}

	if (self.purchase3.localizedTitle) {
		UITableViewCell *purchaseCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:IDX_PURCHASE]];
		purchaseCell.textLabel.text = self.purchase3.localizedTitle;
		purchaseCell.detailTextLabel.text = self.purchase3.localizedPrice;
	}

//	[purchaseCell.imageView animate:CGAffineTransformMakeRotation(DEG_360 / 4) duration:1.25 damping:0.1 velocity:ANIMATION_VELOCITY options:ANIMATION_OPTIONS completion:Nil];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	return section == IDX_PURCHASE ? self.purchase1.localizedDescription ?: self.purchase2.localizedDescription ?: self.purchase3.localizedDescription ?: [super tableView:tableView titleForFooterInSection:section] : [super tableView:tableView titleForFooterInSection:section];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0) {
		UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
		cell.detailTextLabel.text = [cell.detailTextLabel.text isEqualToString:[NSBundle bundleVersion]] ? [NSBundle bundleShortVersionString] : [NSBundle bundleVersion];
/*
		if ([WatchDelegate instance].reachableSession) {
			NSDate *date = [NSDate date];
			[[WatchDelegate instance] getActivitiesFromDate:[date addValue:-1 forComponent:NSCalendarUnitDay] toDate:date handler:^(NSArray<CMMotionActivitySample *> *activities) {
				NSArray *arr = [activities map:^id(CMMotionActivitySample *obj) {
					return [NSString stringWithFormat:@"%@,%f,%lu,%lu", [obj.startDate descriptionWithFormat:@"yyyy'-'MM'-'dd' 'HH':'mm':'ss" calendar:Nil], obj.duration, obj.type, obj.confidence];
				}];
				NSString *str = [arr componentsJoinedByString:STR_NEW_LINE];
				[self presentActivityWithActivityItems:arr_(str)];
			}];
		}
*/
	} else if (indexPath.section == IDX_PURCHASE) {
		__weak AboutController *__self = self;

		SKInAppPurchase *purchase = indexPath.row == 1 ? self.purchase2 : indexPath.row == 2 ? self.purchase3 : self.purchase1;

		[purchase requestProduct:^(SKProduct *product, NSError *error) {
			SKPayment *payment = [purchase requestPayment:product handler:^(NSArray<SKPaymentTransaction *> *transactions) {
				BOOL success = transactions.lastObject.transactionState == SKPaymentTransactionStatePurchased;

				if (success)
					[__self presentAlertWithTitle:[Localization thankYou] message:[Localization feedbackMessage] cancelActionTitle:Nil destructiveActionTitle:Nil otherActionTitles:@[ [Localization yes], [Localization no] ] completion:^(UIAlertController *instance, NSInteger index) {
						if (index == 0)
							[__self presentMailComposeWithRecipient:STR_EMAIL subject:[NSBundle bundleDisplayNameAndShortVersion]];
					}];
				else
					[__self presentAlertWithError:error cancelActionTitle:[Localization cancel]];

				[Answers logPurchaseWithPrice:product.price currency:product.priceLocale.currencyCode success:@(success) itemName:product.localizedTitle itemType:Nil itemId:product.productIdentifier customAttributes:dic_(@"error", transactions.lastObject.error.shortDescription)];

				for (SKPaymentTransaction *transaction in transactions)
					[Answers logError:transaction.error];
			}];

			[Answers logStartCheckoutWithPrice:product.price currency:product.priceLocale.currencyCode itemCount:@(payment.quantity) customAttributes:dic_(@"error", error.shortDescription)];

			[Answers logError:error];
		}];

		[Answers logAddToCartWithPrice:purchase.price currency:purchase.currencyCode itemName:purchase.localizedTitle itemType:Nil itemId:purchase.productIdentifier customAttributes:Nil];
	} else if (indexPath.section == 2) {
		UIImage *screenshot = [self.presentingViewController.view snapshotImageAfterScreenUpdates:YES];

		[self presentMailComposeWithRecipients:arr_(STR_EMAIL) subject:[NSBundle bundleDisplayNameAndShortVersion] body:Nil attachments:screenshot ? @{ @"screenshot.jpg" : [screenshot jpegRepresentation] } : Nil completionHandler:Nil];
	} else if (indexPath.section == 3) {
		[self presentWebActivityWithActivityItems:@[ [NSBundle bundleDisplayName], [NSURL URLForMobileAppWithIdentifier:APP_ID_LUNA affiliateInfo:GLOBAL.affiliateInfo] ] excludedTypes:Nil completionHandler:^(UIActivityType  _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
			[Answers logInviteWithMethod:activityType customAttributes:@{ @"version" : [NSBundle bundleVersion], @"success" : completed ? @"YES" : @"NO", @"error" : [activityError debugDescription] ?: STR_EMPTY }];
		}];
	} else if (indexPath.section == 4) {
		[UIApplication openURL:[NSURL URLForMobileAppWithIdentifier:APP_ID_LUNA affiliateInfo:GLOBAL.affiliateInfo] options:Nil completionHandler:^(BOOL success) {
			[UIRateController logRateWithMethod:@"AboutController" success:success];
		}];
	} else if (indexPath.section == 5) {
		if (indexPath.row == 0)
			[self presentProductWithIdentifier:APP_ID_DONE parameters:GLOBAL.affiliateInfo];
		else if (indexPath.row == 1)
			[self presentProductWithIdentifier:APP_ID_DONE parameters:GLOBAL.affiliateInfo];
	}
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}
/*
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 4;//5;
}
*/

@end

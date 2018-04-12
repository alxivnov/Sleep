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
#define IDX_APPS 5

#define DEV_ID 734258593

@interface AboutController ()
@property (strong, nonatomic, readonly) SKInAppPurchase *purchase1;
@property (strong, nonatomic, readonly) SKInAppPurchase *purchase2;
@property (strong, nonatomic, readonly) SKInAppPurchase *purchase3;

@property (strong, nonatomic) NSArray<AFMediaItem *> *apps;
@end

@implementation AboutController

__synthesize(SKInAppPurchase *, purchase1, [SKInAppPurchase purchaseWithProductIdentifier:APP_PURCHASE_ID_1])
__synthesize(SKInAppPurchase *, purchase2, [SKInAppPurchase purchaseWithProductIdentifier:APP_PURCHASE_ID_2])
__synthesize(SKInAppPurchase *, purchase3, [SKInAppPurchase purchaseWithProductIdentifier:APP_PURCHASE_ID_3])

- (void)viewDidLoad {
	[super viewDidLoad];

	NSURL *url = [[NSFileManager URLForDirectory:NSCachesDirectory] URLByAppendingPathComponent:[NSString stringWithFormat:@"%ul.plist", DEV_ID]];
	self.apps = [[NSArray arrayWithContentsOfURL:url] map:^id(id obj) {
		return [[AFMediaItem alloc] initWithDictionary:obj];
	}];

	[AFMediaItem lookup:@{ KEY_ID : @(DEV_ID), KEY_MEDIA : kMediaSoftware, KEY_ENTITY : kEntitySoftware } handler:^(NSArray<AFMediaItem *> *results) {
		self.apps = [results query:^BOOL(AFMediaItem *obj) {
			return [obj.wrapperType isEqualToString:kMediaSoftware] && obj.trackId.unsignedIntegerValue != APP_ID_LUNA;
		}];
		[[self.apps map:^id(AFMediaItem *obj) {
			return obj.dictionary;
		}] writeToURL:url];

		if (self.apps.count)
			[GCD main:^{
				if (self.tableView.numberOfSections > 4)
					[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:4] withRowAnimation:UITableViewRowAnimationAutomatic];
				else
					[self.tableView insertSections:[NSIndexSet indexSetWithIndex:4] withRowAnimation:UITableViewRowAnimationAutomatic];
			}];
	}];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 5 + (self.apps.count ? 1 : 0);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return section == IDX_PURCHASE ? 3 : section == IDX_APPS ? self.apps.count : 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return section == IDX_PURCHASE ? loc(@"TIPS") : section == 2 ? loc(@"FEEDBACK") : section == 3 ? loc(@"SHARE") : section == 4 ? loc(@"RATE") : section == IDX_APPS ? loc(@"APPS") : Nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	return section == IDX_PURCHASE ? self.purchase1.localizedDescription ?: self.purchase2.localizedDescription ?: self.purchase3.localizedDescription ?: [super tableView:tableView titleForFooterInSection:section] : [super tableView:tableView titleForFooterInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:indexPath.section == IDX_PURCHASE ? [NSString stringWithFormat:@"%ld%ld", indexPath.section, indexPath.row] : str(indexPath.section) forIndexPath:indexPath];

	if (indexPath.section == 0 && indexPath.row == 0) {
		cell.textLabel.text = [NSBundle bundleDisplayName];
		cell.detailTextLabel.text = [NSBundle bundleShortVersionString];
	} else if (indexPath.section == IDX_PURCHASE && indexPath.row == 0 && self.purchase1.localizedTitle) {
		cell.textLabel.text = self.purchase1.localizedTitle;
		cell.detailTextLabel.text = self.purchase1.localizedPrice;
	} else if (indexPath.section == IDX_PURCHASE && indexPath.row == 1 && self.purchase2.localizedTitle) {
		cell.textLabel.text = self.purchase2.localizedTitle;
		cell.detailTextLabel.text = self.purchase2.localizedPrice;
	} else if (indexPath.section == IDX_PURCHASE && indexPath.row == 2 && self.purchase3.localizedTitle) {
		cell.textLabel.text = self.purchase3.localizedTitle;
		cell.detailTextLabel.text = self.purchase3.localizedPrice;
	} else if (indexPath.section == IDX_APPS) {
		AFMediaItem *app = self.apps[indexPath.row];

		NSArray *titles = [app.trackName componentsSeparatedByString:@" - "];
		cell.textLabel.text = titles.count > 1 ? titles.firstObject : app.trackName;
		cell.detailTextLabel.text = titles.count > 1 ? titles.lastObject : [app.dictionary[@"genres"] firstObject];
		if (URL_CACHE(app.artworkUrl100).isExistingFile)
			cell.imageView.image = [[UIImage image:URL_CACHE(app.artworkUrl100)] imageWithSize:CGSizeMake(30.0, 30.0) mode:UIImageScaleAspectFit];
		else
			[app.artworkUrl100 cache:^(NSURL *url) {
				[GCD main:^{
					cell.imageView.image = [[UIImage image:url] imageWithSize:CGSizeMake(30.0, 30.0) mode:UIImageScaleAspectFit];
				}];
			}];
	}

	return cell;
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
		[self presentProductWithIdentifier:[self.apps[indexPath.row].trackId integerValue] parameters:Nil];
	}
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end

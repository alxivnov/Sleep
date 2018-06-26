//
//  StatisticsController.m
//  Sleep Diary
//
//  Created by Alexander Ivanov on 04.06.17.
//  Copyright © 2017 Alexander Ivanov. All rights reserved.
//

#import "StatisticsController.h"

#import "Accelerate+Convenience.h"
#import "NSFormatter+Convenience.h"
#import "NSObject+Convenience.h"
#import "UIColor+Convenience.h"
#import "UIImage+Convenience.h"

@interface StatisticsController ()
@property (weak, nonatomic) IBOutlet UIImageView *meanAndStandardDeviation;
@property (weak, nonatomic) IBOutlet UILabel *mean;
@property (weak, nonatomic) IBOutlet UILabel *standardDeviation;

@property (weak, nonatomic) IBOutlet UIImageView *fiveNumberSummary;
@property (weak, nonatomic) IBOutlet UILabel *min;
@property (weak, nonatomic) IBOutlet UILabel *q1;
@property (weak, nonatomic) IBOutlet UILabel *median;
@property (weak, nonatomic) IBOutlet UILabel *q3;
@property (weak, nonatomic) IBOutlet UILabel *max;
@end

@implementation StatisticsController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

	NSDateComponentsFormatter *formatter = [NSDateComponentsFormatter mmssAbbreviatedFormatter];

	NSArray<NSNumber *> *meanAndStandardDeviation = [self.samples meanAndStandardDeviation:^NSNumber *(CMMotionActivitySample *obj) {
		return obj.confidence == CMMotionActivityConfidenceHigh ? @(obj.duration) : Nil;
	}];
	double avg = meanAndStandardDeviation.firstObject.doubleValue;
	double dev = meanAndStandardDeviation.lastObject.doubleValue;
	self.mean.text = [formatter stringFromTimeInterval:avg];
	self.standardDeviation.text = [formatter stringFromTimeInterval:dev];

	NSArray<NSNumber *> *quartiles = [self.samples quartiles:^NSNumber *(CMMotionActivitySample *obj) {
		return obj.confidence == CMMotionActivityConfidenceHigh ? @(obj.duration) : Nil;
	}];
	double q0 = quartiles[0].isNotANumber ? 0.0 : quartiles[0].doubleValue;
	double q1 = quartiles[1].isNotANumber ? 0.0 : quartiles[1].doubleValue;
	double q2 = quartiles[2].isNotANumber ? 0.0 : quartiles[2].doubleValue;
	double q3 = quartiles[3].isNotANumber ? 0.0 : quartiles[3].doubleValue;
	double q4 = quartiles[4].isNotANumber ? 0.0 : quartiles[4].doubleValue;
	self.min.text = [formatter stringFromTimeInterval:q0];
	self.q1.text = [formatter stringFromTimeInterval:q1];
	self.median.text = [formatter stringFromTimeInterval:q2];
	self.q3.text = [formatter stringFromTimeInterval:q3];
	self.max.text = [formatter stringFromTimeInterval:q4];

	CGFloat ratio = (q4 - q0) / [UIScreen mainScreen].bounds.size.width;
	self.meanAndStandardDeviation.image = [UIImage imageWithSize:self.meanAndStandardDeviation.bounds.size draw:^(CGContextRef context) {
		CGContextSetStrokeColorWithColor(context, [UIColor color:HEX_NCS_BLUE].CGColor);

		CGContextAddRect(context, CGRectMake((avg - q0) / ratio, 4.0, 1.0, 49.0));

		CGContextAddRect(context, CGRectMake((avg - dev - q0) / ratio, 4.0, 1.0, 49.0));
		CGContextAddRect(context, CGRectMake((avg + dev - q0) / ratio, 4.0, 1.0, 49.0));

		CGContextDrawPath(context, kCGPathStroke);
	}];
	self.fiveNumberSummary.image = [UIImage imageWithSize:self.fiveNumberSummary.bounds.size draw:^(CGContextRef context) {
		CGContextSetStrokeColorWithColor(context, [UIColor color:HEX_NCS_YELLOW].CGColor);
		CGContextAddRect(context, CGRectMake((q1 - q0) / ratio, 4.0, 1.0, 49.0));
		CGContextAddRect(context, CGRectMake((q3 - q0) / ratio, 4.0, 1.0, 49.0));
		CGContextDrawPath(context, kCGPathStroke);

		CGContextSetStrokeColorWithColor(context, [UIColor color:HEX_NCS_RED].CGColor);
		CGContextAddRect(context, CGRectMake(0.0, 4.0, 1.0, 49.0));
		CGContextAddRect(context, CGRectMake(self.fiveNumberSummary.bounds.size.width - 1.0, 4.0, 1.0, 49.0));
		CGContextDrawPath(context, kCGPathStroke);

		CGContextSetStrokeColorWithColor(context, [UIColor color:HEX_NCS_GREEN].CGColor);
		CGContextAddRect(context, CGRectMake((q2 - q0) / ratio, 4.0, 1.0, 49.0));
		CGContextDrawPath(context, kCGPathStroke);
	}];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
/*
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
#warning Incomplete implementation, return the number of sections
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#warning Incomplete implementation, return the number of rows
    return 0;
}
*/
/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

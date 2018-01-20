//
//  HKCategorySample+JSON.m
//  Sleep Diary
//
//  Created by Alexander Ivanov on 15.06.17.
//  Copyright © 2017 Alexander Ivanov. All rights reserved.
//

#import "HKCategorySample+JSON.h"

#import "HKData.h"
#import "NSFormatter+Convenience.h"

@implementation HKCategorySample (JSON)

- (NSDictionary *)json {
	return @{ @"categoryType" : self.categoryType.identifier ?: @"", @"value" : @(self.value), @"startDate" : [[NSDateFormatter RFC3339Formatter] stringFromValue:self.startDate] ?: @"", @"endDate" : [[NSDateFormatter RFC3339Formatter] stringFromValue:self.endDate] ?: @"", @"source" : self.sourceName ?: @"", @"device" : self.device.name ?: @"", @"metadata" : self.metadata ?: @{ } };
}

+ (instancetype)categorySampleFromJSON:(NSDictionary *)json {
	return [json[@"categoryType"] length] ? [HKCategorySample categorySampleWithType:[HKCategoryType categoryTypeForIdentifier:json[@"categoryType"]] value:[json[@"value"] integerValue] startDate:[[NSDateFormatter RFC3339Formatter] dateFromValue:json[@"startDate"]] endDate:[[NSDateFormatter RFC3339Formatter] dateFromValue:json[@"endDate"]] metadata:json[@"metadata"]] : Nil;
}

@end

//
//  HKCategorySample+JSON.h
//  Sleep Diary
//
//  Created by Alexander Ivanov on 15.06.17.
//  Copyright © 2017 Alexander Ivanov. All rights reserved.
//

#import <HealthKit/HealthKit.h>

@interface HKCategorySample (JSON)

- (NSDictionary *)json;

+ (instancetype)categorySampleFromJSON:(NSDictionary *)json;

@end

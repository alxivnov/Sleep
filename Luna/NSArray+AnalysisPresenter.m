//
//  NSArray+AnalysisPresenter.m
//  Sleep Diary
//
//  Created by Alexander Ivanov on 08/09/16.
//  Copyright © 2016 Alexander Ivanov. All rights reserved.
//

#import "NSArray+AnalysisPresenter.h"

@implementation NSArray (AnalysisPresenter)

- (NSTimeInterval)sumDuration {
	return [self vSum:^NSNumber *(id obj) {
		AnalysisPresenter *presenter = cls(AnalysisPresenter, obj);

		return presenter ? @(presenter.duration) : Nil;
	}];
}

- (double)sumCycleCount {
	return [self vSum:^NSNumber *(id obj) {
		AnalysisPresenter *presenter = cls(AnalysisPresenter, obj);

		return presenter ? @(presenter.cycleCount) : Nil;
	}];
}

- (NSTimeInterval)avgStartTime {
	double avg = [self vAvg:^NSNumber *(id obj) {
		AnalysisPresenter *presenter = cls(AnalysisPresenter, obj);

		return presenter ? @([presenter.startDate timeComponent] + ([[presenter.startDate dateComponent] isEqualToDate:[presenter.endDate dateComponent]] ? TIME_DAY : 0.0)) : Nil;
	}];
	return avg - (avg < TIME_DAY ? 0.0 : TIME_DAY);
}

- (NSTimeInterval)avgEndTime {
	return [self vAvg:^NSNumber *(id obj) {
		AnalysisPresenter *presenter = cls(AnalysisPresenter, obj);

		return presenter ? @([presenter.endDate timeComponent]) : Nil;
	}];
}

- (NSTimeInterval)avgDuration {
	return [self vAvg:^NSNumber *(id obj) {
		AnalysisPresenter *presenter = cls(AnalysisPresenter, obj);

		return presenter ? @(presenter.duration) : Nil;
	}];
}

- (double)avgCycleCount {
	return [self vAvg:^NSNumber *(id obj) {
		AnalysisPresenter *presenter = cls(AnalysisPresenter, obj);

		return presenter ? @(presenter.cycleCount) : Nil;
	}];
}

@end

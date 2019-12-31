//
//  ADVideoData.m
//  AdViewVideoSample
//
//  Created by AdView on 15-4-9.
//  Copyright (c) 2015年 AdView. All rights reserved.
//

#import "ADVideoData.h"

@implementation ADVideoData
@synthesize videoSize;
@synthesize htmlData;
@synthesize actClickUrlStr;
@synthesize showSourceUrlArr;
@synthesize adBody;
@synthesize adActionType;
@synthesize showReportArr;
@synthesize clickReportArr;
@synthesize otherPlatArray;

- (void)dealloc{
    htmlData = nil;
    actClickUrlStr = nil;
    showSourceUrlArr = nil;
    adBody = nil;
    showReportArr = nil;
    clickReportArr = nil;
    otherPlatArray = nil;
}

@end

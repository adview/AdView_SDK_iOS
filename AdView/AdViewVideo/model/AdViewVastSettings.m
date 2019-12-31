//
//  ADVASTSettings.m
//  AdViewVideoSample
//
//  Created by AdView on 16/10/9.
//  Copyright © 2016年 AdView. All rights reserved.
//

#import "AdViewVastSettings.h"


const NSString* AdViewkVASTKitVersion     = @"1.0.6";
int const AdViewkMaxRecursiveDepth = 5;
float const AdViewkPlayTimeCounterInterval = 1;
NSTimeInterval const AdViewkVideoLoadTimeoutInterval = 6.0;
NSTimeInterval const AdViewkFirstShowControlsDelay = 4.0;
BOOL const adcmopkValidateWithSchema = NO;

@implementation AdViewVastSettings

static NSTimeInterval AdViewVastVideoLoadTimeout = 10;

+ (NSTimeInterval)vastVideoLoadTimeout
{
    return AdViewVastVideoLoadTimeout ? AdViewVastVideoLoadTimeout : AdViewkVideoLoadTimeoutInterval;
}

+ (void)setVastVideoLoadTimeout:(NSTimeInterval)newValue
{
    if (newValue!=AdViewVastVideoLoadTimeout) {
        AdViewVastVideoLoadTimeout = newValue>=AdViewkVideoLoadTimeoutInterval?newValue:AdViewkVideoLoadTimeoutInterval;  // force minimum to default value
    }
}

@end

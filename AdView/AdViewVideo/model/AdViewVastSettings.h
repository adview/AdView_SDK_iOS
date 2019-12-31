//
//  ADVASTSettings.h
//  AdViewVideoSample
//
//  Created by AdView on 16/10/9.
//  Copyright © 2016年 AdView. All rights reserved.
//

#import <Foundation/Foundation.h>

extern const NSString* AdViewkVASTKitVersion;
extern const int AdViewkMaxRecursiveDepth;
extern const float AdViewkPlayTimeCounterInterval;
extern const NSTimeInterval  AdViewkVideoLoadTimeoutInterval;
extern const NSTimeInterval AdViewkFirstShowControlsDelay;
extern const BOOL adcmopkValidateWithSchema;

@interface AdViewVastSettings : NSObject

+ (NSTimeInterval)vastVideoLoadTimeout;
+ (void)setVastVideoLoadTimeout:(NSTimeInterval)newValue;

@end

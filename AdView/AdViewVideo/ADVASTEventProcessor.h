//
//  ADVASTEventProcessor.h
//  AdViewVideoSample
//
//  Created by maming on 16/10/8.
//  Copyright © 2016年 maming. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ADVASTViewController.h"

typedef enum {
    VASTEventTrackCreativeView,
    VASTEventTrackStart,
    VASTEventTrackFirstQuartile,
    VASTEventTrackMidpoint,
    VASTEventTrackThirdQuartile,
    VASTEventTrackComplete,
    VASTEventTrackCloseLinear,
    VASTEventTrackPause,
    VASTEventTrackResume,
    VASTEventTrackSkip
}ADVASTEvent;

@interface ADVASTEventProcessor : NSObject

- (id)initWithTrackingEvents:(NSDictionary *)trackingEvents withDelegate:(id<ADVASTViewControllerDelegate>)delegate;    // designated initializer, uses tracking events stored in VASTModel
- (void)trackEvent:(ADVASTEvent)vastEvent;                       // sends the given VASTEvent
- (void)sendVASTUrlsWithId:(NSArray *)vastUrls;                // sends the set of http requests to supplied URLs, used for Impressions, ClickTracking, and Errors.

@end

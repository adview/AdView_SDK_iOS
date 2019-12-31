//
//  ADVASTEventProcessor.m
//  AdViewVideoSample
//
//  Created by maming on 16/10/8.
//  Copyright © 2016年 maming. All rights reserved.
//

#import "ADVASTEventProcessor.h"
#import "ADVASTUrlWithId.h"
#import "AdCompExtTool.h"

@interface ADVASTEventProcessor()

@property (nonatomic, strong) NSDictionary *trackingEvents;
@property (nonatomic, strong) id<ADVASTViewControllerDelegate> delegate;

@end

@implementation ADVASTEventProcessor
// designated initializer
- (id)initWithTrackingEvents:(NSDictionary *)trackingEvents withDelegate:(id<ADVASTViewControllerDelegate>)delegate
{
    self = [super init];
    if (self) {
        self.trackingEvents = trackingEvents;
        self.delegate = delegate;
    }
    return self;
}

- (void)trackEvent:(ADVASTEvent)vastEvent
{
    switch (vastEvent) {
            
        case VASTEventTrackCreativeView:
            if ([self.delegate respondsToSelector:@selector(vastTrackingEvent:)]) {
                [self.delegate vastTrackingEvent:@"creativeView"];
            }
            
            for (NSString *aURLStr in (self.trackingEvents)[@"creativeView"]) {
                [self sendTrackingRequest:aURLStr];
                AdCompAdLogDebug(@"VAST - Event Processor:Sent track start to url %@",aURLStr);
            }
            break;
            
        case VASTEventTrackStart:
            if ([self.delegate respondsToSelector:@selector(vastTrackingEvent:)]) {
                [self.delegate vastTrackingEvent:@"start"];
            }
            
            for (NSString *aURLStr in (self.trackingEvents)[@"start"]) {
                [self sendTrackingRequest:aURLStr];
                AdCompAdLogDebug(@"VAST - Event Processor:Sent track start to url %@",aURLStr);
            }
            break;
            
        case VASTEventTrackFirstQuartile:
            if ([self.delegate respondsToSelector:@selector(vastTrackingEvent:)]) {
                [self.delegate vastTrackingEvent:@"firstQuartile"];
            }
            
            for (NSString *aURLStr in (self.trackingEvents)[@"firstQuartile"]) {
                [self sendTrackingRequest:aURLStr];
                AdCompAdLogDebug(@"VAST - Event Processor:Sent firstQuartile to url %@",aURLStr);
            }
            break;
            
        case VASTEventTrackMidpoint:
            if ([self.delegate respondsToSelector:@selector(vastTrackingEvent:)]) {
                [self.delegate vastTrackingEvent:@"midpoint"];
            }
            
            for (NSString *aURLStr in (self.trackingEvents)[@"midpoint"]) {
                [self sendTrackingRequest:aURLStr];
                AdCompAdLogDebug(@"VAST - Event Processor:Sent midpoint to url %@",aURLStr);
            }
            break;
            
        case VASTEventTrackThirdQuartile:
            if ([self.delegate respondsToSelector:@selector(vastTrackingEvent:)]) {
                [self.delegate vastTrackingEvent:@"thirdQuartile"];
            }
            
            for (NSString *aURLStr in (self.trackingEvents)[@"thirdQuartile"]) {
                [self sendTrackingRequest:aURLStr];
                AdCompAdLogDebug(@"VAST - Event Processor:Sent thirdQuartile to url %@",aURLStr);
            }
            break;
            
        case VASTEventTrackComplete:
            if ([self.delegate respondsToSelector:@selector(vastTrackingEvent:)]) {
                [self.delegate vastTrackingEvent:@"complete"];
            }
            
            for(NSString *aURLStr in (self.trackingEvents)[@"complete"]) {
                [self sendTrackingRequest:aURLStr];
                AdCompAdLogDebug(@"VAST - Event Processor:Sent complete to url %@",aURLStr);
            }
            break;
            
        case VASTEventTrackCloseLinear:
            if ([self.delegate respondsToSelector:@selector(vastTrackingEvent:)]) {
                [self.delegate vastTrackingEvent:@"closeLinear"];
            }
            
            for (NSString *aURLStr in (self.trackingEvents)[@"closeLinear"]) {
                [self sendTrackingRequest:aURLStr];
                AdCompAdLogDebug(@"VAST - Event Processor:Sent close to url %@",aURLStr);
            }
            break;
            
        case VASTEventTrackPause:
            if ([self.delegate respondsToSelector:@selector(vastTrackingEvent:)]) {
                [self.delegate vastTrackingEvent:@"pause"];
            }
            
            for (NSString *aURLStr in (self.trackingEvents)[@"pause"]) {
                [self sendTrackingRequest:aURLStr];
                AdCompAdLogDebug(@"VAST - Event Processor:Sent pause start to url %@",aURLStr);
            }
            break;
            
        case VASTEventTrackResume:
            if ([self.delegate respondsToSelector:@selector(vastTrackingEvent:)]) {
                [self.delegate vastTrackingEvent:@"resume"];
            }
            
            for (NSString *aURLStr in (self.trackingEvents)[@"resume"]) {
                [self sendTrackingRequest:aURLStr];
                AdCompAdLogDebug(@"VAST - Event Processor:Sent resume start to url %@",aURLStr);
            }
            break;
        case VASTEventTrackSkip:
            if ([self.delegate respondsToSelector:@selector(vastTrackingEvent:)]) {
                [self.delegate vastTrackingEvent:@"skip"];
            }
            
            for (NSString *aURLStr in (self.trackingEvents)[@"skip"]) {
                [self sendTrackingRequest:aURLStr];
                AdCompAdLogDebug(@"VAST - Event Processor:Sent resume start to url %@",aURLStr);
            }
            break;
        default:
            if ([self.delegate respondsToSelector:@selector(vastTrackingEvent:)]) {
                [self.delegate vastTrackingEvent:@"Unknown"];
            }
            
            break;
    }
}

- (void)sendVASTUrlsWithId:(NSArray *)vastUrls
{
    for (ADVASTUrlWithId *urlWithId in vastUrls) {
        [self sendTrackingRequest:[urlWithId.url absoluteString]];
        if (urlWithId.id_) {
            AdCompAdLogDebug(@"VAST - Event Processor:Sent http request %@ to url %@",urlWithId.id_,urlWithId.url);
        } else {
            AdCompAdLogDebug(@"VAST - Event Processor:Sent http request to url %@",urlWithId.url);
        }
    }
}

- (void)sendTrackingRequest:(NSString *)trackingURLString
{
    dispatch_queue_t sendTrackRequestQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(sendTrackRequestQueue, ^{
        NSURL *trackingURL = [NSURL URLWithString:[[AdCompExtTool sharedTool] replaceDefineString:trackingURLString]];
        NSURLRequest* trackingURLrequest = [NSURLRequest requestWithURL:trackingURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:1.0];
        NSOperationQueue *senderQueue = [[NSOperationQueue alloc] init];
        AdCompAdLogDebug(@"VAST - Event Processor:Event processor sending request to url %@",[trackingURL absoluteString]);
        [NSURLConnection sendAsynchronousRequest:trackingURLrequest queue:senderQueue completionHandler:nil];  // Send the request only, no response or errors
    });
}

@end

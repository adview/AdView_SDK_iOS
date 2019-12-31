//
//  ADVASTMediaFileModel.m
//  KOpenAPIAdView
//
//  Created by AdView on 2018/4/27.
//

#import "AdViewVastCreative.h"
#import "AdViewExtTool.h"
#import "AdViewVastMediaFilePicker.h"

@implementation AdViewVastCreative

#pragma mark - getter method
- (AdViewVastMediaFile *)mediaFile {
    if (!_mediaFile) {
        _mediaFile = [AdViewVastMediaFilePicker pick:self.mediaFiles];
    }
    return _mediaFile;
}

#pragma mark - report methods
- (void)trackEvent:(ADVideoEvent)vastEvent
{
    switch (vastEvent) {
            
        case ADVideoEventTrackCreativeView:
            [self reportTrackingRequestWithEventString:@"creativeView"];
            break;
            
        case ADVideoEventTrackStart:
            [self reportTrackingRequestWithEventString:@"start"];
            break;
            
        case ADVideoEventTrackFirstQuartile:
            [self reportTrackingRequestWithEventString:@"firstQuartile"];
            break;
            
        case ADVideoEventTrackMidpoint:
            [self reportTrackingRequestWithEventString:@"midpoint"];
            break;
            
        case ADVideoEventTrackThirdQuartile:
            [self reportTrackingRequestWithEventString:@"thirdQuartile"];
            break;
            
        case ADVideoEventTrackComplete:
            [self reportTrackingRequestWithEventString:@"complete"];
            break;
            
        case ADVideoEventTrackCloseLinear:
            [self reportTrackingRequestWithEventString:@"closeLinear"];
            break;
            
        case ADVideoEventTrackPause:
            [self reportTrackingRequestWithEventString:@"pause"];
            break;
            
        case ADVideoEventTrackResume:
            [self reportTrackingRequestWithEventString:@"resume"];
            break;
            
        case ADVideoEventTrackSkip:
            [self reportTrackingRequestWithEventString:@"skip"];
            break;
            
        case ADVideoEventTrackMute:
            [self reportTrackingRequestWithEventString:@"mute"];
            break;
        
        case ADVideoEventTrackUnMute:
            [self reportTrackingRequestWithEventString:@"unmute"];
            break;
            
        default:
            break;
    }
}

- (void)reportTrackingRequestWithEventString:(NSString*)eventString {
    if (self.wrapperTrackingArray && self.wrapperTrackingArray.count) {
        for (NSDictionary *trackingDict in self.wrapperTrackingArray) {
            for (NSString *adURLStr in trackingDict[eventString]) {
                [self sendTrackingRequest:adURLStr];
                AdViewLogDebug(@"VAST - Event Processor:Sent wrapper %@ start to url %@",eventString,adURLStr);
            }
        }
    }
    
    for (NSString *adURLStr in self.trackings[eventString]) {
        [self sendTrackingRequest:adURLStr];
        AdViewLogDebug(@"VAST - Event Processor:Sent %@ start to url %@",eventString,adURLStr);
    }
}

- (void)reportClickTrackings
{
    if (self.clickTrackings && self.clickTrackings.count)
    {
        for (AdViewVastUrlWithId *urlWithId in self.clickTrackings)
        {
            [self sendTrackingRequest:urlWithId.url.absoluteString];
        }
    }
    
    if (self.wrapperClickTrackingArray && self.wrapperClickTrackingArray.count)
    {
        for (AdViewVastUrlWithId *urlWithId in self.wrapperClickTrackingArray)
        {
            [self sendTrackingRequest:urlWithId.url.absoluteString];
        }
    }
}

- (void)sendTrackingRequest:(NSString *)trackingURLString {
    NSURL *trackingURL = [NSURL URLWithString:[[AdViewExtTool sharedTool] replaceDefineString:trackingURLString]];
    NSMutableURLRequest* trackingURLrequest = [NSMutableURLRequest requestWithURL:trackingURL];
    trackingURLrequest.HTTPMethod = @"GET";
    trackingURLrequest.timeoutInterval = 5;
    AdViewLogDebug(@"VAST - Event Processor:Event processor sending request to url %@",[trackingURL absoluteString]);
    [NSURLConnection connectionWithRequest:trackingURLrequest delegate:nil];
}

@end

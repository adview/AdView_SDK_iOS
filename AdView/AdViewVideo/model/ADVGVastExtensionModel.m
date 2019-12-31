//
//  ADVGVastExtensionModel.m
//  AdViewHello
//
//  Created by unakayou on 8/6/19.
//

#import "ADVGVastExtensionModel.h"
#import "AdViewDefines.h"

@implementation ADVGVastExtensionModel
- (void)reportVerificationNotExecuted {
    [self reportTrackingRequestWithEventString:@"verificationNotExecuted"];
}

- (void)reportTrackingRequestWithEventString:(NSString*)eventString {
    [self sendTrackingRequest:self.trackingEvents[@"eventString"]];
}

- (void)sendTrackingRequest:(NSString *)trackingURLString
{
    NSURL *trackingURL = [NSURL URLWithString:[[AdViewExtTool sharedTool] replaceDefineString:trackingURLString]];
    NSMutableURLRequest* trackingURLrequest = [NSMutableURLRequest requestWithURL:trackingURL];
    trackingURLrequest.HTTPMethod = @"GET";
    trackingURLrequest.timeoutInterval = 5;
    [NSURLConnection connectionWithRequest:trackingURLrequest delegate:nil];
}
@end

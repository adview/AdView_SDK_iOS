//
//  ADVASTCompanionModel.m
//  KOpenAPIAdView
//
//  Created by AdView on 2018/4/27.
//

#import "ADVASTCompanionModel.h"
#import "AdViewExtTool.h"

@implementation ADVASTCompanionModel

- (void)reportImpressionTracking {
    AdViewLogDebug(@"companion view report impression trackings");
    NSArray *showArray = [self.trackingsDict objectForKey:@"creativeView"];
    if (showArray && showArray.count) {
        for (NSString *urlString in showArray) {
            NSURL *url = [NSURL URLWithString:[[AdViewExtTool sharedTool] replaceDefineString:urlString]];
            NSMutableURLRequest* impressionRequest = [NSMutableURLRequest requestWithURL:url];
            impressionRequest.HTTPMethod = @"GET";
            impressionRequest.timeoutInterval = 5;
            [NSURLConnection connectionWithRequest:impressionRequest delegate:nil];
        }
    }
}

- (void)reportClickTracking {
    AdViewLogDebug(@"companion view report click trackings");
    if (self.clickTrackingsArr && self.clickTrackingsArr.count) {
        for (NSURL *clickURL in self.clickTrackingsArr) {
            NSURL *url = [NSURL URLWithString:[[AdViewExtTool sharedTool] replaceDefineString:[clickURL absoluteString]]];
            NSMutableURLRequest* clickRequest = [NSMutableURLRequest requestWithURL:url];
            clickRequest.HTTPMethod = @"GET";
            clickRequest.timeoutInterval = 5;
            [NSURLConnection connectionWithRequest:clickRequest delegate:nil];
        }
    }
}

@end

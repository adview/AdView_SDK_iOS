//
//  ADVASTIconModel.m
//  KOpenAPIAdView
//
//  Created by AdView on 2018/4/27.
//

#import "ADVASTIconModel.h"
#import "AdViewExtTool.h"

@implementation ADVASTIconModel

- (void)reportImpressionTracking {
    AdViewLogDebug(@"iconview report impression trackings");
    if (self.viewTrackingsArr && self.viewTrackingsArr.count) {
        for (NSString *urlString in self.viewTrackingsArr) {
            NSURL *url = [NSURL URLWithString:[[AdViewExtTool sharedTool] replaceDefineString:urlString]];
            NSMutableURLRequest* impressionRequest = [NSMutableURLRequest requestWithURL:url];
            impressionRequest.HTTPMethod = @"GET";
            impressionRequest.timeoutInterval = 5;
            [NSURLConnection connectionWithRequest:impressionRequest delegate:nil];
        }
    }
}

- (void)reportClickTracking {
    AdViewLogDebug(@"iconview report click trackings");
    if (self.clickTrackingsArr && self.clickTrackingsArr.count) {
        for (NSString *clickString in self.clickTrackingsArr) {
            NSURL *url = [NSURL URLWithString:[[AdViewExtTool sharedTool] replaceDefineString:clickString]];
            NSMutableURLRequest* clickRequest = [NSMutableURLRequest requestWithURL:url];
            clickRequest.HTTPMethod = @"GET";
            clickRequest.timeoutInterval = 5;
            [NSURLConnection connectionWithRequest:clickRequest delegate:nil];
        }
    }
}

@end

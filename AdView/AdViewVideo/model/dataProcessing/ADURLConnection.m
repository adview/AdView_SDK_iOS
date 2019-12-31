//
//  ADURLConnection.m
//  AdViewVideoSample
//
//  Created by AdView on 15-4-9.
//  Copyright (c) 2015年 AdView. All rights reserved.
//

#import "ADURLConnection.h"
#import "ADConnectDataProcessor.h"
#import "AdViewExtTool.h"
#define OPENAPI_ADDATA_LIMIT 512*1024

@implementation AVTemporaryData
@synthesize posID;
@synthesize appID;
@synthesize videoType;

@end

@interface ADURLConnection()<NSURLConnectionDelegate,NSURLConnectionDataDelegate> {
    ADConnectDataProcessor *dataProcessor;
    ADURLConnectionType currentType;
    
    NSMutableData *httpData;
    NSURLResponse *conResponse;
}

@property (nonatomic, strong) NSMutableData *httpData;
@property (nonatomic, strong) NSURLResponse *conResponse;


@end

@implementation ADURLConnection
@synthesize conDelegate;
@synthesize httpData;
@synthesize conResponse;
@synthesize videoData;

- (void)dealloc {
    httpData = nil;
    conResponse = nil;
    videoData = nil;
    conDelegate = nil;
}

- (id)initWithConnectionType:(ADURLConnectionType)connectionType withTemporaryData:(AVTemporaryData *)data delegate:(id<ADURLConnectionDelegate>)delegate {
    self = [super init];
    if (self) {
        currentType = connectionType;
        self.conDelegate = delegate;
        [self makeConnectionWithTemporaryData:data];
    }
    return self;
}

- (void)makeConnectionWithTemporaryData:(AVTemporaryData*)data {
    videoData = [[ADVideoData alloc] init];
    dataProcessor = [[ADConnectDataProcessor alloc] init];
    NSURLRequest *request = [dataProcessor getVideoRequest:data];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [connection start];
}

#pragma mark - NSURLConnectionDelegate
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSMutableData *data = [[NSMutableData alloc] init];
    self.httpData = data;
    
    self.conResponse = response;
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    NSUInteger conLength = [self.httpData length] + [data length];
    if (conLength > OPENAPI_ADDATA_LIMIT) {
        [connection cancel];
        AdViewLogDebug(@"connection too large to be:%lu",(unsigned long)conLength);
        NSError *error = [NSError errorWithDomain:@"content too large" code:-1 userInfo:nil];
        [self.conDelegate connectionFailedLoadingWithError:error];
    }
    [self.httpData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    AdViewLogDebug(@"connection didFailWithError:%@",error);
    if (self.conDelegate && [self.conDelegate respondsToSelector:@selector(connectionFailedLoadingWithError:)]) {
        [self.conDelegate connectionFailedLoadingWithError:error];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSString *dataStr = nil;
    if ([self.httpData length] > 0) {
        dataStr = [[NSString alloc] initWithData:self.httpData encoding:NSUTF8StringEncoding];
        AdViewLogDebug(@"%@",dataStr);
    }
    
    NSError *error = [[NSError alloc] initWithDomain:@"没有可播放的广告" code:-1 userInfo:nil];
    BOOL bError = NO;
    
    int statusCode = (int)[(NSHTTPURLResponse*)self.conResponse statusCode];
    if (statusCode/100 != 2) {
        bError = YES;
    }
    
    if (!bError) {
        BOOL bRet = [dataProcessor parseResponse:self.httpData Error:error withVideoData:videoData];
        if (bRet) {
            if (self.conDelegate && [self.conDelegate respondsToSelector:@selector(connectionDidFinshedLoadingWithUrlConnection:)]) {
                [self.conDelegate connectionDidFinshedLoadingWithUrlConnection:self];
            }
        }
        else
            bError = YES;
    }
    
    if (bError) {
        if (self.conDelegate && [self.conDelegate respondsToSelector:@selector(connectionFailedLoadingWithError:)]) {
            [self.conDelegate connectionFailedLoadingWithError:error];
        }
    }
}

@end

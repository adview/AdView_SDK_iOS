//
//  AdViewURLProtocol.m
//  AdViewHello
//
//  Created by AdView on 16/5/25.
//
//

#import "AdViewURLProtocol.h"
#import "AdViewExtTool.h"

@interface AdViewURLProtocol() {
    NSURLConnection *connection;
}

@property (nonatomic, strong) NSURLConnection *connection;

@end

@implementation AdViewURLProtocol
@synthesize connection;

+ (NSString *)encodeToPercentEscapeString:(NSString *)input
{
    // Encode all the reserved characters, per RFC 3986
    // (<http://www.ietf.org/rfc/rfc3986.txt>)
    NSString *outputStr = (NSString *)
    CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                              (CFStringRef)input,
                                                              NULL,
                                                              (CFStringRef)@"!*'();@+$,%#[]",
                                                              kCFStringEncodingUTF8));
    return outputStr;
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    //只处理http和https请求
    NSString *scheme = [request URL].scheme;
    NSString *reqStr = request.URL.absoluteString;
    if ([AdViewExtTool sharedTool].protocolCount <= 0) {
        return NO;
    }
    
    if ([NSURLProtocol propertyForKey:@"MyURLProtocolHandledKey" inRequest:request]) {
        return NO;
    }
    
    if([scheme caseInsensitiveCompare:@"http"] == NSOrderedSame || [scheme caseInsensitiveCompare:@"https" ] == NSOrderedSame) {
        NSString *hostStr = (NSString*)[[AdViewExtTool sharedTool] objectStoredForKey:@"AdViewHost"];
        BOOL containHost = NO;
        if (nil != hostStr)
        {
            containHost = [reqStr rangeOfString:hostStr].length > 0;
        }
        containHost = [reqStr rangeOfString:@"adview.com"].length > 0 || containHost;
        if (containHost) {
            BOOL isReportUrlStr = [reqStr rangeOfString:@"display"].length > 0 || [reqStr rangeOfString:@"click"].length > 0;
            if (isReportUrlStr) {
                reqStr = [AdViewExtTool decodeFromPercentEscapeString:reqStr];
                BOOL containDefineStr = NO;
                for (NSString *string in [AdViewExtTool sharedTool].replaceStrArr) {
                    containDefineStr = [reqStr rangeOfString:string].length > 0 || containDefineStr;
                    if (containDefineStr) {
                        return YES;
                    }
                }
            }
        }
        return NO;
    }
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    NSString *reqStr = [AdViewExtTool decodeFromPercentEscapeString:request.URL.absoluteString];
    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    
    reqStr = [[AdViewExtTool sharedTool] replaceDefineString:reqStr];
//    NSLog(@"%@",reqStr);
    mutableRequest.URL = [NSURL URLWithString:[AdViewURLProtocol encodeToPercentEscapeString:reqStr]];
    return mutableRequest;
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b {
    return [super requestIsCacheEquivalent:a toRequest:b];
}

- (void)startLoading {
    NSMutableURLRequest *newRequest = [self.request mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:@"MyURLProtocolHandledKey"inRequest:newRequest];
    self.connection = [NSURLConnection connectionWithRequest:newRequest delegate:self];
}

- (void)stopLoading {
    [self.connection cancel];
    self.connection =nil;
}
#pragma mark --NSURLProtocol Delegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
//    if ([connection.currentRequest.URL.absoluteString hasSuffix:@"webp"]) {
//        UIImage *imgData = [UIImage sd_imageWithWebPData:data];
//        NSData *jpgData = UIImageJPEGRepresentation(imgData, 1.0f);
//        [self.client URLProtocol:self didLoadData:jpgData];
//    }else{
//        [self.client URLProtocol:self didLoadData:data];
//    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self.client URLProtocol:self didFailWithError:error];
}

@end

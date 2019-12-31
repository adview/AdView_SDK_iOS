//
//  ADVASTRequestTask.m
//  AdViewVideoSample
//
//  Created by AdView on 17/2/17.
//  Copyright © 2017年 AdView. All rights reserved.
//

#import "AdViewVastRequestTask.h"
#import "AdViewVastFileHandle.h"
#import "AdViewExtTool.h"

@interface AdViewVastRequestTask() <NSURLConnectionDataDelegate,NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession *session;  //会话对象
@property (nonatomic, strong) NSURLSessionTask *task; //任务

@end

@implementation AdViewVastRequestTask

- (instancetype)init {
    if (self = [super init]) {
        [AdViewVastFileHandle createTempFile];
    }
    return self;
}

- (void)dealloc {
    self.session = nil;
    self.task = nil;
}

- (void)start {
    NSURLComponents * components = [[NSURLComponents alloc] initWithURL:self.requestUrl resolvingAgainstBaseURL:NO];
    components.scheme = @"http";
    NSURL *url = [components URL];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:20];
    
    if (self.requestOffset > 0) {
        [request addValue:[NSString stringWithFormat:@"bytes=%tu-%tu",self.requestOffset,self.fileLength - 1] forHTTPHeaderField:@"Range"];
    }
    
    self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    self.task = [self.session dataTaskWithRequest:request];
    [self.task resume];
}

- (void)setIsCancel:(BOOL)isCancel {
    _isCancel = isCancel;
    [self.task cancel];
    [self.session invalidateAndCancel];
}

#pragma mark - NSURLSessionDataDelegate
//服务器响应
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    if (self.isCancel) return;
    AdViewLogDebug(@"response: %@",response);
    completionHandler(NSURLSessionResponseAllow);
    NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
    
    //视频超过200M，不下载
    NSString *contentLength = [[httpResponse allHeaderFields] objectForKey:@"Content-Length"];
    float size = [contentLength floatValue]/(1024.0*1024.0);
    if (size > URLCACHE_VIDEO_SIZE || size <= 0) {
        self.isCancel = YES;
        return;
    }
    
    NSString * contentRange = [[httpResponse allHeaderFields] objectForKey:@"Content-Range"];
    NSString * fileLength = [[contentRange componentsSeparatedByString:@"/"] lastObject];
    self.fileLength = fileLength.integerValue > 0 ? fileLength.integerValue : (NSInteger)response.expectedContentLength;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(requestTaskDidReceiveResponse)]) {
        [self.delegate requestTaskDidReceiveResponse];
    }
}

//服务器返回数据 可能会调用多次
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    if (self.isCancel) return;
    self.cacheLength += data.length;
    [AdViewVastFileHandle writeTempFileData:data];
    if (self.delegate && [self.delegate respondsToSelector:@selector(requestTaskDidUpdateCache)]) {
        [self.delegate requestTaskDidUpdateCache];
    }
}

//请求完成会调用该方法，请求失败则error有值
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (self.isCancel) {
        AdViewLogDebug(@"下载取消");
        NSError *cancelError = [NSError errorWithDomain:@"文件过大" code:error.code userInfo:nil];
        if (self.delegate && [self.delegate respondsToSelector:@selector(requestTaskDidFailWithError:task:)]) {
            [self.delegate requestTaskDidFailWithError:cancelError task:self];
        }
    }else {
        if (error) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(requestTaskDidFailWithError:task:)]) {
                [self.delegate requestTaskDidFailWithError:error task:self];
            }
        }else {
            NSString *type;
            if (self.type == ADVASTMediaFileType_Video) {
                type = @"mp4";
            }else {

                type = @"png";
            }
            
            //可以缓存则保存文件
            if (self.isCache) {
                [AdViewVastFileHandle cacheTempFileWithFileName:[AdViewVastFileHandle fileNameWithURL:self.requestUrl fileType:type]];
            }
            if (self.delegate && [self.delegate respondsToSelector:@selector(requestTaskDidFinishLoadingWithCache:task:)]) {
                [self.delegate requestTaskDidFinishLoadingWithCache:self.isCache task:self];
            }
        }
    }
}

@end

//
//  ADVGNetworkManager.m
//  AdViewHello
//
//  Created by unakayou on 7/10/19.
//

#import "ADVGNetworkManager.h"
#import "ADVGURLSessionManager.h"

@interface ADVGNetworkManager() <NSURLSessionDataDelegate, ADVGURLSessionManagerProtocol, ADVGResponseSerializationProcotol>
@property (nonatomic, strong, readwrite) AdViewAdapter * adapter;       //取广告的平台
@property (nonatomic, assign, readwrite) ADVGRequestType requestType;   //请求广告、展示汇报、点击汇报
@property (nonatomic, strong) ADVGURLSessionManager * sessionManager;   //封装的请求类
@end

@implementation ADVGNetworkManager

#pragma mark 对外接口

- (NSURLSessionDataTask *)requestAdWithAdCondition:(AdViewAdCondition *)condition
                                           adapter:(AdViewAdapter *)adapter
                                 completionHandler:(void (^)(NSURLResponse *, NSArray <AdViewContent *>*, NSError *))completionHandler {
    return [self requestType:ADVGRequestTypeRequestAd
                 adCondition:condition
                     adapter:adapter
           completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)requestAdDisplayWithAdCondition:(AdViewAdCondition *)condition
                                        ReportWithAdapter:(AdViewAdapter *)adapter {
    return [self requestType:ADVGRequestTypeDisplayReport
                 adCondition:condition
                     adapter:adapter
           completionHandler:nil];
}

- (NSURLSessionDataTask *)requestAdClickWithAdCondition:(AdViewAdCondition *)condition
                                      ReportWithAdapter:(AdViewAdapter *)adapter {
    return [self requestType:ADVGRequestTypeClickReport
                 adCondition:condition
                     adapter:adapter
           completionHandler:nil];
}

- (void)cancel {
    [_sessionManager invalidateSessionCancelingTasks:YES resetSession:YES];
}

#pragma mark - 初始化
- (NSURLSessionDataTask *)requestType:(ADVGRequestType)requestType
                          adCondition:(AdViewAdCondition *)condition
                              adapter:(AdViewAdapter *)adapter
                    completionHandler:(void (^)(NSURLResponse *, NSArray <AdViewContent *>*, NSError *))completionHandler {
    self.adapter = adapter;
    self.requestType = requestType;
    self.useCache = [_delegate respondsToSelector:@selector(useCache)] ? [_delegate useCache] : NO;
    
    //请求是否被限制(请求过快)
    BOOL requestLimited = [self requestLimitedWithLimitTime:AdViewAd_TIME_LIMIT adPlatType:_adapter.adPlatType advertType:_adapter.adType];
    NSMutableURLRequest * request = [_adapter getAdGetRequest:condition];

    //如果请求过快
    if (requestLimited) {
        if ([_delegate respondsToSelector:@selector(networkManager:didFailWithError:)]) {
            [_delegate networkManager:self didFailWithError:[NSError errorWithDomain:@"Request Too Fast." code:ADVGErrorCodeRequestTooFast userInfo:nil]];
        }
        return nil;
    } else if (_useCache) {
        //请求广告数据暂时不使用缓存
    } else {
        //不使用缓存情况, 如果不是原生广告 保存一下本次请求时间
        if (_adapter.adType != AdViewNative) {
            [self setRequestTimeAdPlatType:_adapter.adPlatType adverType:_adapter.adType];
        }
        [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    }
    NSURLSessionDataTask * task = [_sessionManager dataTaskWithRequest:request
                                                     completionHandler:completionHandler];
    return task;
}

#pragma mark - 解析协议 ADVGResponseSerializationProcotol
- (id)responseObjectForResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *__autoreleasing  _Nullable *)error {
    //如果不是请求广告直接不做操作
    if (_requestType != ADVGRequestTypeRequestAd) return nil;
    
    HTTPStatus statusCode = HTTPStatusUnkonw;
    if ([response respondsToSelector:@selector(statusCode)]) {
        statusCode = [(NSHTTPURLResponse *)response statusCode];
    }
    
    //如果Http返回成功则开始调用解析逻辑
    if (statusCode == HTTPStatusSuccess) {
        //开始解析 返回错误信息
        NSArray <AdViewContent *>* contentArray = [self contentArrayParseFromSessionData:data response:response error:error];
        if (!*error) {
            return contentArray;
        }
    } else {
        *error = [NSError errorWithDomain:@"HTTP Error" code:statusCode userInfo:nil];
    }
    return nil;
}

//解析Data具体逻辑
- (NSArray <AdViewContent *>*)contentArrayParseFromSessionData:(NSData *)sessionData response:(NSURLResponse *)response error:(NSError *__autoreleasing*)error {
    NSMutableArray <AdViewContent *>* contentArray = nil;
    switch (_requestType) {
        case ADVGRequestTypeRequestAd:
            //请求广告数据的解析
            if ([self.adapter useInternalParser]) {
                //采用自定义XML解析
            } else {
                //普通JSON
                AdViewAdapterResponse * adapterResponse = [[AdViewAdapterResponse alloc] init];
                adapterResponse.body = sessionData;
                adapterResponse.type = _requestType;
                adapterResponse.status = HTTPStatusSuccess;
                adapterResponse.headers = [(NSHTTPURLResponse *)response allHeaderFields];
                
                //使用adapter解析广告 返回错误信息
                NSString * errorString = nil;
                contentArray = [NSMutableArray new];
                BOOL bRet = [_adapter parseResponse:adapterResponse contentArr:contentArray ErrorInfo:&errorString];
                if (!bRet) {
                    *error = [[NSError alloc] initWithDomain:errorString code:ADVGErrorCodeParseFail userInfo:nil];
                }
            }
            break;
        case ADVGRequestTypeDisplayReport:  //展示汇报
        case ADVGRequestTypeClickReport:    //点击汇报
            break;
        default:
            break;
    }
    return contentArray;
}

#pragma mark NSURLSessionDataDelegate
//接收到服务器的响应
- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {

}

- (void)URLSession:(nonnull NSURLSession *)session
      downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(nonnull NSURL *)location {
    
}

#pragma mark 判断逻辑
//是否请求过快
- (BOOL)requestLimitedWithLimitTime:(NSUInteger)limitTime adPlatType:(AdViewAdPlatType)platType advertType:(AdvertType)advertType {
    NSString * lastReqTimeKey = [NSString stringWithFormat:LAST_REQTIME_FMT, platType,advertType];
    NSNumber * timeObj = (NSNumber*)[[AdViewExtTool sharedTool] objectStoredForKey:lastReqTimeKey];
    NSTimeInterval lastReqTime = [timeObj doubleValue];
    NSTimeInterval nowTime = [[NSDate date] timeIntervalSince1970];
    return (nowTime - lastReqTime < limitTime);
}

//保存本次请求时间到内存
- (void)setRequestTimeAdPlatType:(AdViewAdPlatType)platType adverType:(AdvertType)adverType {
    NSTimeInterval  requestTime = [[NSDate date] timeIntervalSince1970];
    NSString * lastReqTimeStr = [NSString stringWithFormat:LAST_REQTIME_FMT, platType,adverType];
    [[AdViewExtTool sharedTool] storeObject:[NSNumber numberWithDouble:requestTime] forKey:lastReqTimeStr];
}

#pragma mark - getter
- (NSArray *)tasks {
    return _sessionManager.tasks;
}

- (NSArray *)dataTasks {
    return _sessionManager.dataTasks;
}

- (NSArray *)downloadTask {
    return _sessionManager.downloadTasks;
}

#pragma makr 单例实现
static ADVGNetworkManager * manager = nil;
+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[super allocWithZone:NULL] init];
    });
    return manager;
}

- (instancetype)init {
    if (manager == nil && (self = [super init])) {
        self.sessionManager = [[ADVGURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        _sessionManager.delegate = self;            //这个类接收session回调
        _sessionManager.responseSerializer = self;  //这个类作为数据解析器
    }
    return self;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [ADVGNetworkManager sharedManager];
}

- (id)copyWithZone:(NSZone *)zone {
    return [ADVGNetworkManager sharedManager];
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    return [ADVGNetworkManager sharedManager];
}

@end

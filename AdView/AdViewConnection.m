#import "AdViewConnection.h"
#import "AdViewExtTool.h"
#import "AdViewContent.h"
#import "AdViewAdapter.h"
#import "AdViewDefines.h"

#define LAST_CONRESPONSE_FMT    @"lastConResponse_%zd_%zd"
#define LAST_ADRESPONSE_FMT     @"lastAdResponse_%zd_%zd"
#include <string.h>
#include <math.h>
#include <time.h>


#define AdViewAd_TIME_LIMIT		10.0f
#define Request_TIME_LIMIT      3

static void setRequestTime(NSInteger adPlatType,NSInteger adType)
{
	NSTimeInterval  requestTime = [[NSDate date] timeIntervalSince1970];
	NSString * lastReqTimeStr = [NSString stringWithFormat:LAST_REQTIME_FMT, adPlatType,adType];
	
	[[AdViewExtTool sharedTool] storeObject:[NSNumber numberWithDouble:requestTime] forKey:lastReqTimeStr];
}


static void storeResponse(AdViewAdPlatType adPlatType, AdvertType adType, NSURLResponse *conResponse, AdViewAdapterResponse *adResponse)
{
    NSString *lastConResponseKey = [NSString stringWithFormat:LAST_CONRESPONSE_FMT, adPlatType, adType];
    NSString *lastAdResponseKey = [NSString stringWithFormat:LAST_ADRESPONSE_FMT, adPlatType, adType];
    [[AdViewExtTool sharedTool] storeObject:conResponse forKey:lastConResponseKey];
    [[AdViewExtTool sharedTool] storeObject:adResponse forKey:lastAdResponseKey];
}

static BOOL requestLimited(NSInteger adPlatType,NSInteger adType)
{
	NSString * lastReqTimeStr = [NSString stringWithFormat:LAST_REQTIME_FMT, adPlatType,adType];
	NSNumber * timeObj = (NSNumber*)[[AdViewExtTool sharedTool] objectStoredForKey:lastReqTimeStr];
    
	NSTimeInterval lastReqTime = 0;
	if (nil != timeObj) lastReqTime = [timeObj doubleValue];
	
	NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    
    if (adType == AdViewSpread)
    {
        return NO; //不缓存
    }
    else
    {
        return (now - lastReqTime < AdViewAd_TIME_LIMIT);
    }
}

@implementation AdViewAdRequest
@synthesize adAppId;
@synthesize httpRequest;

- (void)dealloc
{
    AdViewLogDebug(@"Dealloc AdViewAdRequest");
    self.adAppId = nil;
    self.httpRequest = nil;
}
@end

@implementation AdViewAdResponse
@end

@implementation AdViewAdGetRequest

+ (AdViewAdGetRequest*)requestWithConditon:(AdViewAdCondition*)condition adapter:(AdViewAdapter*)adapter
{
    AdViewAdGetRequest* request = [[AdViewAdGetRequest alloc] init];
    if (request)
    {
		request.adAppId = condition.appId;
		request.httpRequest = [adapter getAdGetRequest:condition];
    }
    return request;
}

- (void)dealloc
{
    AdViewLogDebug(@"Dealloc AdViewAdGetRequest");
}
@end

@implementation AdViewAdDisplayRequest
+ (AdViewAdDisplayRequest *)requestWithAdContent:(AdViewContent *)theAdContent Adapter:(AdViewAdapter *)adapter
{
    AdViewAdDisplayRequest * request = [[AdViewAdDisplayRequest alloc] init];
    if (request)
    {
        request.httpRequest = [adapter getAdReportRequest:NO AdContent:theAdContent];
		if (nil == request.httpRequest) return nil;
    }
    return request;
}

-(void) dealloc
{
    AdViewLogDebug(@"Dealloc AdViewAdDisplayRequest");
}
@end

@implementation AdViewAdDisplayResponse
@end

@implementation AdViewAdClickRequest
+ (AdViewAdClickRequest*)requestWithAdContent:(AdViewContent*)theAdContent  Adapter:(AdViewAdapter*)adapter
{
    AdViewAdClickRequest* request = [[AdViewAdClickRequest alloc] init];
    if (request) {        
        request.httpRequest = [adapter getAdReportRequest:YES AdContent:theAdContent];
		if (nil == request.httpRequest) return nil;
    }
    return request;
}

- (void)dealloc
{
    AdViewLogDebug(@"Dealloc AdViewAdClickRequest");
}
@end

@implementation AdViewAdClickResponse
@end

@interface AdViewConnection(PRIVATE)

- (BOOL)handleFinishGet;
- (BOOL)handleExternalImage;

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error;
- (void)connectionDidFinishLoading:(NSURLConnection*)connection;

-(void) handleParseEnd:(BOOL)bParseOK;

@end

@implementation AdViewConnection
@synthesize adapter = _adapter;

- (void)notifyTooQuickRequestError
{
    NSString *lastConResponseKey = [NSString stringWithFormat:LAST_CONRESPONSE_FMT, self.adapter.adPlatType, self.adapter.adType];
    
    NSString *lastAdResponseKey = [NSString stringWithFormat:LAST_ADRESPONSE_FMT, self.adapter.adPlatType, self.adapter.adType];
    
    self.conResponse = (NSURLResponse *)[[AdViewExtTool sharedTool] objectStoredForKey:lastConResponseKey];
    
    AdViewAdapterResponse *adResponse = (AdViewAdapterResponse *)[[AdViewExtTool sharedTool] objectStoredForKey:lastAdResponseKey];
    
	if (self.conResponse && adResponse)
    {
        self.httpHeader = adResponse.headers.mutableCopy;
        self.httpData = adResponse.body.mutableCopy;
        
        [self handleFinishGet];
		
		AdViewLogDebug(@"will reuse adcontent.");
	}
    else
    {
		NSError *error = [NSError errorWithDomain:@"too quick request." code:-1 userInfo:nil];
		[self connection: nil didFailWithError: error];
	}
}

- (void)startConnection:(NSMutableURLRequest *)request
{	
	@synchronized(self)
    {
		if (nil == self.connections)
        {
			self.connections = [[NSMutableArray alloc] initWithCapacity:4];
        }
	}
	
	@synchronized(self.connections)
    {
		self.conRequest = request;
		NSURLConnection * con = [[NSURLConnection alloc] initWithRequest:request delegate:self];
		[self.connections addObject:con];
		[con start];
        AdViewLogDebug(@"%s - %@", __FUNCTION__, request.URL);
	}
}

- (void)removeConnection:(NSURLConnection*)connection {
	@synchronized(self.connections) {
		[connection cancel];
		[self.connections removeObject:connection];
	}
}

- (void)cancelConnections
{
	@synchronized(self.connections) {
		AdViewLogDebug(@"will cancel %d connections", [self.connections count]);
        [self clearRetryTimer];
		for (int i = 0; i < [self.connections count]; i++) 
		{
			[[self.connections objectAtIndex:i] cancel];
		}
		[self.connections removeAllObjects];
	}
}

//对外开始请求接口
- (void)startConnection
{
    [self startConnection:self.adRequest.httpRequest];
}

- (void)cancel
{
	self.delegate = nil;
	[self cancelConnections];
}

- (AdViewConnection*)initWithGetRequest:(AdViewAdGetRequest*)request
                                adapter:(AdViewAdapter*)adapter
                               delegate:theDelegate
{
    if (self = [super init])
    {
        _connectionType = AdViewConnectionTypeGetRequest;
        _connectionState = AdViewConnectionStateRequestGet;

        self.adRequest = request;
        self.delegate = theDelegate;
		self.adapter = adapter;
        self.adContent = [[AdViewContent alloc] initWithAppId:request.adAppId];
        self.contentArr = [[NSMutableArray alloc] init];
		_adContent.adPlatType = adapter.adPlatType;
        
        [_contentArr addObject:_adContent];
        
        BOOL needCache = NO;
        if (self.delegate && [self.delegate respondsToSelector:@selector(isNeedCache)])
        {
            needCache = [self.delegate isNeedCache];
        }
        //判断上一次请求广告是否成功
        BOOL adStatus = [(NSNumber*)[[AdViewExtTool sharedTool] objectStoredForKey:@"lastRequestAdStatus"] boolValue];
        
        //使用缓存 且未达到请求间隔要求 且上次请求成功
		if (needCache && requestLimited(self.adapter.adPlatType,self.adapter.adType) && adStatus)   //post error.
        {
			[NSTimer scheduledTimerWithTimeInterval:0.5f
											 target:self 
										   selector:@selector(notifyTooQuickRequestError)
										   userInfo:nil
											repeats:NO];
		}
        else
        {
            //request的缓存类型
			[request.httpRequest setCachePolicy:NSURLRequestReloadIgnoringCacheData];
            
            if (self.adapter.adType != AdViewSpread || self.adapter.adType != AdViewNative)
            {
                //保存一下本次请求的时间 用于判断是否请求过快
                setRequestTime(self.adapter.adPlatType,self.adapter.adType);
            }
		}
    }
    return self;
}

- (AdViewConnection *)initWithDisplayRequest:(AdViewAdDisplayRequest*)request delegate:theDelegate
{
    if (self = [super init]) {
        _connectionType = AdViewConnectionTypeDisplayRequest;
        _connectionState = AdViewConnectionStateRequestDisplay;

        self.adRequest = request;
        self.delegate = theDelegate;
		self.adapter = [theDelegate performSelector:@selector(adapter)];
		[request.httpRequest setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    }
    return self;
}

- (AdViewConnection *)initWithClickRequest:(AdViewAdClickRequest *)request delegate:theDelegate
{
    if (self = [super init])
    {
        _connectionType = AdViewConnectionTypeClickRequest;
        _connectionState = AdViewConnectionStateRequestClick;

        self.adRequest = request;
        self.delegate = theDelegate;
		self.adapter = [theDelegate performSelector:@selector(adapter)];
		[request.httpRequest setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    }
    return self;
}

#pragma NSURLConnection delegate
- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*) response
{
    //重制httpData
    self.httpData = [NSMutableData new];
	self.httpHeader = nil;
    
	NSMutableDictionary *dic_tmp = [[NSMutableDictionary alloc] initWithCapacity:10];
	self.httpHeader = dic_tmp;
	
	//copy http data to httpHeader to use.
	if ([response isKindOfClass:[NSHTTPURLResponse class]])
    {
		NSHTTPURLResponse * httpResp = (NSHTTPURLResponse*)response;
		NSDictionary * orgDict = [httpResp allHeaderFields];
		
		AdViewLogDebug(@"URL:%@, ret:%d", [[httpResp URL] absoluteString], [httpResp statusCode]);
		
		for (int i = 0; i < [[orgDict allKeys] count]; i++)
		{
			NSString *key0 = [[orgDict allKeys] objectAtIndex:i];
			NSString *val0 = [orgDict objectForKey:key0];
			
			[self.httpHeader setObject:val0 forKey:[key0 lowercaseString]];
		}		
	}
	self.conResponse = response;
    
	for (int i = 0; i < [[self.httpHeader allKeys] count]; i++)
	{
		NSString *key0 = [[self.httpHeader allKeys] objectAtIndex:i];
		NSString *val0 = [self.httpHeader objectForKey:key0];
        
        AdViewLogDebug(@"header %d:--key:%@--val:%@--%@--", i, key0, val0, NSStringFromClass([val0 class]));
    }
    
    if ([self.delegate respondsToSelector:@selector(adConnection:didReceiveResponse:)]) {
        [self.delegate adConnection:self didReceiveResponse:response];
    }
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
#if 1
	return nil;		//won't use the default cache.
#else
	NSHTTPURLResponse *httpResp = (NSHTTPURLResponse*)[cachedResponse response];
	NSDictionary *orgDict = [httpResp allHeaderFields];
	
	AdViewLogDebug(@"URL:%@", [[httpResp URL] absoluteString]);
	
	for (int i = 0; i < [[orgDict allKeys] count]; i++)
	{
		NSString *key0 = [[orgDict allKeys] objectAtIndex:i];
		NSString *val0 = [orgDict objectForKey:key0];
		
		AdViewLogDebug(@"header %d:--key:%@--val:%@--%@--", i, key0, val0, NSStringFromClass([val0 class]));
	}	
	return	(cachedResponse);
#endif
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	NSUInteger conLength = [self.httpData length] + [data length];
	if (conLength > OPENAPI_ADDATA_LIMIT) //too larget content, think to fail.
	{
		[connection cancel];
		AdViewLogInfo(@"content too large to be:%d", conLength);
		
		NSError *error = [NSError errorWithDomain:@"content too large" code:-1 userInfo:nil];
		[self connection:connection didFailWithError:error];
	}
	
    [self.httpData appendData:data];
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
    AdViewLogDebug(@"connection didFailWithError: %@", error);
    if (self.connectionType == AdViewConnectionTypeGetRequest)
    {
        if (self.delegate && [self.delegate respondsToSelector:@selector(adConnection:didFailWithError:)])
        {
            [self.delegate adConnection:self didFailWithError:error];
        }
    } else {
        [self removeConnection:connection];
        [self handleFailDisplayOrClick];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    AdViewLogDebug(@"%s - %@",__FUNCTION__,connection.currentRequest.URL);
	[self removeConnection:connection];
	
    switch (_connectionState)
    {
        case AdViewConnectionStateRequestGet:
			[self handleFinishGet];
            break;
        case AdViewConnectionStateRequestImage:
		{
            AdViewLogDebug(@"%s,Get Image End!",__FUNCTION__);
			if (![self handleExternalImage]) break;
			
            AdImageItem *imgItem = nil;
            if (nLoadImage >= 0) {
                imgItem = [_adContent getAdImageItem:nLoadImage];
                imgItem.imgData = self.httpData;
            }
            
            if (LOADING_IMG_ADICON == nLoadImage) {
                _adContent.adIconImg = [UIImage imageWithData:self.httpData];
                _adContent.adIconUrlStr = nil;
                
            } else if (LOADING_IMG_ADLOGO == nLoadImage) {
                _adContent.adLogoImg = [UIImage imageWithData:self.httpData];
                _adContent.adLogoURLStr = nil;
                
            } else if (LOADING_IMG_BG == nLoadImage) {
                _adContent.adBgImg = [UIImage imageWithData:self.httpData];
                _adContent.adBgImgURL = nil;

            } else if (LOADING_IMG_ACT == nLoadImage) {
                if (self.httpData == nil) {
                    _adContent.adActImgURL = nil;
                    break;
                }
                
                _adContent.adActImg = [UIImage imageWithData:self.httpData];
                if (nil == _adContent.adActImg || [_adContent.adActImg size].width < 1)
                {
                    AdViewLogDebug(@"ActionImage empty");
                    if (tryUseCache)
                    {
                        _adContent.adActImg = nil;
                        
                        if (self.delegate && [self.delegate respondsToSelector:@selector(adConnection:didFailWithError:)])
                        {
                            NSError *error = [NSError errorWithDomain:@"Image format is not supported" code:-1 userInfo:nil];
                            [self.delegate adConnection: self didFailWithError:error];
                        }
                        return;
                    }
                }
            }
            else
            {
                if ([self.httpData length] <= 0)
                {
                    [_adContent.adImageItems removeObjectAtIndex:nLoadImage];
                    if ((_adContent.adShowType == AdViewAdSHowType_FullImage || (_adContent.adShowType == AdViewAdSHowType_FullGif)) && ![_adContent.adImageItems count])
                    {
                        if (self.delegate && [self.delegate respondsToSelector:@selector(adConnection:didFailWithError:)])
                        {
                            [self.delegate adConnection: self didFailWithError:nil];
                        }
                        break;
                    }
                }
                else
                {
                    imgItem.img = [UIImage imageWithData:self.httpData];
                    if (nil == imgItem.img || [imgItem.img size].width < 1)
                    {
                        AdViewLogDebug(@"Image empty");
                        if (tryUseCache)    //为什么使用的cache就报错??
                        {
                            imgItem.img = nil;
                            if (self.delegate && [self.delegate respondsToSelector:@selector(adConnection:didFailWithError:)])
                            {
                                NSError *error = [NSError errorWithDomain:@"Image format is not supported" code:-1 userInfo:nil];
                                [self.delegate adConnection: self didFailWithError:error];
                            }
                            return;
                        }
                    }
                }
            }
            
            //循环的下载图片,如果没有可以继续下载的,则进行下面的回调
            if (![self fetchExternalImage:YES])
            {
                if (self.delegate && [self.delegate respondsToSelector:@selector(adConnection:didReceiveAdContent:)])
                {
                    [self.delegate adConnection:self didReceiveAdContent:_contentArr];
                }
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(adConnectionDidFinishLoading:)])
                {
                    [self.delegate adConnectionDidFinishLoading:self];
                }
            }
		}
            break;
        case AdViewConnectionStateRequestDisplay:
        case AdViewConnectionStateRequestClick:
        {
			if (_connectionState == AdViewConnectionStateRequestDisplay)
				AdViewLogInfo (@"Request to Display end");
			else if (_connectionState == AdViewConnectionStateRequestClick)
				AdViewLogInfo (@"Request to Click end");
			
			if (![self.adapter useInternalParser])
            {
				NSString *errInfo = @"err";
				AdViewAdapterResponse *adResp = [[AdViewAdapterResponse alloc] init];
				adResp.type = _connectionState;
				adResp.headers = self.httpHeader;
				adResp.body = self.httpData;
				adResp.status = (int)[(NSHTTPURLResponse*)self.conResponse statusCode];
                
                //解析返回数据到<AdContent *>contentArray
				BOOL bRet = [self.adapter parseResponse:adResp contentArr:_contentArr ErrorInfo:&errInfo];
                if (!bRet) //don't accept display or click.
                {
                    [self handleFailDisplayOrClick];
					break;
				}
			}
			
            if (self.delegate && [self.delegate respondsToSelector:@selector(adConnectionDidFinishLoading:)])
            {
                [self.delegate adConnectionDidFinishLoading:self];
            }
        }
            break;
        default:
            break;
    }
}

- (void)handleFailDisplayOrClick
{
    AdViewLogInfo (@"Request display/click failed！");
    
    if (++failDisplayReqTimes >= Request_TIME_LIMIT) {
        NSString *errInfo = @"don't accept display/click request.";
        NSError *error = [NSError errorWithDomain:errInfo code:-1 userInfo:nil];
        if (_connectionState == AdViewConnectionStateRequestDisplay) {
            if ([self.delegate respondsToSelector:@selector(adConnection:didFailWithError:)]) {
                [self.delegate adConnection:self didFailWithError:error];
            }
        }
    } else {
        [self clearRetryTimer];
        self.retryConTimer = [NSTimer scheduledWeakTimerWithTimeInterval:30
                                                                  target:self
                                                                selector:@selector(startRetryConnection:)
                                                                userInfo:self.adRequest.httpRequest
                                                                 repeats:NO];
    }
}

- (void)startRetryConnection:(NSTimer *)timer
{
    NSMutableURLRequest *req = [timer userInfo];
    self.retryConTimer = nil;
    [self startConnection:req];
}

- (void)clearRetryTimer
{
    if (_retryConTimer != nil)
    {
        [_retryConTimer invalidate];
        _retryConTimer = nil;
    }
}

- (void)parseAdBody
{
    NSString* adBody = [[NSString alloc] initWithData:self.httpData encoding:NSUTF8StringEncoding];
    
    NSData* adData = [[adBody stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
                      dataUsingEncoding:NSUTF8StringEncoding];
    
    NSXMLParser* parser = [[NSXMLParser alloc] initWithData: adData];
    self.adXMLParser = parser;
    parser.delegate = self;
    
    [self.adXMLParser parse];
}


- (void)parserDidStartDocument: (NSXMLParser*) parser
{
    AdViewLogInfo(@"Start parse ad body");
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString*)qualifiedName attributes:(NSDictionary *)attributes
{
    AdViewLogDebug(@"didStartElement");
    self.currentElementName = elementName;
	[self.adapter parseXMLStartElement:elementName
							attributes:attributes
							 adContent:_adContent];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName
{
    AdViewLogDebug(@"didEndElement");
    self.currentElementName = nil;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    AdViewLogDebug(@"foundCharacters");
	[self.adapter parseXMLFoundCharacters:string
								inElement:self.currentElementName
								adContent:_adContent];
}

//解析完毕
- (void)handleParseEnd:(BOOL)bParseOK
{
    AdViewLogDebug(@"%s",__FUNCTION__);
    /*
     * Don't show the ad!!!! ⚠️ 这是干啥的??
     */
    if ([_adContent.adId isEqualToString:@"12345678"]) {
#if 0		//laizhiwen 20120427, should display the sample ad. and the didFailWithError will cause the retain count error.
        NSError* error = [[NSError alloc] initWithDomain:@"Don't display" code:-65536 userInfo:nil];
        if (self.delegate && [self.delegate respondsToSelector:@selector(adConnection:didFailWithError:)]) {
            [self.delegate adConnection:self didFailWithError:error];
        }
#endif
    }
	
	if (AdViewContentErrorType_None != _adContent.adParseError)
		bParseOK = NO;
    
	if (bParseOK)
    {
		if ([_adContent needFetchImage])
        {
			//如果解析完毕且需要下载图片
			_connectionState = AdViewConnectionStateRequestImage;
			[self fetchExternalImage:YES];
		}
        else
        {
			/*
			 * Success!!!!
			 */
			_connectionState = AdViewConnectionStateRequestDisplay;
			if (self.delegate && [self.delegate respondsToSelector:@selector(adConnection:didReceiveAdContent:)])
            {
				[self.delegate adConnection:self didReceiveAdContent:_contentArr];
			}
			if (self.delegate && [self.delegate respondsToSelector:@selector(adConnectionDidFinishLoading:)])
            {
				[self.delegate adConnectionDidFinishLoading:self];
			}		
		}
	}
	else
    {
		NSString *errStr = nil;
		switch (self.adContent.adParseError)
        {
			case AdViewContentErrorType_NoFill:
				errStr = @"Ad no fill!";
				break;
			default:
				errStr = @"Content error!";
		}
		NSError *error = [NSError errorWithDomain:errStr code:-1 userInfo:nil];
		[self.delegate adConnection:self didFailWithError:error];
	}
}

- (void)parserDidEndDocument:(NSXMLParser*)parser
{
	[self handleParseEnd:YES];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
	AdViewLogInfo(@"Parser Error");
	
	[self handleParseEnd:NO];
}

//获取图片 是否复用
- (BOOL)fetchExternalImage:(BOOL)bReuse
{
    AdViewLogDebug(@"%s, reuse:%d", __FUNCTION__, bReuse);
    NSURL* url = nil;
    
    if (nil == _adContent.adIconImg && [_adContent.adIconUrlStr length] > 0)
    {
        url = [NSURL URLWithString:_adContent.adIconUrlStr];
        nLoadImage = LOADING_IMG_ADICON;
    }
    else if (nil == _adContent.adLogoImg && [_adContent.adLogoURLStr length] > 0)
    {
        url = [NSURL URLWithString:_adContent.adLogoURLStr];
        nLoadImage = LOADING_IMG_ADLOGO;
    }
    else if (nil == _adContent.adBgImg && [_adContent.adBgImgURL length] > 0)
    {
        url = [NSURL URLWithString:_adContent.adBgImgURL];
        nLoadImage = LOADING_IMG_BG;
    }
    else if (nil == _adContent.adActImg && [_adContent.adActImgURL length] > 0)
    {
        url = [NSURL URLWithString:_adContent.adActImgURL];
        nLoadImage = LOADING_IMG_ACT;
    }
    else
    {
        int nCount = (int)[_adContent.adImageItems count];
        for (int i = 0; i < nCount; i++)
        {
            AdImageItem *imgItem = [_adContent getAdImageItem:i];
            if (nil == imgItem.img && [imgItem.imgUrl length] > 0)
            {
                url = [NSURL URLWithString:imgItem.imgUrl];
                nLoadImage = i;
                break;
            }
        }
        if (nil == url)
            return NO;
    }
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:url 
													   cachePolicy:NSURLRequestReturnCacheDataElseLoad
												   timeoutInterval:60];
	tryUseCache = NO;
	if (bReuse)
    {
#if 0
        if ([[url absoluteString] rangeOfString:@"21161820_TIGP"].location != NSNotFound)
        {
            AdViewLogDebug(@"to fetch?");
        }
#endif
        //缓存 已经在这里初始化完毕
		AdViewURLCache *cache = [AdViewExtTool sharedTool].urlCache;
		NSCachedURLResponse *cacheResp = [cache cachedResponseForRequest:req];  //取得请求的缓存
		if (nil != cacheResp)
		{
			self.conMethod = [req HTTPMethod];
			NSHTTPURLResponse * httpResp = (NSHTTPURLResponse*)[cacheResp response];
			NSDictionary * cachedHeaderDict = [httpResp allHeaderFields];
            
            int realLen = (int)[[cacheResp data] length];
            int headLen = [[cachedHeaderDict objectForKey:@"Content-Length"] intValue];
            AdViewLogDebug(@"cache real and head len:%d, %d", realLen, headLen);
			
			NSString *strLastMod = [cachedHeaderDict objectForKey:@"Last-Modified"];
            if (realLen < 1 || realLen != headLen)  //如果缓存不存在 || 缓存的请求体大小不等于Content-Length标记的大小 头部不添加东西
            {
                AdViewLogDebug(@"refetch image");
            }
			else if (nil != strLastMod) //如果缓存存在 && 与Content-Length一致 && Last-Modified字段不为空.则发送本地缓存图片修改时间
            {
				[req setValue:strLastMod forHTTPHeaderField:@"If-Modified-Since"];
                tryUseCache = YES;
			}
            else
            {
				[req setHTTPMethod:@"HEAD"];		//for server not support "If-Modified-Since", should use "HEAD"
            }
		}
	}
    [self startConnection:req];
    return YES;
}

- (NSTimeInterval)differInHeaderDate:(NSString*)fieldTag
                               cache:(NSDictionary*)cachedDict exist:(BOOL*)out_exist
{
	NSTimeInterval diff = 0;
	if (nil != out_exist) *out_exist = NO;
	
	NSString *strDate1 = [self.httpHeader objectForKey:[fieldTag lowercaseString]];
	NSString *strDate2 = [cachedDict objectForKey:fieldTag];
	
	AdViewLogInfo(@"%@ of HEAD:%@, Cache:%@", fieldTag, strDate1, strDate2);
	
	if (nil != strDate1 && nil != strDate2)
	{
		if (nil != out_exist) *out_exist = YES;
		
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss zzz"];
		NSDate *toDate1 = [dateFormatter dateFromString:strDate1];
		NSDate *toDate2 = [dateFormatter dateFromString:strDate2];
		
		diff = [toDate1 timeIntervalSince1970] - [toDate2 timeIntervalSince1970];
	}
	
	return diff;
}

//检查返回图片数据
- (BOOL)handleExternalImage
{
	int statusCode = (int)[(NSHTTPURLResponse*)self.conResponse statusCode];
	NSURLCache *cache = [AdViewExtTool sharedTool].urlCache;
	NSCachedURLResponse *cacheResp = nil;
	
	if (statusCode / 100 >= 4) {
		AdViewLogInfo(@"image return error of code:%d", statusCode);
		[self.httpData setLength:0];
	}
	else if (304 == statusCode) {
		[self.conRequest setHTTPMethod:self.conMethod];
        [self.conRequest setValue:nil forHTTPHeaderField:@"If-Modified-Since"];
		cacheResp = [cache cachedResponseForRequest:self.conRequest];
		
		AdViewLogInfo(@"reuse image data by 304.");
        
        if (nil == cacheResp) {
            AdViewLogInfo(@"reuse failed, refetch.");
            [self fetchExternalImage:NO];
			return NO;
        } else {
            self.httpData = [NSMutableData dataWithData:[cacheResp data]];
        }
        
        
#if 0   //test
        if ([adContent.adImageURL rangeOfString:@"21161820_TIGP"].location != NSNotFound)
        {
            int nHttpLen = [self.httpData length];
            int nCachLen = [[cacheResp data] length];
            
            AdViewLogDebug(@"cache len:%d,%d", nHttpLen, nCachLen);
        }
#endif
	}
	else if ([[self.conRequest HTTPMethod] isEqualToString:@"HEAD"]) {//check reuse.
		[self.conRequest setHTTPMethod:self.conMethod];
		cacheResp = [cache cachedResponseForRequest:self.conRequest];
		//compare length and last-modified.
		
		int nLength1 = [[self.httpHeader objectForKey:@"content-length"] intValue];
		NSHTTPURLResponse *httpResp = (NSHTTPURLResponse*)[cacheResp response];
		NSDictionary *cachedDict = [httpResp allHeaderFields];
		int nLength2 = [[cachedDict objectForKey:@"Content-Length"] intValue];
		int nLength3 = (int)[[cacheResp data] length];
		AdViewLogInfo(@"length of HEAD:%d, Cache:%d, Data:%d", nLength1, nLength2,
						  nLength3);
		
		BOOL	bLastUpdated = NO, bHasLast = NO;		
		NSTimeInterval diffLastUpdate = [self differInHeaderDate:@"Last-Modified" 
														   cache:cachedDict exist:&bHasLast];
		bLastUpdated = (diffLastUpdate > 0);
		
		BOOL bReuse = NO;
		if (bHasLast) {
			bReuse = !bLastUpdated;
		} else {
			bReuse = (nLength1 == nLength2 || (0 == nLength1 && nLength2 > 0));
			
			if (0 == nLength1 && nLength3 > 0)	//check date value.
			{
				NSTimeInterval diffDate = [self differInHeaderDate:@"Date"
															 cache:cachedDict exist:nil];
				bReuse = (diffDate < 3600*2);		//2 hours.
			}
		}
		
		if (bReuse) {//ok, use cache
			AdViewLogInfo(@"reuse image data.");
			self.httpData = [NSMutableData dataWithData:[cacheResp data]];
		} else {
			[self fetchExternalImage:NO];
			return NO;
		}
	} else {
		//get data, store to cache.
        [self.conRequest setValue:nil forHTTPHeaderField:@"If-Modified-Since"];
		cacheResp = [[NSCachedURLResponse alloc] initWithResponse:self.conResponse
															 data:self.httpData
                                                         userInfo:nil
                                                    storagePolicy:NSURLCacheStorageAllowedInMemoryOnly];
		[cache storeCachedResponse:cacheResp
						forRequest:self.conRequest];
#if 0//for test.
		{
			//to test.
			for (int i = 0; i < 200; i++) {
				NSCachedURLResponse *cacheResp1 = [[NSCachedURLResponse alloc] initWithResponse:self.conResponse
																						   data:self.httpData];
				NSString *urlStr1 = [NSString stringWithFormat:@"https://www.adview.cn/req%04d", i];
				[self.conRequest setURL:[NSURL URLWithString:urlStr1]];
				[cache storeCachedResponse:cacheResp1 forRequest:self.conRequest];
				[cacheResp1 release];
				int dataLen = [self.httpData length];
				[self.httpData setLength:dataLen - 1];
			}
		}
#endif			
	}
	return YES;
}

//处理取广告。
- (BOOL)handleFinishGet
{
	int statusCode = (int)[(NSHTTPURLResponse *)self.conResponse statusCode];
    AdViewLogDebug(@"%s,ret:%d", __FUNCTION__, statusCode);
    
    NSError * error = [NSError errorWithDomain:@"Get ad error!" code:-1 userInfo:nil];
	NSString *errInfo = @"Get ad error!";
	BOOL bError = NO;
	if (statusCode != HTTPStatusSuccess) {
		bError = YES;
        error = [self.adapter parseStatus:statusCode error:error];
	}
	
	if (!bError) {
        _connectionState = AdViewConnectionStateParseContent;
		_adContent.adCopyrightStr = [self.adapter copyRightString];
		
		if ([self.adapter useInternalParser])
        {
			[self parseAdBody];
        }
		else
        {
			AdViewAdapterResponse *adResp = [[AdViewAdapterResponse alloc] init];
			adResp.type = AdViewConnectionStateRequestGet;
			adResp.headers = self.httpHeader;
			adResp.body = self.httpData;
			adResp.status = statusCode;
            
            //仅在内存中保存一下 后面筛选的时候用
            storeResponse(self.adapter.adPlatType, self.adapter.adType, self.conResponse, adResp);
            
            //让各个平台去解析,保存到contentArr中 目前只剩AdFill
            BOOL bRet = [self.adapter parseResponse:adResp contentArr:_contentArr ErrorInfo:&errInfo];
            
            //解析成功
			if (bRet)
            {
                if (self.adapter.adType == AdViewNative)    //如果是原生广告直接把contentArr数据返回
                {
                    _connectionState = AdViewConnectionStateRequestDisplay;
                    if (self.delegate && [self.delegate respondsToSelector:@selector(adConnection:didReceiveAdContent:)])
                    {
                        [self.delegate adConnection:self didReceiveAdContent:_contentArr];
                    }
                    if (self.delegate && [self.delegate respondsToSelector:@selector(adConnectionDidFinishLoading:)])
                    {
                        [self.delegate adConnectionDidFinishLoading:self];
                    }
                }
                else    //非原生广告
                {
                    [self handleParseEnd:YES];
                }
			}
            else
            {
				bError = YES;
			}
		}
	}
	if (bError)
    {
		if (self.delegate && [self.delegate respondsToSelector:@selector(adConnection:didFailWithError:)])
        {
			[self.delegate adConnection:self didFailWithError:error];
		}					
	}
	return YES;
}

- (void)dealloc
{    
    AdViewLogDebug(@"Dealloc AdViewConnection with type: %d", _connectionType);
    
    _connectionState = AdViewConnectionStateNone;

    self.delegate = nil;
	self.adapter = nil;
	
	[self cancelConnections];
	self.connections = nil;
	
    [self.contentArr removeAllObjects];
    self.contentArr = nil;
    
	self.httpHeader = nil;
    
    self.conMethod = nil;
    self.conResponse = nil;
    self.conRequest = nil;
    
    self.currentElementName = nil;
    
    self.httpData = nil;
    self.adXMLParser = nil;
}
@end

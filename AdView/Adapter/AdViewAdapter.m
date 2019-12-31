//
//  AdViewAdapter.m
//  AdViewSDK
//
//  Created by AdView on 12-8-30.
//  Copyright 2012 AdView. All rights reserved.
//

#import "AdViewAdapter.h"
#import "AdViewExtTool.h"
#import "AdViewContent.h"

#define REPORT_ERROR_URL     @"https://bid.adview.com/agent/reportError.php"
#define REPORT_ERROR_TESTURL @"http://test2014.adview.com:8088/agent/reportError.php"

#define ADVIEW_AD_FMT_AGENT @"https://%s/nusoap/nusoap_agent1.php"
#define ADVIEW_AD_FMT_REPLY @"https://%s/nusoap/nusoap_agent2.php"

#define ADVIEW_AD_FMT_TEST  @"https://%s/nusoap/nusoap_agent1_test.php"

static char gAdHost[128] = "report.adview.com";

void setAdViewViewHost(const char *host) {
	if (NULL == host
		|| strlen(host) < 1
		|| strlen(host) >= 128) 
		return;
	strcpy(gAdHost, host);
}

static NSString *getAdAgentUrl(BOOL testMode)
{
	if (testMode)
    {
		return [NSString stringWithFormat:ADVIEW_AD_FMT_TEST, gAdHost];
	}
	return [NSString stringWithFormat:ADVIEW_AD_FMT_AGENT, gAdHost];
}

static NSString *getAdReplyUrl() {
	return [NSString stringWithFormat:ADVIEW_AD_FMT_REPLY, gAdHost];
}

@implementation AdViewAdapterResponse

@synthesize headers;
@synthesize body;

- (void)dealloc {
    self.headers = nil;
    self.body = nil;
}

@end


@implementation AdViewAdapter

@synthesize adTestMode = _adTestMode;
@synthesize adPlatType = _adPlatType;
@synthesize configVer;
@synthesize adType;
@synthesize bIgnoreShowRequest;
@synthesize bIgnoreClickRequest;
@synthesize showUrlStr;
@synthesize clickUrlStr;
@synthesize otherPaltArray;

+ (void)linkMutableString:(NSMutableString*)str
                     Dict:(NSMutableDictionary*)infoDict
{
    for (NSString *aKey in infoDict.allKeys) {
        NSString *val0 = [infoDict objectForKey:aKey];
        if (nil == val0) val0 = @"";
        if (str.length > 0) [str appendString:@"&"];
        [str appendFormat:@"%@=%@", aKey, val0];
    }
}

- (NSMutableURLRequest*)getAdReportRequest:(BOOL)bClickOtherDisplay AdContent:(AdViewContent*)theAdContent;
{
	int nDisplay = bClickOtherDisplay?0:1;
	int nClick = bClickOtherDisplay?1:0;
	
	NSURL* url = [NSURL URLWithString: getAdReplyUrl()];
	NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:url];
	
    NSString *keyDev = [[AdViewExtTool sharedTool] getMacAddress:MacAddrFmtType_Default];
    //if ios >= 7.0, get the idfa as udid
    NSString *sysVersion = [[UIDevice currentDevice] systemVersion];	//@"4.2"
    float sysVer = [sysVersion floatValue];
    if (sysVer >= 7.0f) {
        keyDev = [AdViewExtTool getIDA];
    }
    int seviceId = (self.adPlatType == AdViewAdPlatTypeAdDirect)?995:996;
    NSString *token = [AdViewExtTool getMd5HexString:[NSString stringWithFormat:@"%@%@%@",theAdContent.adAppId,theAdContent.adId,keyDev]];
    
	NSString* reqBody = [[NSString alloc] initWithFormat: @"name=<?xml version='1.0' standalone='yes' ?>"
						 "<application> <keyDev>%@</keyDev><idApp>%@</idApp><idAd>%@</idAd>"
						 "<time>2010091184656</time><system>1</system>"
						 "<reportType>%d</reportType><serviceId>%d</serviceId><display>%d</display><adType>%zd</adType>"
						 "<click>%d</click><token>%@</token></application>", keyDev,
						 theAdContent.adAppId, theAdContent.adId, nClick, seviceId, nDisplay,self.adType, nClick,token];
    AdViewLogDebug(@"RptRequest: \"%@\"", [url absoluteString]);
	AdViewLogDebug(@"RptRequest: \"%@\"", reqBody);
	NSData* postData = [reqBody dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion: YES];
	NSString* postLen = [NSString stringWithFormat:@"%ld", (long)[postData length]];
	req.HTTPMethod = @"POST";
	req.HTTPBody = postData;
	[req setValue: postLen forHTTPHeaderField: @"Content-Length"];
	[req setValue: @"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
	
	return req;
}

/**
 * 生成错误汇报信息
 */
- (NSMutableURLRequest*)makeAdErrorReport:(ErrReportType)errType AdContent:(AdViewContent*)theAdContent Arg:(NSString*)arg {
    if (nil == theAdContent) {
        return nil;
    }
    
    NSURL* url = [NSURL URLWithString: self.adTestMode ? REPORT_ERROR_TESTURL : REPORT_ERROR_URL];
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:url];
    
    NSMutableDictionary *bodyDict = [[NSMutableDictionary alloc] initWithCapacity:5];
    [bodyDict setObject: [NSNumber numberWithInt:errType] forKey:@"et"];
    [bodyDict setObject: (arg ? arg : @"") forKey:@"arg"];
    
    NSString *adb = theAdContent.adBody ? theAdContent.adBody : @"";
    if (adb.length <= 0) {
        return nil;
    }
    [bodyDict setObject:adb forKey:@"adb"];
    
    //如果eqs为空，补一些基本字段。
    if ([theAdContent.errorReportQuery length] < 1) {
        NSString *keyDev = [[AdViewExtTool sharedTool] getMacAddress:MacAddrFmtType_Default];
        //if ios >= 7.0, get the idfa as udid
        NSString *sysVersion = [[UIDevice currentDevice] systemVersion];	//@"4.2"
        float sysVer = [sysVersion floatValue];
        if (sysVer >= 7.0f) {
            keyDev = [AdViewExtTool getIDA];
        }
        //ios10限制广告追踪
        if ([keyDev isEqual:@"00000000-0000-0000-0000-000000000000"]) {
            keyDev = [[UIDevice currentDevice] getAdViewIDFA];
        }
        [bodyDict setObject:keyDev forKey:@"uuid"];
        [bodyDict setObject:(theAdContent.adAppId ? theAdContent.adAppId : @"") forKey:@"aid"];
        [bodyDict setObject:(theAdContent.adId ? theAdContent.adId : @"") forKey:@"adi"];
        [bodyDict setObject:(theAdContent.adInfo ? theAdContent.adInfo : @"") forKey:@"ai"];
    }
    [bodyDict setObject: (theAdContent.errorReportQuery ? theAdContent.errorReportQuery : @"") forKey:@"eqs"];
    
    //生成JSON
    NSError *error = nil;
    
    NSData *postData = [NSJSONSerialization dataWithJSONObject:bodyDict options:NSJSONWritingPrettyPrinted error:&error];

    if (nil != error) {
        AdViewLogInfo(@"makeAdErrorReport failed.");
        return nil;
    }

    NSData* zipData = [AdViewExtTool gzipData:postData];
    if (nil != zipData) {
        postData = zipData;
        [req setValue: @"gzip" forHTTPHeaderField: @"Content-Encoding"];
    }
    
    NSString* postLen = [NSString stringWithFormat:@"%ld", (long)[postData length]];
    req.HTTPMethod = @"POST";
    req.HTTPBody = postData;
    [req setValue: postLen forHTTPHeaderField: @"Content-Length"];
    [req setValue: @"application/json" forHTTPHeaderField: @"Content-Type"];
    
    return req;
}

//set request body
- (NSString*)getRequestBody:(AdViewAdCondition*)condition
{
    self.adType = condition.adverType;
    
    int density = [AdViewExtTool getDensity];
    int width = (int)condition.adSize.width;
    int height = (int)condition.adSize.height;
    
    if (condition.adverType == AdViewBanner)
    {
        width = (int)condition.adSize.width * density;
        height = (int)condition.adSize.height * density;
    }
    
    if (condition.adverType == AdViewInterstitial)
    {
        width = 300 * density;
        height = 300 * density;
        if ([AdViewExtTool getDeviceIsIpad])
        {
            width = 600 * density;
            height = 600 * density;
        }
    }
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    BOOL  bIsLand = [AdViewExtTool getDeviceDirection];
    CGFloat screenWidth =  bIsLand?screenSize.height:screenSize.width;
    CGFloat screenHeight =  bIsLand?screenSize.width:screenSize.height;
    if (bIsLand && screenWidth < screenHeight)
    {
        screenWidth += screenHeight;
        screenHeight = screenWidth - screenHeight;
        screenWidth = screenWidth - screenHeight;
    }
    NSString *adDeviceSize = [NSString stringWithFormat:@"%dX%d",(int)screenWidth,(int)screenHeight];
    NSString *adSize = [NSString stringWithFormat:@"%dX%d",width,height];
    int seviceId = (self.adPlatType == AdViewAdPlatTypeAdDirect)?995:996;
    NSString *token = [AdViewExtTool getMd5HexString:[NSString stringWithFormat:@"%@%d%@",condition.appId,seviceId,adSize]];
    
    return [[NSString alloc] initWithFormat: @"name=<?xml version='1.0' standalone='yes' ?>"
                         "<application> <idApp>%@</idApp> <time>2010091184656</time> <system>1</system> <serviceId>%d</serviceId> <adSize>%@</adSize> <deviceSize>%@</deviceSize> <adType>%zd</adType> <token>%@</token> </application>",
                         condition.appId,seviceId,adSize,adDeviceSize,condition.adverType,token];
}

- (NSMutableURLRequest*)getAdGetRequest:(AdViewAdCondition*)condition
{
	self.adTestMode = condition.adTest;
    
	NSURL* url = [NSURL URLWithString: getAdAgentUrl(condition.adTest)];
	NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL: url];
	
    NSString * reqBody = [self getRequestBody:condition];
    
    AdViewLogDebug(@"AdGetRequest: \"%@\"", [url absoluteString]);
    AdViewLogDebug(@"AdGetRequest: \"%@\"", reqBody);
	NSData * postData = [reqBody dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion: YES];
	NSString * postLen = [NSString stringWithFormat:@"%ld", (long)[postData length]];
	req.HTTPMethod = @"POST";
	req.HTTPBody = postData;
	[req setValue: postLen forHTTPHeaderField: @"Content-Length"];
	[req setValue: @"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
	
	return req;
}

- (BOOL)useInternalParser {
	return YES;
}

- (BOOL)parseResponse:(AdViewAdapterResponse*)response
		  AdContent:(AdViewContent*)adContent ErrorInfo:(NSString**)errInfo;
{
	return YES;
}

- (BOOL)parseResponse:(AdViewAdapterResponse*)response contentArr:(NSMutableArray*)contentArr ErrorInfo:(NSString**)errInfo
{
    return YES;
}

- (void)adjustAdSize:(CGSize*)size
{
    
}

- (BOOL)parseXMLStartElement:(NSString*)elementName 
				  attributes:(NSDictionary*)attributes
				   adContent:(AdViewContent*)theAdContent
{
	return YES;
}

// 假如html形式广告返回的尺寸不存在或者有问题，给以默认尺寸
- (void)htmlWebViewSizeDefault:(AdViewContent*)theAdContent
{
    if (self.adType == AdViewBanner)
    {
        theAdContent.adWidth = 320;
        theAdContent.adHeight = 50;
    }
    else if (self.adType == AdViewInterstitial)
    {
        theAdContent.adWidth = 200;
        theAdContent.adHeight = 350;
    }
    else if (self.adType == AdViewSpread)
    {
        theAdContent.adWidth = 320;
        theAdContent.adHeight = 480;
    }
    else
    {
        theAdContent.adWidth = 320;
        theAdContent.adHeight = 50;
    }
}

- (BOOL)parseXMLFoundCharacters:(NSString*)string
					  inElement:(NSString*)elementName
					  adContent:(AdViewContent*)theAdContent
{
    if ([elementName isEqualToString:@"idAd"])
    {
        theAdContent.adId = [NSString stringWithString: string];
    }
    else if ([elementName isEqualToString:@"adShowType"])
    {
        switch ([string intValue])
        {
            case 1:// 图文
                theAdContent.adShowType = AdViewAdSHowType_AdFillImageText;
                if (self.adType == AdViewBanner)
                    theAdContent.adShowType = AdViewAdSHowType_ImageText;
                break;
            case 2:// 图片
                theAdContent.adShowType = AdViewAdSHowType_FullImage;
                break;
            case 3:// gif
                theAdContent.adShowType = AdViewAdSHowType_FullGif;
                break;
            case 4:// html5
                theAdContent.adShowType = AdViewAdSHowType_WebView_Content;
                break;
            default:
                break;
        }
    }
    else if ([elementName isEqualToString:@"adShowText"])
    {
		if (nil == theAdContent.adText) theAdContent.adText = [NSString stringWithString: string];
		else theAdContent.adText = [theAdContent.adText stringByAppendingString:string];
    }
    else if ([elementName isEqualToString:@"adLinkType"])
    {
        theAdContent.adLinkType = [NSString stringWithString: string];
    }
    else if ([elementName isEqualToString:@"adLink"])
    {
        if (nil == theAdContent.adLinkURL)
        {
            theAdContent.adLinkURL = [NSString stringWithString: string];
        }
        else
        {
            theAdContent.adLinkURL = [theAdContent.adLinkURL stringByAppendingString:string];
        }
    }
    else if ([elementName isEqualToString:@"adShowPic"])
    {
        [theAdContent setAdImage:0 Url:string Append:YES];
    }
    else if ([elementName isEqualToString:@"adShowTitle"])
    {
        theAdContent.adTitle = [NSString stringWithString: string];
    }
    else if ([elementName isEqualToString:@"adShowSubTitle"])
    {
        theAdContent.adSubText = [NSString stringWithString:string];
    }
    else if ([elementName isEqualToString:@"adXhtmlSource"])
    {
        if(nil == theAdContent.adBody)
        {
            theAdContent.adBody = [NSString stringWithString:string];
        }
        else
        {
            theAdContent.adBody = [theAdContent.adBody stringByAppendingString:string];
        }
    }
    else if ([elementName isEqualToString:@"adXhtmlSize"])
    {
        NSString *adSize = string;
        if (adSize && [adSize length] > 0)
        {
            NSArray *array = [adSize componentsSeparatedByString:@"x"];
            if ([array count] == 2)
            {
                theAdContent.adWidth = [[array objectAtIndex:0] floatValue];
                theAdContent.adHeight = [[array objectAtIndex:1] floatValue];
                
                CGSize screenSize = [[UIScreen mainScreen] bounds].size;
                BOOL  bIsLand = [AdViewExtTool getDeviceDirection];
                CGFloat screenWidth =  bIsLand?screenSize.height:screenSize.width;
                CGFloat screenHeight =  bIsLand?screenSize.width:screenSize.height;
                if (bIsLand && screenWidth < screenHeight)
                {
                    screenWidth += screenHeight;
                    screenHeight = screenWidth - screenHeight;
                    screenWidth = screenWidth - screenHeight;
                }
                
                if (theAdContent.adWidth > screenWidth || theAdContent.adHeight > screenHeight)
                {
                    CGFloat xScale = theAdContent.adWidth/screenWidth;
                    CGFloat yScale = theAdContent.adHeight/screenHeight;
                    
                    if (xScale >= yScale)
                    {
                        CGFloat width = theAdContent.adWidth;
                        theAdContent.adWidth = screenWidth*3/4;
                        theAdContent.adHeight = theAdContent.adHeight*theAdContent.adWidth/width;
                    }
                    else
                    {
                        CGFloat height = theAdContent.adHeight;
                        theAdContent.adHeight = screenHeight*3/4;
                        theAdContent.adWidth = theAdContent.adHeight*theAdContent.adWidth/height;
                    }
                }
            }
            else
            {
                [self htmlWebViewSizeDefault:theAdContent];
            }
        }
        else
        {
            [self htmlWebViewSizeDefault:theAdContent];
        }
    }
    else if ([elementName isEqualToString:@"clickNumberLimit"])
    {
        theAdContent.maxClickNum = [[NSString stringWithString:string] intValue];
    }
	return YES;
}

//- (NSString*)replaceDefineString:(NSString *)urlString AdContent:(AdViewContent*)content {
//    return urlString;
//}

//may should add some parameter to the linkUrl
- (BOOL)adjustClickLink:(AdViewContent*)adContent
{
    return YES;
}

- (NSString*)copyRightString
{
    if (self.adPlatType == AdViewAdPlatTypeAdDirect) {
        return ADDIRECT_STR;
    }
	return ADEXCHANGE_STR;
}

- (NSError *)parseStatus:(int)statusCode error:(NSError *)error
{
    return error;
}

- (void)cleanDummyData
{
    
}

#pragma mark util methods
+ (void)logRequestHeaders:(NSURLRequest*)requst
{
    NSDictionary *headerDict = [requst allHTTPHeaderFields];
    for (int i = 0; i < [[headerDict allKeys] count]; i++)
    {
        NSString *key0 = [[headerDict allKeys] objectAtIndex:i];
        NSString *val0 = [headerDict objectForKey:key0];
        
        AdViewLogDebug(@"header %d:--key:%@--val:%@---", i, key0, val0);
    }
}

+ (void)metricPing:(NSString*)query
{
    AdViewLogDebug(@"Sending metric ping to %@", query);
    if (nil == query) return;
    
    NSURL *metURL = [NSURL URLWithString:query];
    NSURLRequest *metRequest = [NSURLRequest requestWithURL:metURL];
    [NSURLConnection connectionWithRequest:metRequest
                                  delegate:nil]; // fire and forget
}

@end

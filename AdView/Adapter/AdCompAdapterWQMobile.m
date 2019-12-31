//
//  AdCompAdapterWQMobile.m
//  AdViewSDK
//
//  Created by zhiwen on 12-8-30.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "AdCompAdapterWQMobile.h"
#import "AdCompExtTool.h"
#import "AdCompContent.h"
#import "AdCompConnection.h"
#import <UIKit/UIKit.h>
#import "AdCompView.h"

#import "CJSONDeserializer.h"

#define SZ_Serial_Key @"67590f398bf0447931eb20fa2b63bb36"

static const char *gWQMobileTestUrl[] = {
	"https://s2s.adwaken.com:8090/wqs2s_test/getad",
	"https://s2s.adwaken.com:8090/wqs2s_test/getad",
	"https://s2s.adwaken.com:8090/wqs2s_test/getad",
	"https://s2s.adwaken.com:8090/wqs2s_test/getad",
};

static const char *gWQMobileUrl[] = {
	"https://s2s.adwaken.com:8090/wqs2s/getad",
	"https://s2s.adwaken.com:8090/wqs2s/getad",
	"https://s2s.adwaken.com:8090/wqs2s/getad",
	"https://s2s.adwaken.com:8090/wqs2s/getad",
};

typedef enum tagSZGetType {
	SZGetType_Get = 0,
	SZGetType_GetBody,
	SZGetType_Display,
	SZGetType_Click,
}SZGetType;

typedef struct tagSZRequestItem{
	const char *idStr;
	const char *defVal;
	int  bMust;
}SZRequestItem;

#define SZITEM_ARRSIZE(arr) (sizeof(arr)/sizeof(SZRequestItem))

/*
 */
#define WQMobile_KEY  @"9a1c89a7e5994a03b763487da92ccd5a"

#define REPORT_VIEW_URL @"report_view_url"
#define REPORT_VIEW_TIME @"report_view_time"
#define REPORT_CLICK_URL @"report_click_url"

static const SZRequestItem gGetItems[] =
{
	{"dev","",1},             //sha1 of mac addr, not include ":",lowercase
	{"key","",1},             //
	{"pkg","",1},             //bundle id
    
    {"as","",0},              //ad app id.
	{"pf","iOS",0},           //system, android or ios
    {"sw","",0},              //ad width
    {"sh","",0},              //ad height
    {"ip","",0},
    
    {"pnam","",0},             //app name
    {"psat","T,P,V,H",0},      //ad media type
    {"ppv","1.6.3",0},
    {"pcat","2",0},
    {"su","1",0},
    
    {"ua","",0},
    {"mcc","460",0},             //460
    
    {"ac","1",0},             //ad number of the request
    {"lng","",0},
    {"lat","",0},
    
    {"ct","1",0},           //1, wifi, 2, 2g, 3, 3g, 4, 4g
    
    {"sr","",0},             //480x320
    {"mf","Apple",0},       //mobile manufacture
    {"md","",0},            //like iPhone 4s
    {"pv","5.1",0},         //ios version
    {"bss","",0},           //wifi mac addr, with ":"
    
    {"exm","false",0},
    
    {"ss","apiadviewc633659b4fda54",1},
    {"ssv","1.2",1},
};

//static const SZRequestItem gDisplayItems[] =		//the whole url is get from receive data.
//{
//};

@interface AdCompAdapterWQMobile (PRIVATE)

- (void)setupNotifyTimer:(int)time;
- (void)cleanNotifyTimer;

@end

@implementation AdCompAdapterWQMobile

- (id)init {
	self = [super init];
	if (self) {
		[self initInfo];
	}
	return self;
}

- (void)dealloc {
	infoDict = nil;
}

- (void)initInfo {
	if (nil == infoDict) {
		infoDict = [[NSMutableDictionary alloc] init];
	}
	
	for (int i = 0; i < SZITEM_ARRSIZE(gGetItems); i++)
	{
		[infoDict setObject:[NSString stringWithUTF8String:gGetItems[i].defVal]
					 forKey:[NSString stringWithUTF8String:gGetItems[i].idStr]];
	}
	
	NSString *macStr1 = [[[AdCompExtTool sharedTool] getMacAddress:MacAddrFmtType_Default] lowercaseString];
    NSString *macStr2 = [[[AdCompExtTool sharedTool] getMacAddress:MacAddrFmtType_UpperCaseColon] lowercaseString];
	[infoDict setObject:[AdCompExtTool encodeToPercentEscapeString:macStr2] forKey:@"bss"];
    
    [infoDict setObject:ADVIEWSDK_VERSION forKey:@"ssv"];
    
    
    //NSString *testDev = [AdCompExtTool getSha1HexString:@"180373e97b3f"];
    //AdCompAdLogDebug(@"test dev:%@", testDev);
    
    NSString *devStr = [AdCompExtTool getSha1HexString:macStr1];
	[infoDict setObject:devStr forKey:@"dev"];
    
	//ip
	//NSString *ipVal = [[AdCompExtTool sharedTool] deviceIPAdress];
	//[infoDict setObject:ipVal forKey:@"ip"];
    [infoDict removeObjectForKey:@"ip"];        //if can get net ip, remove it.
    
    [infoDict setObject:WQMobile_KEY forKey:@"key"];
    [infoDict setObject:[[NSBundle mainBundle] bundleIdentifier] forKey:@"pkg"];
    
    NSString *bundleName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
    NSString *bundleVer = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    [infoDict setObject:bundleName forKey:@"pnam"];
    [infoDict setObject:bundleVer forKey:@"ppv"];
    
    [infoDict setObject:[AdCompExtTool encodeToPercentEscapeString:
                         [infoDict objectForKey:@"psat"]] forKey:@"psat"];
    
	NSString *uaStr = [AdCompExtTool encodeToPercentEscapeString:
					   [[AdCompExtTool sharedTool] userAgent]];
	[infoDict setObject:uaStr forKey:@"ua"];
    
	//os_version
    NSString *deviceModel = [[UIDevice currentDevice] model];			//@"iPhone Simulator"
	deviceModel = [deviceModel stringByReplacingOccurrencesOfString:@" " withString:@""];
	NSString *sysVersion = [UIDevice currentDevice].systemVersion;	//@"4.2"
	NSString *sysName = [[UIDevice currentDevice] systemName];		//@"iPhone OS"
    
    //NSString *sysInfo = [NSString stringWithFormat:@"%@%@", sysName, sysVersion];
    //sysInfo = [sysInfo stringByReplacingOccurrencesOfString:@" " withString:@""];

    [infoDict setObject:deviceModel forKey:@"md"];
	[infoDict setObject:[AdCompExtTool encodeToPercentEscapeString:sysName] forKey:@"pf"];
    [infoDict setObject:sysVersion forKey:@"pv"];
    
    //screen.
	CGSize scrSize = [[[UIScreen mainScreen] currentMode] size];
	NSString *strScreenSize = [NSString stringWithFormat:@"%dx%d", (int)scrSize.width,
							   (int)scrSize.height];
	[infoDict setObject:strScreenSize forKey:@"sr"];
}

- (void)setAdCondition:(AdCompAdCondition*)condition
{
	[infoDict setObject:condition.appId forKey:@"as"];
    [infoDict setObject:condition.appPwd forKey:@"key"];
    
    [infoDict setObject:[NSString stringWithFormat:@"%d", (int)condition.adSize.width] forKey:@"sw"];
	[infoDict setObject:[NSString stringWithFormat:@"%d", (int)condition.adSize.height] forKey:@"sh"];
    
	if (condition.hasLocationVal) {
        NSString *latVal = [NSString stringWithFormat:@"%f", condition.latitude];
        NSString *lngVal = [NSString stringWithFormat:@"%f", condition.longitude];
        [infoDict setObject:latVal forKey:@"lat"];
        [infoDict setObject:lngVal forKey:@"lng"];
    } else {
        [infoDict removeObjectForKey:@"lat"];
        [infoDict removeObjectForKey:@"lng"];
    }
}

- (void)linkMutableString:(NSMutableString*)str
				  Pointer:(const SZRequestItem*)pItems
				   Length:(int)len
{
	for (int i = 0; i < len; i++)
	{
		NSString *key0 = [NSString stringWithUTF8String:pItems[i].idStr];
		NSString *val0 = [infoDict objectForKey:key0];
        
        if (nil == val0 || [val0 length] < 1) continue;
		
		//NSString *val0esc = [val0 stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		if (i > 0) [str appendString:@"&"];
		[str appendFormat:@"%@=%@", key0, val0];
	}
}

- (NSString*)getVisitUrl:(SZGetType)type
{
	const char *cStr = self.adTestMode?gWQMobileTestUrl[type]:gWQMobileUrl[type];
	
	NSMutableString *urlStr = [NSMutableString stringWithUTF8String:cStr];
	
	[urlStr appendString:@"?"];
	[self linkMutableString:urlStr Pointer:gGetItems
					 Length:SZITEM_ARRSIZE(gGetItems)];
	return urlStr;
}

- (void)setURLRequestHeaders:(NSMutableURLRequest*)request Type:(SZGetType)type
{
}

- (NSMutableURLRequest*)getAdVisitRequest:(SZGetType)type
{
	NSString *urlStr = [self getVisitUrl:type];
	
	AdCompAdLogDebug(@"WQMobile Url %d:%@", type, urlStr);
	
	NSURL* url = [NSURL URLWithString:urlStr];
	NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:url];
	[self setURLRequestHeaders:req Type:type];
	req.HTTPMethod = @"GET";
	
	return req;
}

- (NSMutableURLRequest*)getAdGetRequest:(AdCompAdCondition*)condition
{
    [self cleanNotifyTimer];            //if wait one, clean
    
	[self setAdCondition:condition];
	self.adTestMode = condition.adTest;
	
	return [self getAdVisitRequest:SZGetType_Get];
}

+ (NSMutableURLRequest*)utilGetRequest:(NSString*)urlStr
{
    if (nil == urlStr) return nil;
    NSURL* url = [NSURL URLWithString:urlStr];
    return [NSMutableURLRequest requestWithURL:url];
}

- (NSMutableURLRequest*)getAdReportRequest:(BOOL)bClickOtherDisplay AdContent:(AdCompContent*)theAdContent
{
    //will use url from get content.
    if (bClickOtherDisplay) {//click
        return [AdCompAdapterWQMobile utilGetRequest:
                [infoDict objectForKey:REPORT_CLICK_URL]];
    } else {//display
        if (nil == [infoDict objectForKey:REPORT_VIEW_TIME]) {
            return [AdCompAdapterWQMobile utilGetRequest:
                    [infoDict objectForKey:REPORT_VIEW_URL]];
        }
    }
    
	return nil;
}

- (BOOL)useInternalParser {
	return NO;
}

/*
 */
- (BOOL)parseResponse:(AdCompAdapterResponse*)response
		  AdContent:(AdCompContent*)adContent ErrorInfo:(NSString**)errInfo
{
    NSString *errMsg = nil;
    
	switch (response.type) {
        case AdCompConnectionStateRequestDisplay:
        case AdCompConnectionStateRequestClick:		//if no need report.
            if (nil == response.headers && 0 == response.status)
            {
                int nTimeVal = [[infoDict objectForKey:REPORT_VIEW_TIME] intValue];
                if (AdCompConnectionStateRequestDisplay == response.type
                    && nTimeVal > 0)
                {//delay visit the report url.
                    [self setupNotifyTimer:nTimeVal];
                }
                
                return YES;
            }
            break;
            
        case AdCompConnectionStateRequestGet:
            [infoDict removeObjectForKey:REPORT_VIEW_URL];
            [infoDict removeObjectForKey:REPORT_VIEW_TIME];
            [infoDict removeObjectForKey:REPORT_CLICK_URL];
            break;
	}
    
	NSError *jsonError = nil;
	id parsed = [[CJSONDeserializer deserializer] deserialize:response.body error:&jsonError];
	if (errInfo != nil)
		*errInfo = @"Error parsing config JSON from server";
	
	if (parsed == nil) {
		return NO;
	}
	
	
	if (![parsed isKindOfClass:[NSDictionary class]]) return NO;
	NSDictionary *dict = (NSDictionary*)parsed;
    
    if (AdCompConnectionStateRequestGet != response.type)
    {
        NSString *retStr = [[dict objectForKey:@"return"] lowercaseString];
        return  [retStr isEqualToString:@"ok"];
    } else {
        NSString *status = [[dict objectForKey:@"status"] lowercaseString];
        if (![status isKindOfClass:[NSString class]] || ![status isEqualToString:@"ok"]) {
            errMsg = [dict objectForKey:@"message"];
		
            if (nil != errInfo) {
                if (errMsg) *errInfo = errMsg;
                else *errInfo = @"No ad response";
            }
		
            AdCompAdLogInfo(@"request failed, err info:%@", errMsg);
		
            return NO;
        }
    }
	
	if (AdCompConnectionStateRequestGet == response.type) {
        NSArray *adArr = (NSArray*)[dict objectForKey:@"ads"];
        if (![adArr isKindOfClass:[NSArray class]]
            || [adArr count] < 1) {
         
            if (nil != errInfo) *errInfo = @"No ad response";
            return NO;
        }
        
        NSDictionary *dicAd = [adArr objectAtIndex:0];
        if (![dicAd isKindOfClass:[NSDictionary class]]) return NO;
        
        NSString *typeStr = [dicAd objectForKey:@"type"];
        
        if (![typeStr isKindOfClass:[NSString class]]) {
            if (nil != errInfo) *errInfo = @"Error data format";
            return NO;
        }
        
        if ([dicAd objectForKey:@"width"] && [dicAd objectForKey:@"height"]) {
            adContent.adRetSize = CGSizeMake([[dicAd objectForKey:@"width"] floatValue],
            [[dicAd objectForKey:@"height"] floatValue]);
        }
        
        if ([typeStr isEqualToString:@"html"]
            || [typeStr isEqualToString:@"image"]) {
            adContent.adShowType = [NSString stringWithFormat:@"%d", AdCompAdSHowType_WebView];
            adContent.adWebURL = [dicAd objectForKey:@"url"];
            NSURL* url = [NSURL URLWithString:adContent.adWebURL];
            adContent.adWebRequest = [NSURLRequest requestWithURL:url];
        }
        
        NSArray *arrBeacons = [dicAd objectForKey:@"beacons"];
        for (NSDictionary *dicBeacon in arrBeacons) {
            NSString *beaconType = [dicBeacon objectForKey:@"type"];
            NSString *beaconUrl = [dicBeacon objectForKey:@"url"];
            int      beaconNfTime = [[dicBeacon objectForKey:@"notifyTime"] intValue];
            if ([[beaconType lowercaseString] isEqualToString:@"view"]) {
                if (beaconUrl) [infoDict setObject:beaconUrl forKey:REPORT_VIEW_URL];
                if (beaconNfTime > 0) {
                    [infoDict setObject:[NSString stringWithFormat:@"%d", beaconNfTime]
                                 forKey:REPORT_VIEW_TIME];
                }
            } else if ([[beaconType lowercaseString] isEqualToString:@"click"]) {
                if (beaconUrl) [infoDict setObject:beaconUrl forKey:REPORT_CLICK_URL];
            }
        }
	}
	
	if (errInfo != nil)
		*errInfo = nil;
	return YES;
}

- (void)adjustAdSize:(CGSize*)size
{
	if (320 == size->width) {
		size->height = 50;
	}
}

- (NSString*)copyRightString
{
	return @"WQMobile";
}

- (void)notifyHandler
{
    _notifyTimer = nil;
    
    NSString *displayUrl = [infoDict objectForKey:REPORT_VIEW_URL];
    [AdCompAdapter metricPing:displayUrl];
}

- (void)cleanNotifyTimer
{
    [_notifyTimer invalidate];
    _notifyTimer = nil;
}

- (void)setupNotifyTimer:(int)time
{
    [self cleanNotifyTimer];
    
    if (nil == [infoDict objectForKey:REPORT_VIEW_URL]) return;
    
    _notifyTimer = [NSTimer scheduledTimerWithTimeInterval:time target:self
                                                  selector:@selector(notifyHandler)
                                                  userInfo:nil repeats:NO];
}

- (void)cleanDummyData
{
    [super cleanDummyData];
    
    //clear timer data.
    [self cleanNotifyTimer];
}

@end

//
//  AdCompAdapterSuiZong.m
//  AdViewSDK
//
//  Created by zhiwen on 12-8-30.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "AdCompAdapterSuiZong.h"
#import "AdCompExtTool.h"
#import "AdCompContent.h"
#import "AdCompConnection.h"
#import <UIKit/UIKit.h>

#define SZ_Serial_Key @"67590f398bf0447931eb20fa2b63bb36"

static const char *gSuiZongTestUrl[] = {
	"https://apitest1.suizong.com/mobile/ADServerGetAPI",
	"https://apitest1.suizong.com/mobile/ADServerGetBodyAPI",
	"https://apitest1.suizong.com/mobile/ADServerShowAPI",
	"https://apitest1.suizong.com/mobile/ADServerClickAPI",
};

static const char *gSuiZongUrl[] = {
	"https://api.suizong.com/mobile/ADServerGetAPI",
	"https://api.suizong.com/mobile/ADServerGetBodyAPI",
	"https://api.suizong.com/mobile/ADServerShowAPI",
	"https://api.suizong.com/mobile/ADServerClickAPI",
};

static const char *gSuiZongUrlKey[] = {
	NULL,
	NULL,
	"imps_url",
	"click_url",
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
	int  bMd5;
}SZRequestItem;

#define SZITEM_ARRSIZE(arr) (sizeof(arr)/sizeof(SZRequestItem))

static const SZRequestItem gGetItems[] =
{
	{"appkey","",1},
	{"uuid","",1},
	{"client","1",1},			//1, ios
	{"ip","192.168.1.65",1},
	{"osversion","4.2",1},
	{"density","1",1},			//if 3gs, 1, if ipad4, 2
	{"aw","320",1},
	{"ah","48",1},
	{"pw","320",1},
	{"ph","480",1},
	{"long","0.0",1},
	{"lat","0.0",1},
	{"device","iPhone",1},
	{"sdk", "adview_1.5.6", 0}
};

//values from response of get.
static const SZRequestItem gGetBodyItems[] =
{
	{"adid","",1},
	{"updatetime","",1},
	{"sid","",1},
};

static const SZRequestItem gDisplayItems[] =		//click is same.
{
	{"appkey","",1},
	{"uuid","",1},
	{"client","",1},
	{"ip","",1},
	{"adid","",1},
	{"updatetime","",1},
	{"sid","",1},
	{"pw","320",1},
	{"ph","480",1},
	{"long","0.0",1},
	{"lat","0.0",1},
	{"device","iPhone",1},
};

@implementation AdCompAdapterSuiZong

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
	
	NSString *uuidStr = [[AdCompExtTool sharedTool] getMacAddress:MacAddrFmtType_Default];
	[infoDict setObject:uuidStr forKey:@"uuid"];
	
	//ip
	NSString *ipVal = [[AdCompExtTool sharedTool] deviceIPAdress];
	[infoDict setObject:ipVal forKey:@"ip"];
	
	//os_version
	
    NSString *deviceModel = [[UIDevice currentDevice] model];			//@"iPhone Simulator"
	deviceModel = [deviceModel stringByReplacingOccurrencesOfString:@" " withString:@""];
	NSString *sysVersion = [[UIDevice currentDevice] systemVersion];	//@"4.2"
	//NSString *sysName = [[UIDevice currentDevice] systemName];		//@"iPhone OS"
	
	//os_version
	[infoDict setObject:sysVersion forKey:@"osversion"];
	
	//density
	int densityVal = [AdCompExtTool getDensity];
	[infoDict setObject:[NSString stringWithFormat:@"%d", densityVal] forKey:@"density"];
	
	//pw,ph
	UIWindow *win = [[UIApplication sharedApplication] keyWindow];
    CGRect winFrame = win.frame;
    UIDeviceOrientation orientation = (UIDeviceOrientation)[UIApplication sharedApplication].statusBarOrientation;
    BOOL bIsLand = UIDeviceOrientationIsLandscape(orientation);
    CGFloat winWidth = bIsLand?winFrame.size.height:winFrame.size.width;
    CGFloat winHeight = bIsLand?winFrame.size.width:winFrame.size.height;
	
	[infoDict setObject:[NSString stringWithFormat:@"%d", (int)winWidth] forKey:@"pw"];
	[infoDict setObject:[NSString stringWithFormat:@"%d", (int)winHeight] forKey:@"ph"];
	
	//long,lat	(should set by caller, not set now.)
	
	//device
	[infoDict setObject:deviceModel forKey:@"device"];
}

- (void)setAdCondition:(AdCompAdCondition*)condition
{
	[infoDict setObject:condition.appId forKey:@"appkey"];
	[infoDict setObject:[NSString stringWithFormat:@"%d", (int)condition.adSize.width] forKey:@"aw"];
	[infoDict setObject:[NSString stringWithFormat:@"%d", (int)condition.adSize.height] forKey:@"ah"];
	
	[infoDict setObject:[NSString stringWithFormat:@"%f", condition.longitude] forKey:@"long"];
	[infoDict setObject:[NSString stringWithFormat:@"%f", condition.latitude] forKey:@"lat"];
}

- (NSString*)getVisitUrl:(SZGetType)type
{
	const char *cStr = self.adTestMode?gSuiZongTestUrl[type]:gSuiZongUrl[type];
	
	NSString *urlStr = [NSString stringWithUTF8String:cStr];
	
	if (NULL != gSuiZongUrlKey[type])
	{
		NSString *urlKey0 = [NSString stringWithUTF8String:gSuiZongUrlKey[type]];
		if (nil != [infoDict objectForKey:urlKey0])
		{
			urlStr = [infoDict objectForKey:urlKey0];
		}
	}	
	return urlStr;
}

- (void)setURLRequestHeaders:(NSMutableURLRequest*)request Type:(SZGetType)type
{
	const SZRequestItem *pSZItems = gGetItems;
	int		szItemNum = SZITEM_ARRSIZE(gGetItems);
	
	switch (type) {
		case SZGetType_GetBody:
			pSZItems = gGetBodyItems;
			szItemNum = SZITEM_ARRSIZE(gGetBodyItems);
			break;
		case SZGetType_Display:
		case SZGetType_Click:
			pSZItems = gDisplayItems;
			szItemNum = SZITEM_ARRSIZE(gDisplayItems);
			break;
		default:
			//type = SZGetType_Get;
			break;
	}
	
	
	NSMutableString *strCheck = [NSMutableString stringWithCapacity:1024];
	
	for (int i = 0; i < szItemNum; i++)
	{
		NSString *key0 = [NSString stringWithUTF8String:pSZItems[i].idStr];
		NSString *val0 = [infoDict objectForKey:key0];
		
		//NSString *val0esc = [val0 stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		
		[request setValue:val0 forHTTPHeaderField:key0];
		
		if (pSZItems[i].bMd5) {
			[strCheck appendString:val0];
		}
	}
	
	//need check val.
	NSString *pCheck = [AdCompExtTool getSha1HexString:strCheck];
	NSString *strICheck = [pCheck stringByAppendingString:SZ_Serial_Key];
	
	NSString *iCheck = [AdCompExtTool getMd5HexString:strICheck];
	
	//AdCompAdLogDebug(@"sha1 input:%@", strCheck);
	//AdCompAdLogDebug(@"sha1 val:%@", pCheck);
	//AdCompAdLogDebug(@"md5 input:%@", strICheck);
	//AdCompAdLogDebug(@"md5 val:%@", iCheck);
	
	[request setValue:pCheck forHTTPHeaderField:@"pcheck"];
	[request setValue:iCheck forHTTPHeaderField:@"icheck"];
	
	//log the http header.
	NSDictionary *headerDict = [request allHTTPHeaderFields];
	for (int i = 0; i < [[headerDict allKeys] count]; i++)
	{
		NSString *key0 = [[headerDict allKeys] objectAtIndex:i];
		NSString *val0 = [headerDict objectForKey:key0];
		
		AdCompAdLogDebug(@"header %d:--key:%@--val:%@---", i, key0, val0);
	}
}

- (NSMutableURLRequest*)getAdVisitRequest:(SZGetType)type
{
	NSString *urlStr = [self getVisitUrl:type];
	
	AdCompAdLogDebug(@"SuiZong Url %d:%@", type, urlStr);
	
	NSURL* url = [NSURL URLWithString:urlStr];
	NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:url];
	[self setURLRequestHeaders:req Type:type];
	req.HTTPMethod = @"GET";
	
	return req;
}

- (NSMutableURLRequest*)getAdGetRequest:(AdCompAdCondition*)condition
{
	[self setAdCondition:condition];
	self.adTestMode = condition.adTest;
	
	return [self getAdVisitRequest:SZGetType_Get];
}

- (NSMutableURLRequest*)getAdReportRequest:(BOOL)bClickOtherDisplay AdContent:(AdCompContent*)theAdContent
{
	SZGetType type = bClickOtherDisplay?SZGetType_Click:SZGetType_Display;
	
	return [self getAdVisitRequest:type];
}

- (BOOL)useInternalParser {
	return NO;
}

- (BOOL)parseResponse:(AdCompAdapterResponse*)response
		  AdContent:(AdCompContent*)adContent ErrorInfo:(NSString**)errInfo
{
	NSString *retKey = @"status";
	if (AdCompConnectionStateRequestGet != response.type)
		retKey = @"result";
	
	NSString *retObj = [response.headers objectForKey:retKey];
	NSString *errMsg = nil;
	
	AdCompAdLogInfo(@"request type:%d, key:%@, val:%@", response.type, retKey, retObj);
	
	if (nil == retObj || 1 != [retObj intValue]) {//failed, not get the ad.
		errMsg = [response.headers objectForKey:@"msg"];
		
		if (nil != errMsg && nil != errInfo) *errInfo = errMsg;
		
		AdCompAdLogInfo(@"request failed, err info:%@", errMsg);
		
		return NO;
	}
	
	if (AdCompConnectionStateRequestGet == response.type) {
		//set header value to infoDict.
		[infoDict addEntriesFromDictionary:response.headers];		//will replace new value.
		
        CGFloat fWidth = [[response.headers objectForKey:@"width"] floatValue];
        CGFloat fHeight = [[response.headers objectForKey:@"height"] floatValue];
        
        adContent.adRetSize = CGSizeMake(fWidth, fHeight);
        
		adContent.adWebURL = [self getVisitUrl:SZGetType_GetBody];
		adContent.adShowType = [NSString stringWithFormat:@"%d", AdCompAdSHowType_WebView];
		adContent.adWebRequest = [self getAdVisitRequest:SZGetType_GetBody];
	}
	
	return YES;
}

- (void)adjustAdSize:(CGSize*)size
{
	if (320 == size->width) {
		size->height = 48;
	}
}

@end

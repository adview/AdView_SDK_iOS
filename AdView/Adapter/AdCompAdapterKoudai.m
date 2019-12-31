//
//  AdCompAdapterKoudai.m
//  AdViewSDK
//
//  Created by zhiwen on 12-8-30.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "AdCompAdapterKoudai.h"
#import "AdCompExtTool.h"
#import "AdCompContent.h"
#import "AdCompConnection.h"
#import <UIKit/UIKit.h>

#import "CJSONDeserializer.h"

#define KOUDAI_URL_SCHEMA  @"IShopping2://"

static const char *gKoudaiTestUrl[] = {
	"https://test.m.koudai.com:9001/glmi/resources/spread/index.html",
	"https://test.m.koudai.com:9001/glmi/resources/spread/index.html",
	"https://test.m.koudai.com:9001/glmi/resources/spread/index.html",
	"https://test.m.koudai.com:9001/glmi/resources/spread/index.html",
};

static const char *gKoudaiUrl[] = {
	"https://co.koudai.com/glmi/resources/spread/index.html",
	"https://co.koudai.com/glmi/resources/spread/index.html",
	"https://co.koudai.com/glmi/resources/spread/index.html",
	"https://co.koudai.com/glmi/resources/spread/index.html",
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

static const SZRequestItem gGetItems[] =
{
	{"m","",1},                         //mac addr
    {"type","2",1},                     //ad type
    {"i","",0},                          //imei, for android
    {"s","2",0},                         //0(男),1（女）,2（未知)
    
	{"o","",0},                         //openudid
	{"p","iPhone",1},					//platform,iphone,ipad,android
	{"v","5.1",0},						//sys version
	{"u","",0},							//identifierForVender
	{"install","0",1},					//if koudai app installed? 0（未安装），1（已安装
	{"fr","adview",1},					//channel
    
    {"utm_source","adview",1},           //channel
    
    {"bundleid", "", 0},                //application bundle id
};

////values from response of get.
//static const SZRequestItem gOptionItems1[] =
//{
//	{"lat","",0},					//latitude
//	{"lon","",0},					//longitude
//	{"model","",0},					//like iphone4
//	{"manufacturer","Apple",0},		//like Apple
//	{"location","+86",0},			//like +86
//};
//
//static const SZRequestItem gOptionItems2[] =		//click is same.
//{
//	{"age","",0},
//	{"gender","",0},				//male, female
//	{"martial","",0},				//single, married
//	{"income","",0},				//salary
//	{"zip","",0},					//postal zip, 
//	
//	{"tag","",0},
//};

@implementation AdCompAdapterKoudai

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
	
	//bundleid
	NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
	[infoDict setObject:bundleID forKey:@"bundleid"];
	
	//model and ua
    NSString *deviceModel = [[UIDevice currentDevice] model];			//@"iPhone Simulator"
	deviceModel = [deviceModel stringByReplacingOccurrencesOfString:@" " withString:@""];
	
	[infoDict setObject:deviceModel forKey:@"p"];
    
    NSString *sysVersion = [[UIDevice currentDevice] systemVersion];	//@"4.2"
    [infoDict setObject:sysVersion forKey:@"v"];
    
	NSString *uuidStr = [[[AdCompExtTool sharedTool] getMacAddress:MacAddrFmtType_Default] lowercaseString];
    [infoDict setObject:uuidStr forKey:@"m"];
    
    [infoDict setObject:[AdCompExtTool getIDA] forKey:@"u"];
    
    int nInstall = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:KOUDAI_URL_SCHEMA]]?1:0;
    [infoDict setObject:[NSString stringWithFormat:@"%d", nInstall] forKey:@"install"];
    
    //[infoDict setObject:uuidStr forKey:@"o"];
	
	//density
	//int densityVal = [AdCompExtTool getDensity];
	//[infoDict setObject:[NSString stringWithFormat:@"%d", densityVal] forKey:@"density"];
	
	//long,lat	(should set by caller, not set now.)
	//sw, sh, adu, etc.
}

- (void)setAdCondition:(AdCompAdCondition*)condition
{
	//int densityVal = [AdCompExtTool getDensity];
	
	[infoDict setObject:condition.appId forKey:@"fr"];
	[infoDict setObject:[NSString stringWithFormat:@"%d", (int)condition.adSize.width]
				 forKey:@"sw"];
	[infoDict setObject:[NSString stringWithFormat:@"%d", (int)condition.adSize.height] 
				 forKey:@"sh"];
	
	[infoDict setObject:[NSString stringWithFormat:@"%f", condition.longitude] forKey:@"lon"];
	[infoDict setObject:[NSString stringWithFormat:@"%f", condition.latitude] forKey:@"lat"];
}

- (void)linkMutableString:(NSMutableString*)str 
				  Pointer:(const SZRequestItem*)pItems
				   Length:(int)len
{
	for (int i = 0; i < len; i++)
	{
		NSString *key0 = [NSString stringWithUTF8String:pItems[i].idStr];
		NSString *val0 = [infoDict objectForKey:key0];
        
        if (!pItems[i].bMust && (nil == val0 || 0 == [val0 length]))        //skip empty optional.
            continue;
		
		//NSString *val0esc = [val0 stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		if (i > 0) [str appendString:@"&"];
		[str appendFormat:@"%@=%@", key0, val0];
	}
}

- (NSString*)getVisitUrl:(SZGetType)type
{
	const char *cStr = self.adTestMode?gKoudaiTestUrl[type]:gKoudaiUrl[type];
	
	NSMutableString *urlStr = [NSMutableString stringWithUTF8String:cStr];
	
	[urlStr appendString:@"?"];
	[self linkMutableString:urlStr Pointer:gGetItems 
					 Length:SZITEM_ARRSIZE(gGetItems)];
#if 0
	[urlStr appendString:@"&"];
	[self linkMutableString:urlStr Pointer:gOptionItems1 
					 Length:SZITEM_ARRSIZE(gOptionItems1)];
#endif
	return urlStr;
}

- (void)setURLRequestHeaders:(NSMutableURLRequest*)request Type:(SZGetType)type
{
}

- (NSMutableURLRequest*)getAdVisitRequest:(SZGetType)type
{
	NSString *urlStr = [self getVisitUrl:type];
	
	AdCompAdLogDebug(@"Koudai Url %d:%@", type, urlStr);
	
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

- (NSMutableURLRequest*)getAdReportRequest:(BOOL)bClickOtherDisplay
								 AdContent:(AdCompContent*)theAdContent
{
	return nil;		//won't do report.
}

- (BOOL)useInternalParser {
	return NO;
}

/*
 */
- (BOOL)parseData:(NSData*)data AdContent:(AdCompContent*)adContent
		ErrorInfo:(NSString**)errInfo
{
    if (nil == data || [data length] < 1)
        return NO;
    
    int nShowType = AdCompAdSHowType_WebView_Content;
    adContent.adShowType = [NSString stringWithFormat:@"%d", nShowType];
    
    int nActionType = AdCompAdActionType_OpenURL; //AdCompAdActionType_Unknown;
    adContent.adActionType = nActionType;
    
    adContent.adRetSize = CGSizeMake(320, 50);
    
	const char *cStr = self.adTestMode?gKoudaiTestUrl[SZGetType_GetBody]:gKoudaiUrl[SZGetType_GetBody];
	NSMutableString *urlStr = [NSMutableString stringWithUTF8String:cStr];
    
    adContent.adBaseUrlStr = urlStr;
    adContent.adWebURL = urlStr;
    NSString *strTemp = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
    
    adContent.adBody = strTemp;
	return YES;
}

- (void)parseStatus:(int)statusCode ErrorInfo:(NSString**)errInfo
{
    if (errInfo) *errInfo = @"No ad available!";
}

- (BOOL)parseResponse:(AdCompAdapterResponse*)response
		  AdContent:(AdCompContent*)adContent ErrorInfo:(NSString**)errInfo
{
	BOOL ret = NO;
	
	switch (response.type) {
	case AdCompConnectionStateRequestDisplay:
	case AdCompConnectionStateRequestClick:		//if no need report.
			return YES;
	}
    
    [self parseStatus:response.status ErrorInfo:errInfo];
	
	if (2 != response.status/100)
	{
		return NO;
	}
	
	if (AdCompConnectionStateRequestGet == response.type) {
		ret = [self parseData:response.body
					AdContent:adContent ErrorInfo:errInfo];
		if (!ret) return NO;
	}
	

	
	return ret;
}

//may should add some parameter to the linkUrl
- (BOOL)adjustClickLink:(AdCompContent*)adContent
{
    if (!adContent.adLinkURL) return NO;
    
    NSArray *arrItems = [adContent.adLinkURL componentsSeparatedByString:@"?"];
    if ([arrItems count] != 2) return NO;

    NSString *baseUrl = [arrItems objectAtIndex:0];
    NSString *paramStr = [arrItems objectAtIndex:1];
    
    NSMutableDictionary *infoDic1 = [NSMutableDictionary dictionaryWithCapacity:2];
    
    arrItems = [paramStr componentsSeparatedByString:@"&"];
    for (int i = 0; i < [arrItems count]; i++)
    {
        NSString *item = [arrItems objectAtIndex:i];
        if (nil == item || ![item isKindOfClass:[NSString class]] || [item length] < 1)
            continue;
        
        NSArray *pairArr = [item componentsSeparatedByString:@"="];
        if ([pairArr count] != 2)
            continue;
        
        NSString *key = [pairArr objectAtIndex:0];
        if (nil == key || ![key isKindOfClass:[NSString class]] || [key length] < 1)
            continue;
        NSString *val = [pairArr objectAtIndex:1];
        if (nil == val || ![val isKindOfClass:[NSString class]])
            continue;
        
        [infoDic1 setObject:val forKey:key];
    }

    [infoDic1 setObject:[infoDict objectForKey:@"m"] forKey:@"m"];
    [infoDic1 setObject:[infoDict objectForKey:@"u"] forKey:@"u"];
    [infoDic1 setObject:[infoDict objectForKey:@"fr"] forKey:@"fr"];
    [infoDic1 setObject:[infoDict objectForKey:@"utm_source"] forKey:@"utm_source"];
    [infoDic1 setObject:[infoDict objectForKey:@"install"] forKey:@"install"];
    
    
    NSMutableString *retStr = [NSMutableString stringWithString:baseUrl];
    [retStr appendString:@"?"];
    
    NSArray *keysArr = [infoDic1 allKeys];
    for (int i = 0; i < [keysArr count]; i++)
    {
        NSString *key0 = [keysArr objectAtIndex:i];
        NSString *val0 = [infoDic1 objectForKey:key0];

        if (i > 0) [retStr appendString:@"&"];
        [retStr appendFormat:@"%@=%@", key0, val0];
    }
    
    adContent.adLinkURL = retStr;
    
    return YES;
}

- (void)adjustAdSize:(CGSize*)size
{
	if (320 == size->width) {
		size->height = 50;
	}
	if (480 == size->width) {
		size->height = 60;
	}
}

@end

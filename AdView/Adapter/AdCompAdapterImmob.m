//
//  AdCompAdapterImmob.m
//  AdViewSDK
//
//  Created by zhiwen on 12-8-30.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "AdCompAdapterImmob.h"
#import "AdCompExtTool.h"
#import "AdCompContent.h"
#import "AdCompConnection.h"
#import <UIKit/UIKit.h>

#import "CJSONDeserializer.h"

static const char *gImmobTestUrl[] = {
	"https://sandbox.api.limei.com/queryad",
	"https://sandbox.api.limei.com/queryad",
	"https://sandbox.api.limei.com/queryad",
	"https://sandbox.api.limei.com/queryad",
};

static const char *gImmobUrl[] = {
	"https://adserving.immob.cn/queryad",
	"https://adserving.immob.cn/queryad",
	"https://adserving.immob.cn/queryad",
	"https://adserving.immob.cn/queryad",
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
	{"adu","",1},
	{"bundleid","",1},						//application bundle id
	{"uid","",1},							//device uuid
	{"at","1",1},							//ad type
	{"ua","",1},							//user agent，like apple/iphone4/ios/6.0
	{"sw","320",1},							//ad width
	{"sh","50",1},							//ad height
	
	{"ip","192.168.1.65",1},
	
	{"mod","3",1},							//mod of visit, fix 3
	{"rf","2",1},							//format of response, fix 2
	{"pv","2.1.1",1},						//server api version, fix 2.1.1 now.
	
	//external not in doc.
	//{"nt", "3", 1},
    {"gmo", "+8", 1}
};

//values from response of get.
static const SZRequestItem gOptionItems1[] =
{
	{"lat","",0},					//latitude
	{"lon","",0},					//longitude
	{"model","",0},					//like iphone4
	{"manufacturer","Apple",0},		//like Apple
	{"location","+86",0},			//like +86
};

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

@implementation AdCompAdapterImmob

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
	
	for (int i = 0; i < SZITEM_ARRSIZE(gOptionItems1); i++)
	{
		[infoDict setObject:[NSString stringWithUTF8String:gOptionItems1[i].defVal]
					 forKey:[NSString stringWithUTF8String:gOptionItems1[i].idStr]];
	}	
	
	NSString *uuidStr = [[AdCompExtTool sharedTool] getMacAddress:MacAddrFmtType_Colon];
	NSString *uuidStr2 = [uuidStr stringByReplacingOccurrencesOfString:@":" withString:@"%3A"];
	NSString *uidStr = [NSString stringWithFormat:@"%@__", uuidStr2];
	[infoDict setObject:uidStr forKey:@"uid"];
	
	//ip
	NSString *ipVal = [[AdCompExtTool sharedTool] deviceIPAdress];
	[infoDict setObject:ipVal forKey:@"ip"];
	
	//bundleid
	NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
	[infoDict setObject:bundleID forKey:@"bundleid"];
	
	//model and ua
    NSString *deviceModel = [[UIDevice currentDevice] model];			//@"iPhone Simulator"
	deviceModel = [deviceModel stringByReplacingOccurrencesOfString:@" " withString:@""];
	NSString *sysVersion = [[UIDevice currentDevice] systemVersion];	//@"4.2"
	//NSString *sysName = [[UIDevice currentDevice] systemName];		//@"iPhone OS"
	
	[infoDict setObject:deviceModel forKey:@"model"];	
	NSString *uaStr = [NSString stringWithFormat:@"apple/%@/ios/%@", deviceModel, sysVersion];
	[infoDict setObject:uaStr forKey:@"ua"];
	
	//density
	int densityVal = [AdCompExtTool getDensity];
	[infoDict setObject:[NSString stringWithFormat:@"%d", densityVal] forKey:@"density"];	
	
	//long,lat	(should set by caller, not set now.)
	//sw, sh, adu, etc.
}

- (void)setAdCondition:(AdCompAdCondition*)condition
{
	//int densityVal = [AdCompExtTool getDensity];
	
	[infoDict setObject:condition.appId forKey:@"adu"];
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
		
		//NSString *val0esc = [val0 stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		if (i > 0) [str appendString:@"&"];
		[str appendFormat:@"%@=%@", key0, val0];
	}
}

- (NSString*)getVisitUrl:(SZGetType)type
{
	const char *cStr = self.adTestMode?gImmobTestUrl[type]:gImmobUrl[type];
	
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
	
	AdCompAdLogDebug(@"Immob Url %d:%@", type, urlStr);
	
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
{"id":"2a694cd64772e0f0a35c418902df702d",
 "key":"b44464504a61480ab8858f2dd3be7a9f",
 "clickUrl":"http:\/\/api.immob.cn\/clickad?adu=d0638eec79904e783c4889abacc46e5c&skey=b44464504a61480ab8858f2dd3be7a9f&cid=2a694cd64772e0f0a35c418902df702d&uid=60%3A33%3A4B%3A97%3AB7%3A36__&mod=3&nt=&imsi=&ua=apple%2FiPhoneSimulator%2Fios%2F6.0&at=1&gmo=8&rid=135641880042327137",
 "type":"3",
 "showImg":"http:\/\/resource.lmmob.com\/commercial\/921355968623.jpg"}
 */
- (BOOL)parseData:(NSData*)data AdContent:(AdCompContent*)adContent
		ErrorInfo:(NSString**)errInfo
{
	NSError *jsonError = nil;
	id parsed = [[CJSONDeserializer deserializer] deserialize:data error:&jsonError];
	if (errInfo != nil)
		*errInfo = @"Error parsing config JSON from server";
	
	if (parsed == nil) {
		return NO;
	}
	
	
	if (![parsed isKindOfClass:[NSDictionary class]]) return NO;
	NSDictionary *dict = (NSDictionary*)parsed;
	
	if (nil == [dict objectForKey:@"key"]) return NO;		//result not 1.
	
	NSDictionary *dictData = dict;
	if (nil == dictData) return NO;
	
	adContent.adId = [dictData objectForKey:@"id"];
	NSString *adImageURL = [[dictData objectForKey:@"showImg"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    [adContent setAdImage:0 Url:adImageURL Append:NO];
	adContent.adText = [[dictData objectForKey:@"showText"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	adContent.adLinkURL = [dictData objectForKey:@"clickUrl"];
    int nType = [[dictData objectForKey:@"type"] intValue];
    
    int nShowType = AdCompAdSHowType_FullImage;
    switch (nType) {
        case 3:nShowType = AdCompAdSHowType_FullImage; break;
        case 1:nShowType = AdCompAdSHowType_Text;      break;
        case 2:nShowType = AdCompAdSHowType_ImageText; break;
        default:
            break;
    }
	adContent.adShowType = [NSString stringWithFormat:@"%d", nShowType];
	
	if (errInfo != nil)
		*errInfo = nil;
	return YES;
}

- (void)parseStatus:(int)statusCode ErrorInfo:(NSString**)errInfo
{
    switch (statusCode) {
        case 420: if (errInfo) *errInfo = @"Missing mandatory parameters"; break;
        case 421: if (errInfo) *errInfo = @"Unknown aduint id!"; break;
        case 422: if (errInfo) *errInfo = @"Invalid uid!"; break;
        case 423: if (errInfo) *errInfo = @"No ad available!"; break;
        default:
            break;
    }
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

//
//  AdCompAdapterInMobi.m
//  AdViewSDK
//
//  Created by zhiwen on 12-8-30.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "AdCompAdapterInMobi.h"
#import "AdCompExtTool.h"
#import "AdCompContent.h"
#import "AdCompConnection.h"
#import <UIKit/UIKit.h>

#import "CJSONDeserializer.h"

static const char *gInMobiTestUrl[] = {
	"https://i.w.sandbox.inmobi.com/showad.asm",
	"https://i.w.sandbox.inmobi.com/showad.asm",
	"https://i.w.sandbox.inmobi.com/showad.asm",
	"https://i.w.sandbox.inmobi.com/showad.asm",
};

static const char *gInMobiUrl[] = {
	"https://i.w.inmobi.com/showad.asm",
	"https://i.w.inmobi.com/showad.asm",
	"https://i.w.inmobi.com/showad.asm",
	"https://i.w.inmobi.com/showad.asm",
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
	{"mk-siteid","",1},
	{"mk-carrier","",1},											//ip
	{"h-user-agent","",1},										//
	{"mk-version","pr-SPEC-ATATA-20090521",1},					//
	{"u-id-adt","0",1},									//if ios6 and Limit Ad tracking enabled?
};

//values from response of get.
static const SZRequestItem gOptionItems1[] =
{
	{"d-localization","zh_CN",0},						//en_US
	//{"d-nettype","",0},								//wifi, etc.
	{"d-device-screen-size","",0},					//like 320X480
	{"d-device-screen-density","",0},				//like 2.0 in iphone4
	{"d-orientation","1",0},						//portrait
	
	{"mk-ads", "1", 0},
	{"mk-ad-slot", "9", 0},							//ad Size type. 9 -- 320x48
	//{"mk-placement", "top", 0},					//ad place where?
	//{"ad-type", "int", 0},
	{"u-id-map", "", 0},							//unique id of device.
	{"u-latlong-accu", "", 0},						//like 79.30,80.456,0
	{"format", "axml", 0},
	
	{"ref-tag", "adsAdview", 0},
};

//static const SZRequestItem gOptionItems2[] =		//click is same.
//{
//	{"u-age","",0},
//	{"u-gender","",0},				//male, female
//	{"u-location","",0},			//City-State-Country
//	{"u-interests","",0},			//like "cars, sports, F1, stocks"
//	{"u-postalCode","",0},			//postal zip,
//	{"u-areaCode","",0}
//};

@implementation AdCompAdapterInMobi

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

	
    AdCompExtTool *tool = [AdCompExtTool sharedTool];
    NSString *idMapStr = [tool getInMobiIdMap];
    AdCompAdLogDebug(@"%@", idMapStr);
	[infoDict setObject:[AdCompExtTool encodeToPercentEscapeString:idMapStr]
                 forKey:@"u-id-map"];
	
    //u-id-adt
    [infoDict setObject:[NSString stringWithFormat:@"%d", tool.advTrackingEnabled]
                 forKey:@"u-id-adt"];
    
	//ip
	NSString *ipVal = [[AdCompExtTool sharedTool] deviceIPAdress];
	[infoDict setObject:ipVal forKey:@"mk-carrier"];
	
	//ua
	NSString *uaStr = [AdCompExtTool encodeToPercentEscapeString:
					   [[AdCompExtTool sharedTool] userAgent]];
	[infoDict setObject:uaStr
				 forKey:@"h-user-agent"];
	
	//model
    //NSString *deviceModel = [[UIDevice currentDevice] model];			//@"iPhone Simulator"
	//deviceModel = [deviceModel stringByReplacingOccurrencesOfString:@" " withString:@""];
	//NSString *sysVersion = [[UIDevice currentDevice] systemVersion];	//@"4.2"
	//NSString *sysName = [[UIDevice currentDevice] systemName];		//@"iPhone OS"
		
	//net-type. not implement here.
	
	//d-localization
	NSLocale *locale = [NSLocale currentLocale];
	NSString *langCode = [locale objectForKey:NSLocaleLanguageCode];//match the country's lang
	//NSString *langSetCode = [[NSLocale preferredLanguages] objectAtIndex:0];
	NSString *countryCode = [locale objectForKey:NSLocaleCountryCode];
	NSString *locStr = [NSString stringWithFormat:@"%@_%@", langCode, countryCode];
	[infoDict setObject:locStr forKey:@"d-localization"];
	
	
	//screen size.
	CGRect scrRect = [[UIScreen mainScreen] bounds];
	NSString *strScreenSize = [NSString stringWithFormat:@"%dX%d", (int)scrRect.size.width,
							   (int)scrRect.size.height];
	[infoDict setObject:strScreenSize forKey:@"d-device-screen-size"];
	
	//orientation.
	int nOrient = 1;
	UIDeviceOrientation orientation = (UIDeviceOrientation)[UIApplication sharedApplication]
					.statusBarOrientation;
	switch (orientation) {
		case UIDeviceOrientationPortraitUpsideDown:	nOrient = 2; break;
		case UIDeviceOrientationLandscapeLeft:		nOrient = 3; break;
		case UIDeviceOrientationLandscapeRight:		nOrient = 4; break;
		default: nOrient = 1;
	}
	[infoDict setObject:[NSString stringWithFormat:@"%d", nOrient] forKey:@"d-orientation"];
	
	
	//density
	int densityVal = [AdCompExtTool getDensity];
	[infoDict setObject:[NSString stringWithFormat:@"%d.0", densityVal] 
				 forKey:@"d-device-screen-density"];
	
	//etc.
}

- (void)setAdCondition:(AdCompAdCondition*)condition
{
	[infoDict setObject:condition.appId forKey:@"mk-siteid"];
	
	int adWidth = (int)condition.adSize.width;
	int adHeight = (int)condition.adSize.height;
	int adSlot = 9;											//320x48
	if (adWidth <= 320 && adHeight > 200) adSlot = 10;		//300x250
	else if (adWidth > 400 && adWidth <=500) adSlot = 12;	//468x60
	else if (adWidth >= 700) adSlot = 11;					//728x90
	
	[infoDict setObject:[NSString stringWithFormat:@"%d", adSlot] forKey:@"mk-ad-slot"];
	
    if (condition.hasLocationVal) {
        [infoDict setObject:[NSString stringWithFormat:@"%f,%f,%f", condition.latitude, condition.longitude, condition.accuracy]
                     forKey:@"u-latlong-accu"];
    } else {
        [infoDict removeObjectForKey:@"u-latlong-accu"];
    }
}

- (void)linkMutableString:(NSMutableString*)str
				  Pointer:(const SZRequestItem*)pItems
				   Length:(int)len
{
    BOOL bFirst = YES;
	for (int i = 0; i < len; i++)
	{
		NSString *key0 = [NSString stringWithUTF8String:pItems[i].idStr];
		NSString *val0 = [infoDict objectForKey:key0];
        
        if (nil == val0) continue;
		
		//NSString *val0esc = [val0 stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		if (!bFirst) [str appendString:@"&"];
		[str appendFormat:@"%@=%@", key0, val0];
        
        bFirst = NO;
	}
}

- (NSString*)getVisitUrl:(SZGetType)type
{
    BOOL bTest = self.adTestMode;
#if TARGET_IPHONE_SIMULATOR
    bTest = YES;
#endif
	const char *cStr = bTest?gInMobiTestUrl[type]:gInMobiUrl[type];
	
    if (bTest) {
        NSString *testId = @"4028cba631d63df10131e1d4650600cd";
        [infoDict setObject:testId forKey:@"mk-siteid"];
    }
    
	NSMutableString *urlStr = [NSMutableString stringWithUTF8String:cStr];
	
	return urlStr;
}

- (void)setURLRequestHeaders:(NSMutableURLRequest*)request Type:(SZGetType)type
{
	NSMutableString *strBody =  [NSMutableString stringWithUTF8String:""];
	[self linkMutableString:strBody Pointer:gGetItems
					 Length:SZITEM_ARRSIZE(gGetItems)];
#if 1
	[strBody appendString:@"&"];
	[self linkMutableString:strBody Pointer:gOptionItems1
					 Length:SZITEM_ARRSIZE(gOptionItems1)];
#endif
    AdCompAdLogDebug(@"post body:%@", strBody);
    NSData* postData = [strBody dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion: YES];
    NSString* postLen = [NSString stringWithFormat:@"%ld", (long)[postData length]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = postData;
    [request setValue: postLen forHTTPHeaderField: @"Content-Length"];
    [request setValue: @"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
}

- (NSMutableURLRequest*)getAdVisitRequest:(SZGetType)type
{
	NSString *urlStr = [self getVisitUrl:type];
	
	AdCompAdLogDebug(@"InMobi Url %d:%@", type, urlStr);
	
	NSURL* url = [NSURL URLWithString:urlStr];
	NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:url];
	[self setURLRequestHeaders:req Type:type];
	req.HTTPMethod = @"POST";
    
    [AdCompAdapter logRequestHeaders:req];
	
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
	return YES;
}

/*
 XML Sample:
 <AdResponse>
 <Ads number="1">
 <Ad type="banner" actionType="web">
 <ImageURL>http://r.edge.inmobicdn.net/FileData/6549de45-cb69-418a-99a7-f6b21c1a87d79.png</ImageURL>
 <ImageAltText></ImageAltText>
 <Placement>page</Placement>
 <AdURL>http://c.w.inmobi.com/c.asm/3/b/qb3/zjc/2/4k/lx/u/0/0/0/x/8cf2b34f-013a-1000-ce1d-3fe0176200c0/1/1d5025af</AdURL>
 </Ad>
 </Ads>
 </AdResponse>
 
 AXML Sample:
 <AdResponse><Ads number="1"><Ad type="banner" actionType="2" actionName="web" width="320" height="48">
 <AdURL>http://c.w.inmobi.com/c.asm/3/b/qb3/po1/2/4k/lx/u/0/0/0/x/af8b941a-013a-1000-ea1d-3fe0176200c0/1/23e24ce1</AdURL> 
 <![CDATA[ <a href="http://c.w.inmobi.com/c.asm/3/b/qb3/po1/2/4k/lx/u/0/0/0/x/af8b941a-013a-1000-ea1d-3fe0176200c0/1/23e24ce1"> 
 <img border="0" src="http://r.edge.inmobicdn.net/FileData/6549de45-cb69-418a-99a7-f6b21c1a87d79.png" alt="" /> </a>
 <style> body {margin:0px;} </style> ]]> 
 </Ad>
 </Ads></AdResponse>
 
 ActionType:
 web, appstore, call, video, audio, itunes, map, search, sms, camera
 */
- (BOOL)parseXMLStartElement:(NSString*)elementName 
				  attributes:(NSDictionary*)attributes
				   adContent:(AdCompContent*)theAdContent
{
	if ([elementName isEqualToString:@"Ads"]) {//check number
		if (1 != [[attributes objectForKey:@"number"] intValue])		//error.
		{
			theAdContent.adParseError = AdCompContentErrorType_NoFill;
			return NO;
		}
	}
	else if ([elementName isEqualToString:@"Ad"]) {
		NSString *typeStr = [[attributes objectForKey:@"type"] lowercaseString];
		NSString *actionType = [[attributes objectForKey:@"actionName"] lowercaseString];
        
        CGFloat fWidth = [[attributes objectForKey:@"width"] floatValue];
        CGFloat fHeight = [[attributes objectForKey:@"height"] floatValue];
        
        theAdContent.adRetSize = CGSizeMake(fWidth, fHeight);
		
		int nShowType = AdCompAdSHowType_WebView_Content;
		if ([typeStr isEqualToString:@"rm"])
			nShowType = AdCompAdSHowType_WebView_Video;
		theAdContent.adShowType = [NSString stringWithFormat:@"%d", nShowType];
		
		int nActionType = AdCompAdActionType_OpenURL; //AdCompAdActionType_Unknown;
		if ([actionType isEqualToString:@"web"])
			nActionType = AdCompAdActionType_Web;
        else if ([actionType isEqualToString:@"appstore"])
            nActionType = AdCompAdActionType_AppStore;
		theAdContent.adActionType = nActionType;
	}
	
	return YES;
}

- (BOOL) parseXMLFoundCharacters:(NSString*)string
					  inElement:(NSString*)elementName
					  adContent:(AdCompContent*)theAdContent
{
	if ([elementName isEqualToString:@"AdURL"]) {
		if (nil == theAdContent.adLinkURL) theAdContent.adLinkURL = [NSString stringWithString: string];
		else theAdContent.adLinkURL = [theAdContent.adLinkURL stringByAppendingString:string];
    } else {
		NSString *valStr = [string stringByTrimmingCharactersInSet:
								   [NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		if ([valStr length] > 0) {
			if (nil == theAdContent.adBody) theAdContent.adBody = [NSString stringWithString:valStr];
			else theAdContent.adBody = [theAdContent.adBody stringByAppendingString:valStr];
		}
    }
	
	return YES;
}

- (BOOL)parseResponse:(AdCompAdapterResponse*)response
		  AdContent:(AdCompContent*)adContent ErrorInfo:(NSString**)errInfo
{
	return NO;
}

- (void)adjustAdSize:(CGSize*)size
{
#if 1
	if (320 == size->width) {
		size->height = 48;
	}
	if (480 == size->width) {
		size->width = 468;
	}
#endif
}

- (NSString*)copyRightString
{
	return @"InMobi";
}

@end

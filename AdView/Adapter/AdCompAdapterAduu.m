//
//  AdCompAdapterAduu.m
//  AdViewSDK
//
//  Created by zhiwen on 12-8-30.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "AdCompAdapterAduu.h"
#import "AdCompExtTool.h"
#import "AdCompContent.h"
#import "AdCompConnection.h"
#import <UIKit/UIKit.h>

#define SZ_Serial_Key @"67590f398bf0447931eb20fa2b63bb36"

static const char *gAduuTestUrl[] = {
	"https://api.adcome.cn/v1/adlist",
	"https://api.adcome.cn/v1/adlist",
	"https://api.adcome.cn/v1/evt",
	"https://api.adcome.cn/v1/evt",
};

static const char *gAduuUrl[] = {
	"https://api.adcome.cn/v1/adlist",
	"https://api.adcome.cn/v1/adlist",
	"https://api.adcome.cn/v1/evt",
	"https://api.adcome.cn/v1/evt",
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
 sourceid:adview_android
 sourcekey:m643b0lz8sph7ka0
 adpos:adview_ban
 
iOS:
 sourceid:adview_ios
 sourcekey:6r4pb0ay87ksjhem
 adpos:adview_ban
 
 增加了一个appid，表示开发者在aduu上注册的应用id
 */
#define ADUU_SOURCEKEY  @"6r4pb0ay87ksjhem"

static const SZRequestItem gGetItems[] =
{
	{"sourceid","adview_ios",1},
	{"token","",1},             //sourcekey,
	{"uuid","",0},              //
	{"timestamp","",1},
    
	{"count","1",0},
	{"adpos","adview_ban",1},
	{"location","",0},
	{"imei","000000000000000",1},
	{"imsi","000000000000000",1},
	{"brand","",1},             //like iphone3gs
	{"platform","",1},          //like ios4.2
    
	{"appname","",0},
    {"apptype","",0},
	{"appmemo","",0},           //app desc.
    
	{"nettype", "4", 1},         //1(移动)，2(联通)，3(电信)，4(wifi)
    {"macaddr", "", 1},         //12 hex, not include ":"
    {"screen", "", 1},          //widthSheight
    {"channel", "", 0},
    {"density", "", 0},
    
    //extern
    {"appid", "", 1},
};

static const SZRequestItem gDisplayItems[] =		//click is same.
{
	{"sourceid","adview_ios",1},
	{"token","",1},
	{"uuid","",1},                      //
	{"reqid","",1},
	{"location","",0},
    
	{"nettype","4",0},
	{"adid","",1},
	{"evttype","",1},
	{"evtcontent","",0},
	{"evttime","",1},
    
    {"appid", "", 0},
};

@implementation AdCompAdapterAduu

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

#define IMEI_SIM    @"000000000000000"

- (void)initInfo {
	if (nil == infoDict) {
		infoDict = [[NSMutableDictionary alloc] init];
	}
	
	for (int i = 0; i < SZITEM_ARRSIZE(gGetItems); i++)
	{
		[infoDict setObject:[NSString stringWithUTF8String:gGetItems[i].defVal]
					 forKey:[NSString stringWithUTF8String:gGetItems[i].idStr]];
	}
	
	NSString *macStr = [[AdCompExtTool sharedTool] getMacAddress:MacAddrFmtType_Default];
	[infoDict setObject:macStr forKey:@"macaddr"];
    
    NSString *uuidStr = [NSString stringWithFormat:@"%@%@00000",IMEI_SIM, macStr];
    [infoDict setObject:uuidStr forKey:@"uuid"];
	
	//os_version
    NSString *deviceModel = [[UIDevice currentDevice] model];			//@"iPhone Simulator"
	deviceModel = [deviceModel stringByReplacingOccurrencesOfString:@" " withString:@""];
	NSString *sysVersion = [[UIDevice currentDevice] systemVersion];	//@"4.2"
	NSString *sysName = [[UIDevice currentDevice] systemName];		//@"iPhone OS"
    
    NSString *sysInfo = [NSString stringWithFormat:@"%@%@", sysName, sysVersion];
    sysInfo = [sysInfo stringByReplacingOccurrencesOfString:@" " withString:@""];

    [infoDict setObject:deviceModel forKey:@"brand"];
	[infoDict setObject:sysInfo forKey:@"platform"];
    
    //nettype. default 4(wifi), other should judge here.
    int netTypeVal = [AdCompExtTool aduuNetworkType];
    NSString *netTypeStr = [NSString stringWithFormat:@"%d", netTypeVal];
    [infoDict setObject:netTypeStr forKey:@"nettype"];
    
    //screen.
	CGRect scrRect = [[UIScreen mainScreen] bounds];
	NSString *strScreenSize = [NSString stringWithFormat:@"%dS%d", (int)scrRect.size.width,
							   (int)scrRect.size.height];
	[infoDict setObject:strScreenSize forKey:@"screen"];
    
	//density
	int densityVal = [AdCompExtTool getDensity];
	[infoDict setObject:[NSString stringWithFormat:@"%d", densityVal] forKey:@"density"];
}

- (void)setAdCondition:(AdCompAdCondition*)condition
{
	[infoDict setObject:condition.appId forKey:@"appid"];
    
    //generate token.
	
	if (condition.hasLocationVal) {
        NSString *locStrVal = [NSString stringWithFormat:@"%fS%f", condition.latitude, condition.longitude];
        [infoDict setObject:locStrVal forKey:@"location"];
    } else {
        [infoDict removeObjectForKey:@"location"];
    }
}

- (NSString*)getVisitUrl:(SZGetType)type
{
	const char *cStr = self.adTestMode?gAduuTestUrl[type]:gAduuUrl[type];
	
	NSString *urlStr = [NSString stringWithUTF8String:cStr];
		
	return urlStr;
}

- (void)setURLRequestHeaders:(NSMutableURLRequest*)request Type:(SZGetType)type
{
	const SZRequestItem *pSZItems = gGetItems;
	int		szItemNum = SZITEM_ARRSIZE(gGetItems);
	
	switch (type) {
		case SZGetType_Display:
		case SZGetType_Click:
			pSZItems = gDisplayItems;
			szItemNum = SZITEM_ARRSIZE(gDisplayItems);
			break;
		default:
			type = SZGetType_Get;
			break;
	}
	
    if (SZGetType_Display == type)
        [infoDict setObject:@"1" forKey:@"evttype"];
    else [infoDict setObject:@"2" forKey:@"evttype"];
    
    //timestamp, evttime
    NSString *timeStamp = [NSString stringWithFormat:@"%lld", (long long)([[NSDate date] timeIntervalSince1970]*1000)];
    [infoDict setObject:timeStamp forKey:@"timestamp"];
    [infoDict setObject:timeStamp forKey:@"evttime"];
    
    //token
    NSString *tokenIn = nil;
    if (SZGetType_Get== type)
        tokenIn = [NSString stringWithFormat:@"%@%@%@%@", [infoDict objectForKey:@"sourceid"],
               ADUU_SOURCEKEY, timeStamp, IMEI_SIM];
    else tokenIn = [NSString stringWithFormat:@"%@%@%@", [infoDict objectForKey:@"sourceid"],
                    ADUU_SOURCEKEY, timeStamp];
    NSString *token = [AdCompExtTool encryptAduuMd5:tokenIn];
    [infoDict setObject:token forKey:@"token"];
	
	NSMutableString *strBody = [NSMutableString stringWithCapacity:1024];
	
    BOOL    bFirst = YES;
	for (int i = 0; i < szItemNum; i++)
	{
		NSString *key0 = [NSString stringWithUTF8String:pSZItems[i].idStr];
		NSString *val0 = [infoDict objectForKey:key0];
        
        if (!val0) continue;
        if (!pSZItems[i].bMust && [val0 length] < 1) continue;      //empty and not must.
        
        if (!bFirst) [strBody appendString:@"&"];
        [strBody appendFormat:@"%@=%@", key0, val0];
        bFirst = NO;
	}
    
    AdCompAdLogDebug(@"post:%@", strBody);
    
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
	
	AdCompAdLogDebug(@"Aduu Url %d:%@", type, urlStr);
	
	NSURL* url = [NSURL URLWithString:urlStr];
	NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:url];
	[self setURLRequestHeaders:req Type:type];
	req.HTTPMethod = @"POST";
	
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

/*
 error:
 {
 "result": -1,
 "msg": "appid invalid"
 }
 
 ok return:
 {
 "reqid": "foi0uvrj6rxje5bt",
 "uuid": "00000000000000060334B97B73600000",
 "count":1,
 "ads": [
 
 {
 "adid": 329,
 "feetype": 3,
 "feecode": 0,
 "clicktype": 4,
 "clickcontent": "10086,test",
 "showtype": 1,
 
 "text": "test sms",
 "subtext": "",
 "icon": "http://aduu.cn/res/img/ad_l2.png",
 "bg": "http://aduu.cn/res/img/ad_b2.png"
 
 }
 ]
 }
 */
- (BOOL)parseResponse:(AdCompAdapterResponse*)response
		  AdContent:(AdCompContent*)adContent ErrorInfo:(NSString**)errInfo
{
    NSString *errMsg = nil;
    
	NSError *jsonError = nil;
	id parsed = [[CJSONDeserializer deserializer] deserialize:response.body error:&jsonError];
	if (errInfo != nil)
		*errInfo = @"Error parsing config JSON from server";
	
	if (parsed == nil) {
		return NO;
	}
	
	
	if (![parsed isKindOfClass:[NSDictionary class]]) return NO;
	NSDictionary *dict = (NSDictionary*)parsed;
    
	if (0 != [[dict objectForKey:@"result"] intValue]) {//
		errMsg = [dict objectForKey:@"msg"];
		
		if (nil != errMsg && nil != errInfo) *errInfo = errMsg;
		
		AdCompAdLogInfo(@"request failed, err info:%@", errMsg);
		
		return NO;
	}
	
	if (AdCompConnectionStateRequestGet == response.type) {
		int nAd = [[dict objectForKey:@"count"] intValue];
        if (nAd < 1) return NO;
        
        NSArray *adArr = (NSArray*)[dict objectForKey:@"ads"];
        if (![adArr isKindOfClass:[NSArray class]]
            || [adArr count] < 1) return NO;
        
        NSDictionary *dicAd = [adArr objectAtIndex:0];
        if (![dicAd isKindOfClass:[NSDictionary class]]) return NO;
        
        int nAduuShowType = [[dicAd objectForKey:@"showtype"] intValue];
        
		adContent.adText = [dicAd objectForKey:@"text"];
        adContent.adSubText = [dicAd objectForKey:@"subtext"];
        
        AdCompAdSHowType  nAdViewShowType = AdCompAdSHowType_Text;
        switch (nAduuShowType) {
            case 1:
                [adContent setAdImage:0 Url:[dicAd objectForKey:@"icon"] Append:NO];
                adContent.adBgImgURL = [dicAd objectForKey:@"bg"];
                nAdViewShowType = AdCompAdSHowType_ImageText;
                break;
            case 2:
                [adContent setAdImage:0 Url:[dicAd objectForKey:@"pic"] Append:NO];
                nAdViewShowType = AdCompAdSHowType_FullImage;
                break;
            case 3:
                [adContent setAdImage:0 Url:[dicAd objectForKey:@"pic"] Append:NO];
                nAdViewShowType = AdCompAdSHowType_FullImage;
                break;
            case 4:
                break;
            default:
                break;
        }
        
        adContent.adShowType = [NSString stringWithFormat:@"%d", nAdViewShowType];
        
        int nAduuClickType = [[dicAd objectForKey:@"clicktype"] intValue];
        adContent.adLinkURL = [dicAd objectForKey:@"clickcontent"];
        
        switch (nAduuClickType) {
            case 1:adContent.adActionType = AdCompAdActionType_Web; break;
            case 2:adContent.adActionType = AdCompAdActionType_AppStore; break;
            case 3:adContent.adActionType = AdCompAdActionType_Call; break;
            case 4:adContent.adActionType = AdCompAdActionType_Sms; break;
            default:break;
        }
        
        NSString *strAdid = [NSString stringWithFormat:@"%d", [[dicAd objectForKey:@"adid"] intValue]];
        [infoDict setObject:strAdid forKey:@"adid"];
        [infoDict setObject:[dict objectForKey:@"reqid"] forKey:@"reqid"];
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
	return @"Aduu";
}

@end

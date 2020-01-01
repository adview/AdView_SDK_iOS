 //
//  ADConnectDataProcessor.m
//  AdViewVideoSample
//
//  Created by AdView on 15-4-8.
//  Copyright (c) 2015年 AdView. All rights reserved.
//

#import "ADConnectDataProcessor.h"
#import "AdViewExtTool.h"
#import "AdViewVastFileHandle.h"
#import "AdViewReachability.h"
#import "AdViewDefines.h"
#import "AdViewRolloverAdapterModel.h"

static const NSString *TOKEN_KEY = @"dur75pt6jlyim2910rroamiyv54qszuk";

static const char* hostArr[] = {
    "https://bid.adview.com/agent/getAd",
    "http://gbjtest.adview.com/agent/getAd",
};

typedef struct RequestItem {
    const char *idStr;
    const char *defVal;
    int bMust;
}AVRequestItem;

static const AVRequestItem requestItems[] = {
    {"bi","",1},    // bundleId
    {"an","",0},    // appName
    {"sv","",1},    // sdkVersion
    {"av","",0},    // appVersion
    {"aid","",1},   // appId
    {"posId","",1},
    {"sy","1",1},   // 0-andriod  1-iOS
    {"agadn","",1},
    {"st","5",1},   // sdkTyep  video -> 5
    {"at","",1},    //
    {"as","",1},    // adSize : spreenSize
    {"ac","1",1},   // adCount
    {"du","",0},    // is iPad or iPhone
    
    {"lat","",0},   // latitude
    {"lon","",0},   // longitude
    {"bty","0",1},  // 电池电量
    {"hv","0",0},   // 横竖屏 默认竖屏0
    
    {"dt","",0},         // model for device.
    {"db","Apple",0},    // Manufacturers of device
    {"se","",1},         // mobile/unicom/telecom
    {"nt","",0},         // wifi/2g/3g
    {"ov","",0},         // operating system（OS）version.
    {"re","",0},         // rusolution 分辨率
    {"ud","",1},         // uuid
    {"ma","",0},         // mac address,not include ":",lowercase
    {"ia","",0},         // idfa
    {"iv","",0},         // idfv
    {"ua","",0},         // userAgent : web useragent
    {"jb","",0},         // jailBreak = 1, 0 is no jailBreak.
    {"bssid","",0},
    {"ssid","",0},
    {"deny","",0},         // density 屏幕密度
    {"ro","1",1},          // is SSP（1） or AdFill（0）;
    {"ti","",1},           // time
    {"to","",1},           // md5 of bundleId+appId+adSize+uuid+time
    
    {"gdpr","0",1},        //是否使用GDPR
    {"consent","0",1},     //GDPR的consentString
    {"CMPPresent","0",0},
    {"parsedPurposeConsents","0",0},
    {"parsedVendorConsents","0",0},
    {"us_privacy","0",0}   //加州CCPA
};

static const int requestItemSize = sizeof(requestItems)/sizeof(AVRequestItem);

@interface ADConnectDataProcessor() {
    NSMutableDictionary* infoDict; //请求数据容器
}

@end

@implementation ADConnectDataProcessor

- (void)dealloc {
    infoDict = nil;
}

- (id)init {
    if (self = [super init]) {
        [self initInfo];
    }
    return self;
}

- (void)initInfo {
    if (nil == infoDict) {
        infoDict = [[NSMutableDictionary alloc] init];
    }
    
    for (int i = 0; i < requestItemSize; i++) {
        [infoDict setValue:[NSString stringWithUTF8String:requestItems[i].defVal] forKey:[NSString stringWithUTF8String:requestItems[i].idStr]];
    }
    
    NSString *bundle = [[NSBundle mainBundle] bundleIdentifier];
    [infoDict setObject:bundle forKey:@"bi"];
    
    NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    if (nil == appName || [appName length] == 0) {
        appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey];
    }
    appName = [AdViewExtTool URLEncodedString:appName];
    if(nil == appName)
        appName = @"";
    [infoDict setObject:appName forKey:@"an"];
    
    NSString *appVer = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    if (nil == appVer) {
        appVer = @"unknown";
    }
    [infoDict setObject:appVer forKey:@"av"];
    
    [infoDict setObject:ADVIEWSDK_VERSION forKey:@"sv"];
    
    NSString *deviceType = [[UIDevice currentDevice] model];
    deviceType = [deviceType stringByReplacingOccurrencesOfString:@" " withString:@""];
    [infoDict setObject:deviceType forKey:@"dt"];
    
    //获取电量
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    float battery = ([[UIDevice currentDevice] batteryLevel])*100;
    [infoDict setObject:[NSString stringWithFormat:@"%d",(int)battery] forKey:@"bty"];
    
    NSString *jailBreak = [NSString stringWithFormat:@"%d",[AdViewExtTool isJailbroken]];
    [infoDict setObject:jailBreak forKey:@"jb"];
    
    NSString *netType = [self checkNetworkType];
    if (netType && netType.length) {
        [infoDict setObject:netType forKey:@"nt"];
    }
    
    NSString *service = [AdViewExtTool serviceProviderCode];
    [infoDict setObject:service forKey:@"se"];
    
    [infoDict setObject:[NSString stringWithFormat:@"%d",[AdViewExtTool getDeviceIsIpad]] forKey:@"du"];
    
    [infoDict setObject:[AdViewExtTool getIDA] forKey:@"ia"];
    [infoDict setObject:[AdViewExtTool getIDFV] forKey:@"iv"];
    
    [infoDict setObject:[AdViewExtTool URLEncodedString:[AdViewExtTool sharedTool].userAgent] forKey:@"ua"];
    
    NSDictionary *dict = [AdViewExtTool getSSIDInfo];
    if (dict) {
        NSString *ssid = [[dict objectForKey:@"SSID"] lowercaseString];
        NSString *bssid = [[dict objectForKey:@"BSSID"] lowercaseString];
        if (ssid && ssid.length) {
            [infoDict setObject:ssid forKey:@"ssid"];
        }
        if (bssid && bssid.length) {
            [infoDict setObject:bssid forKey:@"bssid"];
        }
    }
    
    NSString *macStr = [[[AdViewExtTool sharedTool] getMacAddress:MacAddrFmtType_Default] lowercaseString];
    [infoDict setObject:[AdViewExtTool URLEncodedString:macStr] forKey:@"ma"];
    
    [infoDict setObject:[[UIDevice currentDevice] systemVersion] forKey:@"ov"];
    
    NSString * uuid = macStr;
    //if ios >= 7.0, get the idfa as udid
    NSString *sysVersion = [[UIDevice currentDevice] systemVersion];	//@"4.2"
    float sysVer = [sysVersion floatValue];
    if (sysVer >= 7.0f) {
        uuid = [AdViewExtTool getIDA];
    }
    
    [infoDict setObject:uuid forKey:@"ud"];
    [[AdViewExtTool sharedTool] storeObject:uuid forKey:@"{UUID}"];
    
    [infoDict setObject:[NSString stringWithFormat:@"%.2f",[UIScreen mainScreen].scale] forKey:@"deny"];
    
    NSString *agadnString = @"";
    Class ToutiaoClass = NSClassFromString(@"BUFullscreenVideoAd");
    if (ToutiaoClass) {
        agadnString = @"1008";
    }
    
    // baidu GDT 未完成
    [infoDict setObject:agadnString forKey:@"agadn"];
    BOOL isPortrait = UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation);
    [infoDict setObject:[NSString stringWithFormat:@"%d",isPortrait] forKey:@"hv"];
}

- (NSString*)checkNetworkType {
    AdViewViewNetworkStatus netStatus = [[AdViewReachability reachabilityForInternetConnection] currentReachabilityStatus];
    
    NSString *str;
    
    switch (netStatus) {
        case AdViewViewNotReachable:
            str = @"other";
            break;
        case AdViewReachableViaWiFi:
            str = @"WiFi";
            break;
        case AdViewReachableViaWWAN:
            str = @"2G/3G";
            break;
        case kAdViewReachableVia2G:
            str = @"2G";
            break;
        case kAdViewReachableVia3G:
            str = @"3G";
            break;
        case kAdViewReachableVia4G:
            str = @"4G";
            break;
        default:
            break;
    }
    return str;
}

- (void)addTemporaryData:(AVTemporaryData*)tempData
{
    [infoDict setObject:tempData.appID forKey:@"aid"];
    [infoDict setObject:tempData.posID forKey:@"posId"];
    
    //⚠️ 这里是弹出视频、贴片视频.at字段在上传的时候无意义.服务器不做处理
    NSString *adType = @"6";
    if (tempData.videoType == AdViewVideoTypePreMovie) {
        adType = @"7";
    }
    [infoDict setObject:adType forKey:@"at"];
    
    NSString *time = [NSString stringWithFormat:@"%ld",(long)[[NSDate date] timeIntervalSince1970]];
    [infoDict setObject:time forKey:@"ti"];
    NSString *bundle = [infoDict objectForKey:@"bi"];
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    if (screenSize.width < screenSize.height) {
        screenSize.width = screenSize.width + screenSize.height;
        screenSize.height = screenSize.width - screenSize.height;
        screenSize.width = screenSize.width - screenSize.height;
    }
    NSString *adSize = [NSString stringWithFormat:@"%dX%d",(int)screenSize.width,(int)screenSize.height];
    [infoDict setObject:adSize forKey:@"as"];
    
    NSString *uuid = [infoDict objectForKey:@"ud"];
    NSString *token = [AdViewExtTool getMd5HexString:[NSString stringWithFormat:@"%@%@%@%@%@%@",bundle,tempData.appID,adSize,uuid,time,TOKEN_KEY]];
    [infoDict setObject:token forKey:@"to"];
    
    [infoDict setObject:[NSString stringWithFormat:@"%d",tempData.subjectToGDPR] forKey:AdView_IABConsent_SubjectToGDPR];
    if (tempData.consentString && tempData.consentString.length) {
        [infoDict setObject:tempData.consentString forKey:AdView_IABConsent_ConsentString];
    } else {
        [infoDict setObject:@"0" forKey:AdView_IABConsent_ConsentString];
    }
    
    //这里的字段需要和 AVRequestItem 一样名称
    [infoDict setObject:[NSString stringWithFormat:@"%d",tempData.CMPPresent] forKey:AdView_IABConsent_CMPPresent];
       
       if (tempData.parsedPurposeConsents) {
           [infoDict setObject:tempData.parsedPurposeConsents forKey:AdView_IABConsent_ParsedPurposeConsents];
       }
       
       if (tempData.parsedVendorConsents) {
           [infoDict setObject:tempData.parsedVendorConsents forKey:AdView_IABConsent_ParsedVendorConsents];
       }
       
       //CCPA
       if (tempData.ccpaString) {
           [infoDict setObject:tempData.ccpaString forKey:AdView_IABConsent_CCPA];
       }
}

- (NSString*)getUrlStr {
    BOOL useTestServer = [[[NSUserDefaults standardUserDefaults] objectForKey:USE_TEST_SERVER_KEY] boolValue];    
    NSMutableString *urlStr = [NSMutableString stringWithUTF8String:hostArr[useTestServer]];
    [urlStr appendString:@"?"];
    
    for (int i = 0; i < requestItemSize; i++) {
        NSString *key = [NSString stringWithUTF8String:requestItems[i].idStr];
        NSString *value = [infoDict objectForKey:key];
        if (nil == value || [value length] < 1) continue;
        
        if (i > 0) [urlStr appendString:@"&"];
        [urlStr appendFormat:@"%@=%@",key,value];
    }
    return urlStr;
}

- (NSURLRequest*)getVideoRequest:(AVTemporaryData*)tempData {
    [self addTemporaryData:tempData];
    NSString *urlStr = [self getUrlStr];
    NSURL *url = [NSURL URLWithString:urlStr];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    req.timeoutInterval = 10;
    [req setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    req.HTTPMethod = @"GET";
    return req;
}

- (BOOL)isFileExists:(NSString*)path {
    NSFileManager *manage = [NSFileManager defaultManager];
    BOOL ret = [manage fileExistsAtPath:path] && [manage isReadableFileAtPath:path];
    return ret;
}

//解析
- (BOOL)parseResponse:(NSData*)data Error:(NSError*)error withVideoData:(ADVideoData*)videoData
{
    NSString * errMsg = nil;
    id parsed = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error];
    
    if (nil == parsed)
    {
        errMsg = @"ad error";
        error = [[NSError alloc] initWithDomain:errMsg code:-1 userInfo:nil];
        return NO;
    }
    
    if (![parsed isKindOfClass:[NSDictionary class]]) return NO;
    NSDictionary *dict = (NSDictionary*)parsed;
    
    //如果错误
    if (0 == [[dict objectForKey:@"res"] intValue]) {
        errMsg = [dict objectForKey:@"mg"];
        if (nil == errMsg)
            errMsg = @"no ad to play";
        error = [[NSError alloc] initWithDomain:errMsg code:-1 userInfo:nil];
        
        AdViewLogInfo(@"Error:%@", errMsg);

        NSMutableArray *array;
        NSDictionary *agData = [dict objectForKey:@"agdata"];
        if (agData) {
            AdViewRolloverAdapterModel *model = [AdViewRolloverAdapterModel modelFromJSONDictionary:agData];
            if (model) {
                if (!array) {
                    array = [NSMutableArray array];
                }
                [array addObject:model];
            }
        }
                
        NSArray *agext = [dict objectForKey:@"agext"];
        if ([agext isKindOfClass:[NSArray class]] && agext) {
            for (NSDictionary *agdata in agext) {
                AdViewRolloverAdapterModel *model = [AdViewRolloverAdapterModel modelFromJSONDictionary:agdata];
                if (model) {
                    if (!array) {
                        array = [NSMutableArray array];
                    }
                    [array addObject:model];
                }
            }
        }
        
        if (array) {
            videoData.otherPlatArray = array;
        }

        return NO;
    }
    
    int count = [[dict objectForKey:@"ac"] intValue];
    if (count < 1) return NO;
    NSArray *adArr = (NSArray*)[dict objectForKey:@"ad"];
    if (![adArr isKindOfClass:[NSArray class]]
        || [adArr count] < 1) {
        if (nil == errMsg)
            errMsg = @"no ad to play";
        error = [[NSError alloc] initWithDomain:errMsg code:-1 userInfo:nil];
        return NO;
    }
    
    NSDictionary *dicAd = [adArr objectAtIndex:0];
    if (![dicAd isKindOfClass:[NSDictionary class]]) return NO;
    
    AdFillAdType typeStr = [[dicAd objectForKey:@"at"] intValue];
    if (typeStr != AdFillAdTypePopVideo && typeStr != AdFillAdTypeDataVideo && typeStr != AdFillAdTypeEmbedVieo)
    {
        return NO;
    }
    
    int actionType = [[dicAd objectForKey:@"act"] intValue];
    switch (actionType)
    {
        case 1:videoData.adActionType = AVAdActionType_Web; break;
        case 2:videoData.adActionType = AVAdActionType_AppStore; break;
        case 4:videoData.adActionType = AVAdActionType_Map;break;
        case 8:videoData.adActionType = AVAdActionType_Sms; break;
        case 16:videoData.adActionType = AVAdActionType_Mail;break;
        case 32:videoData.adActionType = AVAdActionType_Call; break;
        default:break;
    }
    
    // vt返回分钟数 数据存储为秒数，需要*60
    int cacheTime = [[dicAd objectForKey:@"vt"] intValue] * 60;
    // 视频缓存时间最小是30分钟
    if (cacheTime < 1800) {
        cacheTime  = 1800;
    }
    
    [AdViewCacheTimeValue sharedCacheTimeValue].cacheTimeOutValue = cacheTime;
    
    NSDictionary *dic = [dicAd objectForKey:@"video"];
    NSInteger dataType = [[dic objectForKey:@"xmltype"] integerValue];
    videoData.pbm = (AdView_PBM)[dic[@"pbm"] integerValue];

    if (dataType == 1)  // 视频vast形式解析
    {
#if DEBUG_VIDEO_FILE
        NSString *sPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"videoData.txt"];
        BOOL bExist = [self isFileExists:sPath];
        AdViewLogDebug(@"offline config path:%@, exist:%d", sPath, bExist);
        NSString *strXS = [NSString stringWithContentsOfFile:sPath encoding:NSUTF8StringEncoding error:nil];
        videoData.adBody = strXS;
#else
        videoData.adBody = [dic objectForKey:@"vastxml"];
        AdViewLogDebug(@"html body : %@",videoData.adBody);
        if ([videoData.adBody length] == 0)
        {
            AdViewLogDebug(@"error: vastxml is null");
            return NO;
        }
        
#endif
        if (error != nil)
            error = nil;
    }
    else if (dataType == 2)
    {
        // 视频原生解析
    }
    else
    {
        // 类型未知，做失败处理
        return NO;
    }
    
    return YES;
}

@end

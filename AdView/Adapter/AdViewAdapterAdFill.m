//
//  AdViewAdapterAdFill.m
//  AdViewHello
//
//  Created by AdView on 13-7-25.
//
//

#import "AdViewAdapterAdFill.h"
#import "AdViewExtTool.h"
#import "AdViewContent.h"
#import "AdViewConnection.h"
#import "AdViewView.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import "AdViewDefines.h"
#import "AdViewRolloverAdapterModel.h"

@class AdViewView;

#define SZ_Serial_Key @"67590f398bf0447931eb20fa2b63bb36"
#define SUPPORT_ADSOURCE "27" //@"27"， 256

//TO DO: 重复的URL
static const char *gAdFillMobileTestUrl[] = {
    "http://gbjtest.adview.com/agent/getAd",
    "http://gbjtest.adview.com/agent/getAd",
    "http://gbjtest.adview.com/agent/display",
    "http://gbjtest.adview.com/agent/click",
    
    "http://gbjtest.adview.com/agent/getAd",
    "http://gbjtest.adview.com/agent/getAd",
    "http://gbjtest.adview.com/agent/display",
    "http://gbjtest.adview.com/agent/click",
    
    "http://gbjtest.adview.com/agent/getAd",
    "http://gbjtest.adview.com/agent/getAd",
    "http://gbjtest.adview.com/agent/display",
    "http://gbjtest.adview.com/agent/click",
};

static const char *gAdFillMobileUrl[] = {
    "https://bid.adview.com/agent/getAd",
    "https://bid.adview.com/agent/getAd",
    "https://bid.adview.com/agent/display",
    "https://bid.adview.com/agent/click",
    
    "https://bid.adview.com/agent/getAd",
    "https://bid.adview.com/agent/getAd",
    "https://bid.adview.com/agent/display",
    "https://bid.adview.com/agent/click",
    
    "https://bid.adview.com/agent/getAd",
    "https://bid.adview.com/agent/getAd",
    "https://bid.adview.com/agent/display",
    "https://bid.adview.com/agent/click",
};

#define DisplayMetricURLFmt     @"%@agent/display"
#define ClickMetricURLFmt       @"%@agent/click"

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
    {"html5","0",1},
    {"bi","",1},
    {"an","",0},
    {"ch","",0},
    {"sv","",1},
    {"cv","0",1},
    {"av","",0},
    {"aid","",1},
    {"ap","",0},
    {"sy","1",1},           // 0-andriod  1-iOS
    {"agadn","1006",1},
    {"st","0",1},
    {"posId","",1},         //广告位id
    {"as","",1},
    {"ac","1",1},
    {"la","",0},
    {"tm","0",1},           // tm 强制为0防止开发者正式线传1导致出问题
    {"du","",0},            // is iPad or iPhone
    {"supGdtUrl","1",0},    // 开启是gdt返回的al会带有需要替换的宏
    {"hv","0",0},           // 横竖屏 默认竖屏0
    {"apt","",0},
    {"lp","",0},
    {"lat","",0},
    {"lon","",0},
    {"ci","",0},
    {"ar","",0},
    {"bty","0",1},          //电池电量
    
    {"gdpr","0",1},         //是否使用GDPR
    {"consent","0",1},      //GDPR的consentString
    {"CMPPresent","0",0},   //
    {"parsedPurposeConsents","0",0},
    {"parsedVendorConsents","0",0},
    {"us_privacy","0",0},   //加州CCPA
    
    {"dt","",0},            // model for device.
    {"db","Apple",0},       // Manufacturers of device
    {"se","",1},            // mobile/unicom/telecom
    {"nt","",0},            // wifi/2g/3g
    {"ov","",0},            // operating system（OS）version.
    {"re","",0},            // rusolution
    {"ud","",1},            // uuid
    {"nia","",1},           //normalIDFA   0=实际idfa 1=第三方生成idfa
    {"ma","",0},            // mac address,not include ":",lowercase
    {"ia","",0},
    {"iv","",0},
    {"ua","",0},
    {"jb","",0},            // jailBreak = 1, 0 is no jailBreak.
    {"src",SUPPORT_ADSOURCE,0},      // Support advertisement origin.
    {"deny","",0},
    {"lang","",0},
    {"ro","0",1},          // is SSP（1） or AdFill（0）;
    {"ti","",1},
    {"to","",1},           // md5 of bundleId+appId+adSize+uuid+time
};

#define ADFILL_IOS @"d6lkmmxao3habycd626ijoafz85bkixk"
#define ADVIEWBID_IOS @"dur75pt6jlyim2910rroamiyv54qszuk"
#define ADVIEWRTB_IOS @"6xri90l1of1yv3plf4iuce1vo8kf3fgy"

@implementation AdViewAdapterAdFill
@synthesize reportHost;

- (id)init
{
	if (self = [super init])
    {
		[self initInfo];
	}
	return self;
}

- (void)dealloc {
	self.infoDict = nil;
    self.reportHost = nil;
}

- (NSString *)URLEncodedString:(NSString*)str
{
    NSString *encodedString = (NSString *)
    CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                            (CFStringRef)str,
                                            (CFStringRef)@"!$&'()*+,-./:;=?@_~%#[]",
                                            NULL,
                                            kCFStringEncodingUTF8));
    return encodedString;
}

- (BOOL)isJailbroken {
    BOOL jailbroken = NO;
    NSString *cydiaPath = @"/Applications/Cydia.app";
    NSString *aptPath = @"/private/var/lib/apt/";
    if ([[NSFileManager defaultManager] fileExistsAtPath:cydiaPath]) {
        jailbroken = YES;
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:aptPath]) {
        jailbroken = YES;
    }
    return jailbroken;
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

//初始化一些系统参数
- (void)initInfo
{
    if (nil == _infoDict)
    {
		_infoDict = [[NSMutableDictionary alloc] init];
	}
	
    //使用默认值初始化infoDict
	for (int i = 0; i < SZITEM_ARRSIZE(gGetItems); i++)
	{
		[_infoDict setObject:[NSString stringWithUTF8String:gGetItems[i].defVal]
					 forKey:[NSString stringWithUTF8String:gGetItems[i].idStr]];
	}
    
    NSString *bundle = [[NSBundle mainBundle] bundleIdentifier];
    
    [_infoDict setObject:bundle forKey:@"bi"];
    
    NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    if (nil == appName || [appName length] == 0) {
        appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey];
    }
    appName = [self URLEncodedString:appName];
    if(nil == appName)
        appName = @"";
    [_infoDict setObject:appName forKey:@"an"];
    
    NSString *appVer = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    if (nil == appVer) {
        appVer = @"unknown";
    }
    [_infoDict setObject:appVer forKey:@"av"];

    [_infoDict setObject:ADVIEWSDK_VERSION forKey:@"sv"];
    
    NSString* deviceType = [[AdViewExtTool sharedTool] iphoneType]; //获取手机型号
    [_infoDict setObject:[self URLEncodedString:deviceType] forKey:@"dt"];
    
    //获取电量
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    float battery = ([[UIDevice currentDevice] batteryLevel])*100;
    [_infoDict setObject:[NSString stringWithFormat:@"%d",(int)battery] forKey:@"bty"];
    
    NSString *jailBreak = [NSString stringWithFormat:@"%d",[self isJailbroken]];
    [_infoDict setObject:jailBreak forKey:@"jb"];
    
    NSString *service = [AdViewExtTool serviceProviderCode];
    [_infoDict setObject:service forKey:@"se"];
    
    [_infoDict setObject:[NSString stringWithFormat:@"%d",[AdViewExtTool getDeviceIsIpad]] forKey:@"du"];
    
    [_infoDict setObject:[AdViewExtTool getIDA] forKey:@"ia"];
    [_infoDict setObject:[AdViewExtTool getIDFV] forKey:@"iv"];
    
    [_infoDict setObject:[self URLEncodedString:[AdViewExtTool sharedTool].userAgent] forKey:@"ua"];

    
    NSString *macStr = [[[AdViewExtTool sharedTool] getMacAddress:MacAddrFmtType_Default] lowercaseString];
    [_infoDict setObject:[AdViewExtTool encodeToPercentEscapeString:macStr] forKey:@"ma"];
    
    [_infoDict setObject:[[UIDevice currentDevice] systemVersion] forKey:@"ov"];
    
    NSString * uuid = macStr;
    //if ios >= 7.0, get the idfa as udid
    NSString *sysVersion = [[UIDevice currentDevice] systemVersion];
    float sysVer = [sysVersion floatValue];
    if (sysVer >= 7.0f) {
        uuid = [AdViewExtTool getIDA];
    }

    //ios10限制广告追踪
    if ([uuid isEqual:@"00000000-0000-0000-0000-000000000000"])
    {
        uuid = [[UIDevice currentDevice] getAdViewIDFA];
        NSLog(@"%@",uuid);
        [_infoDict setObject:@"1" forKey:@"nia"];
    }
    
    [_infoDict setObject:uuid forKey:@"ud"];
    [[AdViewExtTool sharedTool] storeObject:uuid forKey:@"{UUID}"]; 
    
    [_infoDict setObject:[NSString stringWithFormat:@"%.2f",[UIScreen mainScreen].scale] forKey:@"deny"];
    
    [_infoDict setObject:[[[NSLocale preferredLanguages] firstObject] componentsSeparatedByString:@"-"][0] forKey:@"lang"];
}

//根据condition设置其他需要传递参数
- (void)setAdCondition:(AdViewAdCondition*)condition
{
    self.appId = condition.appId;
    self.adType = condition.adverType;
    self.adTestMode = condition.adTest;
    
    [_infoDict setObject:[NSString stringWithFormat:@"%zd", self.adType] forKey:@"st"];
    [_infoDict setObject:[NSString stringWithFormat:@"%d",self.adTestMode] forKey:@"tm"];
    
    NSMutableString * agadnString = [NSMutableString new];
    NSDictionary * classDictionary = nil;
    switch (self.adType)
    {
        case AdViewBanner:
        {
            classDictionary = @{@"GDTMobBannerView":@"1006",@"BaiduMobAdView":@"1007",@"WMBannerAdView":@"1008"};
        }
            break;
        case AdViewInterstitial:
        {
            classDictionary = @{@"GDTMobInterstitial":@"1006",@"BaiduMobAdInterstitial":@"1007",@"WMInterstitialAd":@"1008"};
        }
            break;
        case AdViewSpread:
        {
            classDictionary = @{@"GDTSplashAd":@"1006",@"BaiduMobAdSplash":@"1007",@"WMSplashAdView":@"1008"};
        }
            break;
        case AdViewNative:
        {
            classDictionary = @{@"GDTNativeAd":@"1006",@"BaiduMobAdNative":@"1007"};
        }
            break;
        default:
            break;
    }
    
    //拼接支持的打底
    for (NSString * classNameString in classDictionary.allKeys) {
        Class class = NSClassFromString(classNameString);
        if (class) {
            [agadnString appendString:[classDictionary objectForKey:classNameString]];
            [agadnString appendString:@","];
        }
    }
    if (agadnString.length) {
        [agadnString deleteCharactersInRange:NSMakeRange(agadnString.length - 1, 1)];
    }
    [_infoDict setObject:agadnString forKey:@"agadn"];

#if DEBUG_XS_FILE
    [_infoDict setObject:@"1" forKey:@"html5"];
#else
    if (condition.bUseHtml5) {
        [_infoDict setObject:@"1" forKey:@"html5"];
    }
#endif
    NSString *netType = [self checkNetworkType];
    if (nil == netType) {
        netType = @"other";
    }
    
    [_infoDict setObject:netType forKey:@"nt"];
    
    BOOL isPortrait = UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation);
    [_infoDict setObject:[NSString stringWithFormat:@"%d",isPortrait] forKey:@"hv"];
    

    NSString *time = [NSString stringWithFormat:@"%ld",(long)[[NSDate date] timeIntervalSince1970]];
    [_infoDict setObject:time forKey:@"ti"];
    
    if (self.adPlatType == AdViewAdPlatTypeAdview)
        [_infoDict setObject:@"1" forKey:@"ro"];
    else if (self.adPlatType == AdViewAdPlatTypeAdfill)
        [_infoDict setObject:@"0" forKey:@"ro"];
    else if (self.adPlatType == AdViewAdPlatTypeAdviewRTB)
        [_infoDict setObject:@"2" forKey:@"ro"];
    
    urlNumber = [[_infoDict objectForKey:@"ro"] intValue] * 4;
    
    [_infoDict setObject:@SUPPORT_ADSOURCE forKey:@"src"];
    
    //ua
	NSString *uaStr = [AdViewExtTool encodeToPercentEscapeString:
					   [[AdViewExtTool sharedTool] userAgent]];
	[_infoDict setObject:uaStr forKey:@"ua"];
    
    //内涵问题
    if (nil != condition.appId) {
        [_infoDict setObject:condition.appId forKey:@"aid"];
    }
    
    if (nil != condition.positionId) {
        [_infoDict setObject:condition.positionId forKey:@"posId"];
    }
    
    //此处强制输出SDK版本号和appid
    AdViewLogInfo(@"AdViewSDKVersion:%@-----AdViewKey:%@", ADVIEWSDK_VERSION, condition.appId);
    int density = [AdViewExtTool getDensity];
    int width = (int)condition.adSize.width;
    int height = (int)condition.adSize.height;
    
    if (condition.adverType == AdViewBanner) {
        width = (int)condition.adSize.width * density;
        height = (int)condition.adSize.height * density;
    } else if (condition.adverType == AdViewInterstitial) {
        width = 320 * density;
        height = 480 * density;
        if ([AdViewExtTool getDeviceIsIpad]) {
            width = 768 * density;
            height = 1024 * density;
        }
    } else if (condition.adverType == AdViewNative) {
        [_infoDict setObject:[NSString stringWithFormat:@"%d",condition.adCount] forKey:@"ac"];
        [_infoDict removeObjectForKey:@"tm"];
    }
    
    [_infoDict setObject:[NSString stringWithFormat:@"%dX%d", width, height] forKey:@"as"];
	if (condition.hasLocationVal)
    {
        NSString *latVal = [NSString stringWithFormat:@"%f", condition.latitude];
        NSString *lngVal = [NSString stringWithFormat:@"%f", condition.longitude];
        [_infoDict setObject:latVal forKey:@"lat"];
        [_infoDict setObject:lngVal forKey:@"lon"];
    }
        
    //GDPR
    [_infoDict setObject:[NSString stringWithFormat:@"%d",condition.gdprApplicability] forKey:AdView_IABConsent_SubjectToGDPR];
    if (condition.consentString && condition.consentString.length) {
        [_infoDict setObject:condition.consentString forKey:AdView_IABConsent_ConsentString];
    } else {
        [_infoDict setObject:@"0" forKey:AdView_IABConsent_ConsentString];
    }
    [_infoDict setObject:[NSString stringWithFormat:@"%d",condition.CMPPresent] forKey:AdView_IABConsent_CMPPresent];
    
    if (condition.parsedPurposeConsents) {
        [_infoDict setObject:condition.parsedPurposeConsents forKey:AdView_IABConsent_ParsedPurposeConsents];
    }
    
    if (condition.parsedVendorConsents) {
        [_infoDict setObject:condition.parsedVendorConsents forKey:AdView_IABConsent_ParsedVendorConsents];
    }
    
    //CCPA
    if (condition.CCPAString) {
        [_infoDict setObject:condition.CCPAString forKey:AdView_IABConsent_CCPA];
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
    CGFloat scale = [[_infoDict valueForKey:@"deny"] floatValue];
    [_infoDict setObject:[NSString stringWithFormat:@"%dX%d",(int)(screenWidth * scale),(int)(screenHeight * scale)] forKey:@"re"];
    
    NSString *cngVer = [NSString stringWithFormat:@"%d",self.configVer];
    [_infoDict setObject:cngVer forKey:@"cv"];
    //token
    NSString *bundle = [_infoDict objectForKey:@"bi"];
    NSString *appId = [_infoDict objectForKey:@"aid"];
    NSString *adSize = [_infoDict objectForKey:@"as"];
    NSString *uuid = [_infoDict objectForKey:@"ud"];
    
    NSString *key;
    int keyInt = [[_infoDict objectForKey:@"ro"]intValue];
    switch (keyInt)
    {
        case 0:
            key = ADFILL_IOS;
            break;
        case 1:
            key = ADVIEWBID_IOS;
            break;
        case 2:
            key = ADVIEWRTB_IOS;
            break;
        default:
            break;
    }
    NSString *token = [AdViewExtTool getMd5HexString:[NSString stringWithFormat:@"%@%@%@%@%@%@",bundle,appId,adSize,uuid,time,key]];
    [_infoDict setObject:token forKey:@"to"];
}

//字典转key-value字符串
- (void)linkMutableString:(NSMutableString*)str
				  Pointer:(const SZRequestItem*)pItems
				   Length:(int)len {
	for (int i = 0; i < len; i++) {
		NSString *key0 = [NSString stringWithUTF8String:pItems[i].idStr];
		NSString *val0 = [_infoDict objectForKey:key0];
        
        if (nil == val0 || [val0 length] < 1) continue;
		if (i > 0) [str appendString:@"&"];
		[str appendFormat:@"%@=%@", key0, val0];
	}
}

//获取服务器地址,测试、正式 + URL参数拼接
- (NSString*)getVisitUrl:(SZGetType)type {
	const char * cStr = self.useTestServer ? gAdFillMobileTestUrl[type + urlNumber] : gAdFillMobileUrl[type + urlNumber];
	
	NSMutableString * urlStr = [NSMutableString stringWithUTF8String:cStr];
	[urlStr appendString:@"?"];
    
	[self linkMutableString:urlStr
                    Pointer:gGetItems
					 Length:SZITEM_ARRSIZE(gGetItems)];
	return urlStr;
}

- (void)setURLRequestHeaders:(NSMutableURLRequest*)request Type:(SZGetType)type
{
    
}

//重置部分数据（主要针对banner，因为banner中adapter一直存在会有部分数据缓存导致下次请求出现误差甚至错误）
- (void)resetSomeData {
    self.bIgnoreClickRequest = NO;
    self.bIgnoreShowRequest = NO;
}

//生成request
- (NSMutableURLRequest*)getAdVisitRequest:(SZGetType)type {
	NSString * urlStr = [self getVisitUrl:type];
	
	AdViewLogDebug(@"AdFill Url %d:%@", type, urlStr);
    //	[AdViewExtTool writeTheLogWithWho:[[infoDict objectForKey:@"ro"] intValue]?@"BID":@"AdFIll" Source:@"unknown" AdId:@"unknown" Type:@"request"];
	NSURL * url = [NSURL URLWithString:urlStr];
	NSMutableURLRequest * req = [NSMutableURLRequest requestWithURL:url];
    if (self.adType == AdViewSpread) req.timeoutInterval = 3;
    [req setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
	[self setURLRequestHeaders:req Type:type];
	req.HTTPMethod = @"GET";

	return req;
}

- (NSMutableURLRequest*)getAdGetRequest:(AdViewAdCondition *)condition
{
    //重置部分数据（主要针对banner，因为banner中adapter一直存在会有部分数据缓存导致下次请求出现误差甚至错误）
    [self resetSomeData];
	[self setAdCondition:condition];
    
    //⚠️ 是否使用测试服务器 需要在demo的设置 - 测试服务器 - 打开 这里算是个后门.之前遗留的,我不改了防止有问题 - unakayou
    BOOL useTestServer = [[[NSUserDefaults standardUserDefaults] objectForKey:USE_TEST_SERVER_KEY] boolValue];
    self.useTestServer = useTestServer;
	return [self getAdVisitRequest:SZGetType_Get];
}

+ (NSMutableURLRequest*)utilGetRequest:(NSString*)urlStr
{
    if (nil == urlStr) return nil;
    NSURL* url = [NSURL URLWithString:urlStr];
    return [NSMutableURLRequest requestWithURL:url];
}

- (NSString*)getDisplayBaseUrlStringAdContent:(AdViewContent*)AdContent
{
    AdViewLogDebug(@"Host: %@",self.reportHost);
    AdViewLogDebug(@"content host: %@",AdContent.hostURL);
	if (nil != AdContent.hostURL)
    {
		NSString *str = [NSString stringWithFormat:DisplayMetricURLFmt, AdContent.hostURL];
		return str;
	}
	return [NSMutableString stringWithUTF8String:self.useTestServer ?
            gAdFillMobileTestUrl[SZGetType_Display + urlNumber] : gAdFillMobileUrl[SZGetType_Display + urlNumber]];
}

- (NSString*)getClickBaseUrlStringAdContent:(AdViewContent*)AdContent{
    AdViewLogDebug(@"Host: %@",self.reportHost);
    AdViewLogDebug(@"content host: %@",AdContent.hostURL);
    if (nil != AdContent.hostURL) {
        NSString *str = [NSString stringWithFormat:ClickMetricURLFmt,AdContent.hostURL];
        return str;
    }
    return [NSMutableString stringWithUTF8String:self.useTestServer ? gAdFillMobileTestUrl[SZGetType_Click + urlNumber] : gAdFillMobileUrl[SZGetType_Click + urlNumber]];
}
//resuse 纠错
- (void)correctionTheUrlStringWithAdContent:(AdViewContent*)theAdContent {
    
    NSString *adi = theAdContent.adId;
    if (nil != adi && [adi length] > 1) {
        [_infoDict setObject:theAdContent.adId forKey:@"adi"];
    }
    
    NSString *ai = theAdContent.adInfo;
    if (nil != ai || [ai length] > 1) {
        [_infoDict setObject:theAdContent.adInfo forKey:@"ai"];
    }
    
    [_infoDict setObject:[NSString stringWithFormat:@"%d",theAdContent.src] forKey:@"src"];
}

//展示和点击请求
- (NSMutableURLRequest*)getAdReportRequest:(BOOL)bClickOtherDisplay AdContent:(AdViewContent*)theAdContent
{
    NSURL *url;
    [self correctionTheUrlStringWithAdContent:theAdContent];
    
    NSString *requestStr = @"";
    if (bClickOtherDisplay)
    {
        requestStr =  [[AdViewExtTool sharedTool] replaceDefineString:self.clickUrlStr];
        url = [NSURL URLWithString:[self getClickBaseUrlStringAdContent:theAdContent]];
    }
    else
    {
        requestStr = [[AdViewExtTool sharedTool] replaceDefineString:self.showUrlStr];
        url = [NSURL URLWithString:[self getDisplayBaseUrlStringAdContent:theAdContent]];
    }
    
    NSRange hostRange = [requestStr rangeOfString:@"?"];
    if (hostRange.length > 0) {
        requestStr = [requestStr substringFromIndex:(hostRange.location+1)];
    }
    
    AdViewLogDebug(@"点击/展示网址后面跟的:%@",requestStr);
    NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];
    NSData* postData = [requestStr dataUsingEncoding:NSUTF8StringEncoding];
    NSString* postLen = [NSString stringWithFormat:@"%ld", (long)[postData length]];
    req.HTTPMethod = @"POST";
    req.HTTPBody = postData;
    [req setValue: postLen forHTTPHeaderField: @"Content-Length"];
    [req setValue: @"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];

    AdViewLogDebug(@"RptRequest is : \"%@\"", req);
	return req;
}

- (BOOL)useInternalParser {
	return NO;
}

- (void)deleteNilObjectWithDict:(id)object {
    if ([object isKindOfClass:[NSDictionary class]]) {
        for (NSString *key in [object allKeys]) {
            id obj = [object objectForKey:key];
            if (!obj) {
                [object removeObject:obj];
            }
        }
    }else if([object isKindOfClass:[NSArray class]]) {
        for (id obj in object) {
            [self deleteNilObjectWithDict:obj];
        }
    }
}

#pragma mark - parse help function
- (void)setColorSchemes:(AdViewContent*)adContent withColorArray:(NSArray*)colorArray
{
    if (![colorArray isKindOfClass:[NSArray class]] || [colorArray count] == 0) {
        return;
    }
    id colorDict = [colorArray firstObject];
    if ([colorDict isKindOfClass:[NSDictionary class]] && [colorDict count] > 0) {
        
        for (NSString *key in [colorDict allKeys]) {
            if ([key isKindOfClass:[NSString class]]) {
                id value = [colorDict objectForKey:key];
                if ([value isKindOfClass:[NSString class]] && [(NSString*)value length] > 0) {
                    [adContent.colorBG setValue:value forKey:key];
                }
            }
        }
    }
}

// string转CGRect
- (CGRect)makeRectWithString:(NSString*)rectStr {
    CGRect rect = CGRectMake(0, 0, 1000, 1000);
    if (nil == rectStr || [rectStr length] == 0) return rect;
    
    rectStr = [rectStr stringByReplacingOccurrencesOfString:@"(" withString:@""];
    rectStr = [rectStr stringByReplacingOccurrencesOfString:@")" withString:@""];
    NSArray *rectArr = [rectStr componentsSeparatedByString:@","];
    if ([rectArr count]) {
        rect = CGRectMake([[rectArr objectAtIndex:0] floatValue],
                          [[rectArr objectAtIndex:1] floatValue],
                          [[rectArr objectAtIndex:2] floatValue],
                          [[rectArr objectAtIndex:3] floatValue]);
    }
    
    return rect;
}

//获取AdView汇报链接，如果没有则挂起为YES，如果有取出链接字符串并处理相应的字典或者数组（处理：去除里面的AdView链接，防止汇报多次）
- (id)takeShowOrClickUrlString:(id)object {
    if (object == nil) return nil;
    if ([object isKindOfClass:[NSDictionary class]]) {
        for (NSString *key in [(NSDictionary*)object allKeys]) {
            id urlArr = [(NSDictionary*)object objectForKey:key];
            if (urlArr && [urlArr isKindOfClass:[NSArray class]] ) {
                for (NSString *urlStr in urlArr) {
                    if (urlStr && [urlStr rangeOfString:self.reportHost].length > 0) {
                        self.showUrlStr = urlStr;
                        NSUInteger index = [urlArr indexOfObject:urlStr];
                        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:object];
                        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL (id evaluatedObject, NSDictionary *bindings) {
                            NSString *str = evaluatedObject;
                            return [urlArr indexOfObject:str] != index;
                        }];
                        NSArray *arr = [urlArr filteredArrayUsingPredicate:predicate];
                        [dict setObject:arr forKey:key];
                        return dict;
                    }
                }
            }
        }
        self.bIgnoreShowRequest = YES;
        if ([object allKeys].count <= 0) return  nil;
        
    }else if ([object isKindOfClass:[NSArray class]]) {
        for (NSString *clickUrlStr in object) {
            if (clickUrlStr && [clickUrlStr rangeOfString:self.reportHost].length > 0) {
                self.clickUrlStr = clickUrlStr;
                NSUInteger index = [object indexOfObject:clickUrlStr];
                NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
                    NSString *str = evaluatedObject;
                    return [object indexOfObject:str] != index;
                }];
                
                return [object filteredArrayUsingPredicate:predicate];
            }
        }
        
        self.bIgnoreClickRequest = YES;
        if (((NSArray*)object).count <= 0) {
            return nil;
        }
    }
    return object;
}

- (NSString*)stringAppending:(NSString*)stringOne and:(NSString*)stringTwo {
    NSString *temp = @"";
    if (nil != stringOne) {
        temp = [temp stringByAppendingString:stringOne];
    }
    
    if (nil != stringTwo) {
        temp = [temp stringByAppendingString:stringTwo];
    }
    return temp;
}

// 判断字符串是否为数字
- (BOOL)isNum:(NSString *)checkedNumString {
    checkedNumString = [checkedNumString stringByTrimmingCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]];
    if(checkedNumString.length > 0) {
        return NO;
    }
    return YES;
}

// 获取html广告正常需要的尺寸(处理as字段)
- (void)getAdSizeValueWithSize:(NSString*)sizeString content:(AdViewContent*)theContent
{
    if (sizeString && [sizeString length] > 0)
    {
        // 防止返回的字符串为大写
        sizeString = [sizeString lowercaseString];
        NSArray *array = [sizeString componentsSeparatedByString:@"x"];
        if ([array count] == 2)
        {
            // 判断两个字符串是否都为数字
            BOOL isNormal = [self isNum:[array firstObject]] && [self isNum:[array lastObject]];
            if (isNormal)
            {
                CGFloat width = [[array firstObject] floatValue];
                CGFloat height = [[array lastObject] floatValue];
                CGSize size = [UIScreen mainScreen].bounds.size;
                if (width > 0 && height > 0)
                {
                    // 如果超出屏幕尺寸大小就按照分辨率处理一下
                    if (width > size.width || height > size.height)
                    {
                        CGFloat scale = [UIScreen mainScreen].scale;
                        width /= scale;
                        height /= scale;
                    }
                    // 处理过后的尺寸如果还大于屏幕尺寸，则判定异常走默认尺寸
                    if (width <= size.width && height <= size.height)
                    {
                        theContent.adWidth = width;
                        theContent.adHeight = height;
                        return;
                    }
                }
            }
        }
    }
    
    //只有Banner、开屏、插屏有默认尺寸
    switch (self.adType)
    {
        case AdViewSpread:
        {
            theContent.adWidth = 320;
            theContent.adHeight = 480;
        }
            break;
        case AdViewBanner:
        {
            theContent.adWidth = 320;
            theContent.adHeight = 50;
        }
            break;
        case AdViewInterstitial:
        {
            theContent.adWidth = 300;
            theContent.adHeight = 300;
        }
            break;
        default:
            break;
    }
}

#pragma mark - parse function
// 解析video字段
- (BOOL)parseVideoWithDict:(NSDictionary*)adDict withContent:(AdViewContent*)adContent
{
    if (!adDict || ![adDict isKindOfClass:[NSDictionary class]])
    {
        return NO;
    }
    
    NSInteger dataType = [[adDict objectForKey:@"xmltype"] integerValue];

    if (self.adType == AdViewNative)
    {
        if (dataType == 1) {return NO;} // 原生只按照素材格式返回/元素组合
        [self deleteNilObjectWithDict:adDict];
    }
    else
    {
        if (dataType == 1)
        {
            // 视频vast形式解析
#if DEBUG_VIDEO_FILE
            NSString *sPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"videoData.txt"];
            BOOL bExist = [self isFileExists:sPath];
            AdViewLogDebug(@"offline config path:%@, exist:%d", sPath, bExist);
            NSString *strXS = [NSString stringWithContentsOfFile:sPath encoding:NSUTF8StringEncoding error:nil];
            adContent.adBody = strXS;
#else
            NSString *xmlString = [adDict objectForKey:@"vastxml"];
            if (!xmlString || xmlString.length <= 0) {
                return NO;
            }
            adContent.adBody = xmlString;
#endif
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
    }
    return YES;
}

// 解析原生native字段
- (BOOL)parseNativeAdWithDict:(NSDictionary*)adDict withContent:(AdViewContent*)adContent {
    if (!adDict || ![adDict isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    
    [self deleteNilObjectWithDict:adDict];
    
    NSMutableDictionary *newDict = [NSMutableDictionary dictionary];
    for (NSString *key in [adDict allKeys]) {
        if ([key isEqualToString:@"icon"]) {
            NSString *url = [[adDict objectForKey:key] objectForKey:@"url"];
            if (nil != url && url.length) {
                [newDict setObject:url forKey:@"iconUrlString"];
            }
        } else if ([key isEqualToString:@"images"]) {
            NSArray *imageArr = [adDict objectForKey:key];
            if (imageArr && imageArr.count) {
                NSMutableArray *newArr = [NSMutableArray array];
                for (NSDictionary *dict in imageArr) {
                    NSString *url = [dict objectForKey:@"url"];
                    if (nil != url) {
                        [newArr addObject:url];
                    }
                }
                if (newArr.count) {
                    [newDict setObject:newArr forKey:@"imageList"];
                }
            }
        } else {
            [newDict setObject:[adDict objectForKey:key] forKey:key];
        }
    }
    
    if (adContent.adLogoURLStr.length > 0) {
        [newDict setObject:adContent.adLogoURLStr forKey:@"adLogo"];
    }
    
    if (adContent.adIconUrlStr.length > 0) {
        [newDict setObject:adContent.adIconUrlStr forKey:@"adIcon"];
    }
    
    adContent.nativeDict = newDict;
    return YES;
}

//根据at字段获取相应广告素材
- (BOOL)getAdSourceWithDict:(NSDictionary*)dicAd adContent:(AdViewContent*)adContent
{
    if (self.adType == AdViewNative) {
        [self parseNativeAdWithDict:[dicAd objectForKey:@"native"] withContent:adContent];
        adContent.fallBack = [dicAd objectForKey:@"fallback"];
        self.bIgnoreClickRequest = NO; //原生不受该变量影响
        self.bIgnoreShowRequest  = NO;
    } else {
        adContent.adBgColor = [dicAd objectForKey:@"abc"];
        adContent.adTextColor = [dicAd objectForKey:@"atc"];
        
        AdViewAdSHowType nAdViewShowType = AdViewAdSHowType_Text;
        AdFillAdType typeStr = [[dicAd objectForKey:@"at"] intValue];
#warning see here 枚举转换
        switch (typeStr)
        {
            case AdFillAdTypeBannerPic:
            {
                NSString *baseUrl = [dicAd objectForKey:@"giu"];
                for (int i = 0; i < [[dicAd objectForKey:@"api"] count]; i++)
                {
                    NSString *imgUrl1 = (NSString*)[[dicAd objectForKey:@"api"] objectAtIndex:i];
                    imgUrl1 = [self stringAppending:baseUrl and:imgUrl1];
                    [adContent setAdImage:i Url:imgUrl1 Append:NO];
                }
                nAdViewShowType = AdViewAdSHowType_FullImage;
            }
                break;
            case AdFillAdTypeBannerWords://主标题副标题图文
            {
                adContent.adText = [dicAd objectForKey:@"ati"];
                adContent.adSubText = [dicAd objectForKey:@"ast"];
                
                NSString *baseUrl = [dicAd objectForKey:@"giu"];
                NSString *iconUrl = [dicAd objectForKey:@"aic"];
                iconUrl = [self stringAppending:baseUrl and:iconUrl];
                [adContent setAdImage:0 Url:iconUrl Append:NO];
                
                adContent.adActImgURL = [self stringAppending:[dicAd objectForKey:@"giu"] and:[dicAd objectForKey:@"abi"]];
                
                [self setColorSchemes:adContent withColorArray:[dicAd objectForKey:@"aca"]];
                
                nAdViewShowType = AdViewAdSHowType_AdFillImageText;
            }
                break;
            case AdFillAdTypeBannerPicWords://一段文字图文
            {
                NSString *baseUrl = [dicAd objectForKey:@"giu"];
                NSString *iconUrl = [dicAd objectForKey:@"aic"];
                iconUrl = [self stringAppending:baseUrl and:iconUrl];
                [adContent setAdImage:0 Url:iconUrl Append:NO];
                [adContent setAdText:[dicAd objectForKey:@"ate"]];
                [self setColorSchemes:adContent withColorArray:[dicAd objectForKey:@"aca"]];
                
                if (self.adType != AdViewBanner)
                {
                    adContent.adSubText = [dicAd objectForKey:@"ast"];
                    adContent.adTitle = [dicAd objectForKey:@"ati"];
                }
                nAdViewShowType = AdViewAdSHowType_AdFillImageText;
            }
                break;
            case AdFillAdTypeInstl://插屏
            {
                int adInstlType = [[dicAd objectForKey:@"ait"] intValue];
                /*单纯图片*/
                if (adInstlType == 0)
                {
                    NSString *baseUrl = [dicAd objectForKey:@"giu"];
                    for (int i = 0; i < [[dicAd objectForKey:@"api"] count]; i++)
                    {
                        NSString *imgUrl1 = (NSString*)[[dicAd objectForKey:@"api"] objectAtIndex:i];
                        imgUrl1 = [self stringAppending:baseUrl and:imgUrl1];
                        [adContent setAdImage:i Url:imgUrl1 Append:NO];
                    }
                    nAdViewShowType = AdViewAdSHowType_FullImage;
                }
                else if (adInstlType ==1)   /*富媒体*/
                {
                    NSString *baseUrl = [dicAd objectForKey:@"giu"];
                    NSString *iconUrl = [dicAd objectForKey:@"aic"];
                    iconUrl = [self stringAppending:baseUrl and:iconUrl];
                    [adContent setAdImage:0 Url:iconUrl Append:NO];
                    
                    adContent.adText = [dicAd objectForKey:@"ate"];
                    nAdViewShowType = AdViewAdSHowType_AdFillImageText;
                }
                else if (adInstlType == 2)
                {
                    BOOL videoIsOk = [self parseVideoWithDict:[dicAd objectForKey:@"video"] withContent:adContent];
                    if (!videoIsOk)
                    {
                        AdViewLogDebug(@"error: video object is unusual");
                        return NO;
                    }
                    nAdViewShowType = AdViewAdSHowType_Video;
                }
                break;
            }
            case AdFillAdTypeHTML: //html
            {
                nAdViewShowType = AdViewAdSHowType_WebView_Content;
                [AdViewExtTool sharedTool].protocolCount++; //html汇报的时候需要用到protocolCount计数加1；
                
                if ([AdViewExtTool sharedTool].replaceXSFuction)
                {
                    NSString *sPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"test_xs.txt"];
                    BOOL bExist = [self isFileExists:sPath];
                    if (!bExist)
                    {
                        sPath = [[[NSBundle mainBundle] bundlePath]stringByAppendingPathComponent:@"test_xs.txt"];
                        bExist = [self isFileExists:sPath];
                    }

                    AdViewLogDebug(@"offline config path:%@, exist:%d", sPath, bExist);
                    NSString *strXS = [NSString stringWithContentsOfFile:sPath encoding:NSUTF8StringEncoding error:nil];
                    adContent.adBody = strXS;
                }
                else
                {
#if DEBUG_XS_FILE       //DEBUG
                    NSString *sPath = [[[NSBundle mainBundle] bundlePath]
                                       stringByAppendingPathComponent:@"xs.txt"];
                    BOOL bExist = [self isFileExists:sPath];
                    NSLog(@"offline config path:%@, exist:%d", sPath, bExist);
                    NSString *strXS = [NSString stringWithContentsOfFile:sPath encoding:NSUTF8StringEncoding error:nil];
                    adContent.adBody = strXS;
#else
                    adContent.adBody = [dicAd objectForKey:@"xs"];
                    if ([adContent.adBody length] == 0)
                    {
                        AdViewLogDebug(@"error: xs is null");
                        return NO;
                    }
#endif
                }
                NSString *adSize = [dicAd objectForKey:@"as"];
                [self getAdSizeValueWithSize:adSize content:adContent];
            }
                break;
            case AdFillAdTypeSpread:
            {
                NSString *baseUrl = [dicAd objectForKey:@"giu"];
                
                for (int i = 0; i < [[dicAd objectForKey:@"api"] count]; i++)
                {
                    NSString *imgUrl1 = [baseUrl stringByAppendingFormat:@"%@",[[dicAd objectForKey:@"api"] objectAtIndex:i]];
                    [adContent setAdImage:i Url:imgUrl1 Append:NO];
                    
                }
                adContent.adText = [dicAd objectForKey:@"ati"];
                adContent.adSubText = [dicAd objectForKey:@"ast"];
                nAdViewShowType = AdViewAdSHowType_FullImage;
            }
                break;
            case AdFillAdTypePopVideo:
            case AdFillAdTypeDataVideo:
            case AdFillAdTypeEmbedVieo:
            {
                BOOL videoIsOk = [self parseVideoWithDict:[dicAd objectForKey:@"video"] withContent:adContent];
                if (!videoIsOk)
                {
                    AdViewLogDebug(@"error: video object is unusual");
                    return NO;
                }
                nAdViewShowType = AdViewAdSHowType_Video;
            }
                break;
            default:
                break;
        }
        adContent.adShowType = nAdViewShowType;
    }
    return YES;
}

//解析每条广告数据
- (BOOL)parseAdFieldWithDict:(NSDictionary*)dicAd adContent:(AdViewContent*)adContent
{
    if (![dicAd isKindOfClass:[NSDictionary class]]) return NO;
    
    id number = [dicAd objectForKey:@"cnl"];
    if (number && ([number isKindOfClass:[NSNumber class]] || [number isKindOfClass:[NSString class]])) {
        if ([number intValue] > 0 && [number intValue] <= 10)
            adContent.maxClickNum = [number intValue]; //单条广告点击次数上限
    }else{
        adContent.maxClickNum = 2;
    }
    
    NSString *host = [dicAd objectForKey:@"su"];
    if (![host hasSuffix:@"/"])
        host = [NSString stringWithFormat:@"%@/",host];
    self.reportHost = host;
    adContent.hostURL = host;
    
    if ([host rangeOfString:@"adview.com"].length <= 0) {
        [[AdViewExtTool sharedTool] storeObject:host forKey:@"AdViewHost"];
    }
    
    //错误汇报既定内容
    id eqs = [dicAd objectForKey:@"eqs"];
    if (eqs && [eqs isKindOfClass:[NSString class]])
        adContent.errorReportQuery = eqs;
    
    id ml = [dicAd objectForKey:@"ml"];
    if (ml && [ml isKindOfClass:[NSArray class]])
        [AdViewCheckTool sharedTool].matchLanding = ml;
    
    /*mon 字段*/
    NSArray *monArray = [dicAd objectForKey:@"mon"];
    if (monArray && [monArray isKindOfClass:[NSArray class]] && [monArray count] >= 2) {
        NSDictionary *monDisplay = [monArray objectAtIndex:0];
        NSDictionary *monClick = [monArray objectAtIndex:1];
        adContent.monSstring  = [monDisplay objectForKey:@"s"];
        adContent.monCstring  = [monClick objectForKey:@"c"];
    }else{
        adContent.monCstring = nil;
        adContent.monSstring = nil;
    }
    /**/
    
    // es ec 字段处理
    id exShowDict = [dicAd objectForKey:@"es"];
    exShowDict = [self takeShowOrClickUrlString:exShowDict];            //这里筛掉了第一个链接(一般第一个链接就是Adview的)
    if (exShowDict && [exShowDict isKindOfClass:[NSDictionary class]])
        adContent.extendShowUrl = exShowDict;
    else
        self.bIgnoreShowRequest = YES;
    
    id exClickArr = [dicAd objectForKey:@"ec"];
    exClickArr = [self takeShowOrClickUrlString:exClickArr];
    if (exClickArr && [exClickArr isKindOfClass:[NSArray class]]) {
        adContent.extendClickUrl = exClickArr;
    }else {
        self.bIgnoreClickRequest = YES;
    }
    
    // 如果是开屏，解析某些需要的字段
    if(self.adType == AdViewSpread) {
        NSString *rectStr = [dicAd objectForKey:@"pta"];
        adContent.clickSize = [self makeRectWithString:rectStr];
        adContent.relayTime = [[dicAd objectForKey:@"dlt"] intValue];
        adContent.forceTime = [[dicAd objectForKey:@"rlt"] intValue];
        adContent.spreadType = [[dicAd objectForKey:@"sdt"] intValue];
        adContent.cacheTime = [[dicAd objectForKey:@"cet"] longLongValue];
        adContent.spreadVat = [[dicAd objectForKey:@"vat"] intValue];
        adContent.deformationMode = [[dicAd objectForKey:@"dm"] intValue];
    }
    
    NSString *deepLink = [dicAd objectForKey:@"dl"];
    if (nil != deepLink && deepLink.length > 0) {
        adContent.deepLink = deepLink;
    }
    
    NSString *adLogoUrlStr = [dicAd objectForKey:@"adLogo"];
    if (nil == adLogoUrlStr) adLogoUrlStr = @"";
    NSString *adIconUrlStr = [dicAd objectForKey:@"adIcon"];
    if (nil == adIconUrlStr) adLogoUrlStr = @"";
    adContent.adLogoURLStr = adLogoUrlStr;
    adContent.adIconUrlStr = adIconUrlStr;
    
    //按照at字段解析出相应的广告资源
    BOOL isOk = [self getAdSourceWithDict:dicAd adContent:adContent];
    if (!isOk) return NO;
   
    
    adContent.otherShowURL = [dicAd objectForKey:@"adl"];
    adContent.adLinkURL = [dicAd objectForKey:@"al"];

    //广告行为打电话、发短信、Email等等
    int nAdFillClickType = [[dicAd objectForKey:@"act"] intValue];
    switch (nAdFillClickType)
    {
        case 1:adContent.adActionType = AdViewAdActionType_Web; break;
        case 2:adContent.adActionType = AdViewAdActionType_AppStore; break;
        case 4:adContent.adActionType = AdViewAdActionType_Map;break;
        case 8:adContent.adActionType = AdViewAdActionType_Sms; break;
        case 16:adContent.adActionType = AdViewAdActionType_Mail;break;
        case 32:adContent.adActionType = AdViewAdActionType_Call; break;
        case 128:adContent.adActionType = AdViewAdActionType_MiniProgram;break;
        default:break;
    }
    
    if (nAdFillClickType == 128)    // 解析小程序相关内容
    {
        NSString *aptAppId = [dicAd objectForKey:@"aptAppId"];  //@"";
        NSString *aptOrgId = @"gh_4a0f88f074ca";                //[dicAd objectForKey:@"aptOrgId"];
        NSString *aptPath = [dicAd objectForKey:@"aptPath"];    //@"pages/news/index";
        int aptType = [[dicAd objectForKey:@"aptType"] intValue];
        adContent.miniProgramDict = [NSDictionary dictionaryWithObjectsAndKeys:aptAppId,@"appId",aptOrgId,@"orgId",aptPath,@"path",[NSNumber numberWithInt:aptType],@"type",nil];
    }
    
    NSString *adID = [dicAd objectForKey:@"adi"];
    //            如果adi字段不存在，会导致崩溃，添加判断
    if (nil == adID) {
        NSDate *currentDate = [NSDate date];//获取当前时间，日期
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"YYYYMMdd-HHmmss"];
        NSString *dateString = [dateFormatter stringFromDate:currentDate];
        adID = [NSString stringWithFormat:@"%@_sdk%.2d_165-4172-Fx4e-3719_%d",dateString,arc4random()%20,[[_infoDict objectForKey:@"ro"] intValue]];
    }
    adContent.adId = adID;
    [_infoDict setObject:adID forKey:@"adi"];
    NSString *adInfo = [dicAd objectForKey:@"ai"];
    if (nil == adInfo) {
        adInfo = @"";
    }
    adContent.adInfo = adInfo;
    [_infoDict setObject:adInfo forKey:@"ai"];
    
    NSString *src = [NSString stringWithFormat:@"%d",[[dicAd objectForKey:@"src"] intValue]];
    adContent.src = [src intValue];
    if ([AdViewExtTool sharedTool].autoTestFunction) {
        [AdViewExtTool sharedTool].srcString = src;
    }
    return YES;
}

- (void)parseResPonse:(AdViewAdResponse *)response completionHandler:(void (^)(NSArray * adArray, NSError *error))completionHandler {
    
}

- (BOOL)parseResponse:(AdViewAdapterResponse*)response contentArr:(NSMutableArray *)contentArr ErrorInfo:(NSString **)errInfo
{
    NSString *errMsg = nil;
    NSError *jsonError = nil;
    NSData *data = response.body;
    
    if (AdViewConnectionStateRequestGet == response.type)
    {
        if ([AdViewExtTool sharedTool].autoTestFunction)
        {
            [AdViewExtTool sharedTool].srcString = @"-1";
        }
    }
    
    //当替换数据功能开启时替换“所有”返回数据，反之无影响
    data = [self replaceResponseDataWithData:data];
    
    id parsed = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
    
    if (errInfo != nil)
    {
        *errInfo = @"Error parsing config JSON from server";
    }
    
    if (parsed == nil)
    {
        return NO;
    }
    
    self.otherPaltArray = nil;
    NSDictionary * dict = (NSDictionary *)parsed;
    
    //0代表错误
    if (0 == [[dict objectForKey:@"res"] intValue])
    {
        errMsg = [dict objectForKey:@"mg"];
        if (nil != errInfo)
        {
            if (errMsg) *errInfo = errMsg;
            else *errInfo = @"No ad response";
        }
        AdViewLogDebug(@"%s,Error:%@", __FUNCTION__, errMsg);
        
        if (AdViewConnectionStateRequestGet == response.type)
        {
            NSMutableArray *array;
            NSDictionary *agdata = [dict objectForKey:@"agdata"];
            if (agdata)
            {
                AdViewRolloverAdapterModel *model = [AdViewRolloverAdapterModel modelFromJSONDictionary:agdata];
                if (model)
                {
                    if (!array)
                    {
                        array = [NSMutableArray array];
                    }
                    [array addObject:model];
                }
            }
            
            NSArray *agext = [dict objectForKey:@"agext"];
            if ([agext isKindOfClass:[NSArray class]] && agext)
            {
                for (NSDictionary *agdata in agext)
                {
                    AdViewRolloverAdapterModel *model = [AdViewRolloverAdapterModel modelFromJSONDictionary:agdata];
                    if (model)
                    {
                        if (!array)
                        {
                            array = [NSMutableArray array];
                        }
                        [array addObject:model];
                    }
                }
            }
            
            if (array)
            {
                self.otherPaltArray = array;
            }
            self.bIgnoreShowRequest = YES;
        }
        return NO;
    }
    
    if (response.type == AdViewConnectionStateRequestGet)
    {
        int count = [[dict objectForKey:@"ac"] intValue];
        if (count < 1) return NO;
        
        NSArray *adArr = (NSArray*)[dict objectForKey:@"ad"];
        if (![adArr isKindOfClass:[NSArray class]] || [adArr count] < 1)
        {
            if (nil != errInfo) *errInfo = @"No ad response";
            return NO;
        }
        
        BOOL isFirst = YES;
        for (NSDictionary *dicAd in adArr)
        {
            AdViewContent *adContent = isFirst?[contentArr firstObject]:nil;
            if (adContent == nil)
            {
                adContent = [[AdViewContent alloc] init];
                [contentArr addObject:adContent];
            }
            
            if (![dicAd isKindOfClass:[NSDictionary class]]) return NO;
            
            if (![self parseAdFieldWithDict:dicAd adContent:adContent])
            {
                return NO;
            }
            
            int sgt = [[dict objectForKey:@"sgt"] intValue];
            adContent.severAgent = sgt;
            [_infoDict setObject:[NSNumber numberWithInt:sgt] forKey:@"sgt"];
            
            int agt = [[dict objectForKey:@"agt"] intValue];
            adContent.severAgentAdvertiser = agt;
            [_infoDict setObject:[NSNumber numberWithInt:agt] forKey:@"agt"];
            
            adContent.adAppId = self.appId;
            adContent.adPlatType = self.adPlatType;
            adContent.adCopyrightStr = [self copyRightString];
            
            if (self.adType != AdViewNative)
            {
                break;
            }
            else
            {
                if (!isFirst || !contentArr.count)
                {
                    [contentArr addObject:adContent];
                }
            }
            isFirst = NO;
        }
    }
    
    if (errInfo != nil)
    {
        *errInfo = nil;
    }
    return YES;
}

#pragma mark - parent class function
- (void)adjustAdSize:(CGSize*)size
{
	if (320 == size->width)
    {
		size->height = 50;
	}
}

- (NSString*)copyRightString
{
	return ADFILL_STR;
}

#pragma mark - for test replace data
// config file exist? last saved?
- (BOOL)isFileExists:(NSString*)path {
    NSFileManager *manage = [NSFileManager defaultManager];
    
    BOOL ret = [manage fileExistsAtPath:path]
    && [manage isReadableFileAtPath:path];
    if (!ret) {
    }
    return ret;
}

//当替换数据功能开启时替换所有返回数据
- (NSData *)replaceResponseDataWithData:(NSData *)data
{
    if ([AdViewExtTool sharedTool].replaceResponseFuction) //测试：替换所有数据
    {
        NSString *sPath = [[[NSBundle mainBundle] bundlePath]stringByAppendingPathComponent:@"nativeVideoTest.txt"];
        BOOL bExist = [self isFileExists:sPath];
        AdViewLogDebug(@"offline config path:%@, exist:%d", sPath, bExist);
        NSString *strXS = [NSString stringWithContentsOfFile:sPath encoding:NSUTF8StringEncoding error:nil];
        data = [strXS dataUsingEncoding:NSUTF8StringEncoding];
    }
    return data;
}

@end

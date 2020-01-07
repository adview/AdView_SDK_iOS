//
//  AdViewExtTool.h
//  AdViewHello
//
//  Created by AdView on 12-8-23.
//  Copyright 2012 AdView. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AdViewURLCache.h"

#define URLCACHE_MEM_SIZE       5*1024*1024
#define URLCACHE_DISK_SIZE      100*1024*1024
#define URLCACHE_VIDEO_SIZE     200
#define URLCACHE_PATH			@"Library/Caches/AdViewView"

typedef enum enumMacAddrFmtType {
	MacAddrFmtType_Default = 0,
	MacAddrFmtType_Colon = 1,			//comma。
	MacAddrFmtType_UpperCase = 2,		//upper.
	MacAddrFmtType_UpperCaseColon = 3,	//both.
}MacAddrFmtType;

typedef NS_ENUM (NSInteger, AdViewLocale){
    AdViewLocale_Chinese,
    AdViewLocale_English
};

@interface AdViewExtTool : NSObject<UIWebViewDelegate>
{
	NSMutableDictionary		*objDict;
	
	void					*netManager;		//AdViewNetManager
	
	UIWebView				*_webView;
	NSString				*userAgent;
	
	NSString				*macAddr[4];		//4 formats
}

@property (nonatomic, retain) NSString *ipAddr;

@property (nonatomic, retain) UIImage *closeImageN;
@property (nonatomic, retain) UIImage *closeImageH;

@property (nonatomic, retain) AdViewURLCache *urlCache;

@property (nonatomic, retain) NSString *userAgent;

@property (nonatomic, assign) BOOL ios6Checked;

@property (nonatomic, retain) NSString *idaString;
@property (nonatomic, retain) NSString *idvString;
@property (nonatomic, assign) BOOL advTrackingEnabled;
@property (nonatomic, retain) NSString *inmobiIdMapStr;

@property (nonatomic, assign) int protocolCount;

@property (nonatomic, assign) BOOL replaceXSFuction; //替换xs字段功能
@property (nonatomic, assign) BOOL replaceResponseFuction; //替换返回数据功能
@property (nonatomic, assign) BOOL autoTestFunction; //自动测试功能是否开启（用于存储数据判断）
@property (nonatomic, strong) NSMutableDictionary *testDict; //存储测试功能数据
@property (nonatomic, strong) NSString *srcString; //存储src渠道
@property (nonatomic, strong) NSArray *replaceStrArr; //需要替换的宏字符串数组
+ (AdViewExtTool*)sharedTool;
+ (NSData*)gzipData: (NSData*)pUncompressedData;
+ (BOOL) getMacAddressBytes:(void *)out_mac;

//本地化
+ (AdViewLocale)locale;

- (NSString*)getMacAddress:(MacAddrFmtType)fmt;
- (NSString *)deviceIPAdress;

- (UIImage *)getCloseImageNormal;
- (UIImage *)getCloseImageHighlight;

//⚠️ 并不是存储到磁盘.只是临时保存在内存中.等待三方API需要进行宏替换时进行字符串替换.
- (void)removeStoredObjectForKey:(NSString*)keyStr;
- (void)storeObject:(NSObject*)obj forKey:(NSString*)keyStr;
- (NSObject*)objectStoredForKey:(NSString*)keyStr;

+ (NSString *)getSha1HexStringByData:(NSData *)_data;

+ (NSString *)getSha1HexString:(NSString *)plainText;
+ (NSString *)getMd5HexString:(NSString *)plainText;

+ (UIColor *) hexStringToColor: (NSString *) stringToConvert;

+ (NSString *)encodeToPercentEscapeString:(NSString *)input;
+ (NSString *)decodeFromPercentEscapeString:(NSString*)input;

+ (BOOL)isJailbroken;
+ (NSString *)URLEncodedString:(NSString*)str;
+ (id)getSSIDInfo;

+ (NSString *)stringFromHexString:(NSString *)hexString;
+ (NSString *)hexStringFromString:(NSString *)string;

+ (BOOL)getDeviceIsIpad;
+ (BOOL)getDeviceDirection;//设备方向
+ (int) getDensity;

+ (NSString*)getUM5;		//md5 of udid.
+ (NSString*) serviceProviderCode;
+ (NSString *)getIDA;
+ (NSString *)getIDFV;

+ (int)dateStringChangeToSeconds:(NSString*)timeStr;

- (void)setMyURLCache;
- (void)removeAllCaches;

- (void)createHttpRequest;			//for useragent.

- (void)checkIOS6Params;

//platform specific.
- (NSString*)getInMobiIdMap;
- (void)getLocation;
+ (NSString*)encryptAduuMd5:(NSString*)str;

+ (int) aduuNetworkType;

//ios version
+ (void)showViewModal:(UIViewController*)toShow FromRoot:(UIViewController*)root;
+ (void)dismissViewModal:(UIViewController*)inShow;
//将size2的尺寸按照size的大小等比放大
+ (void)scaleEnlargesTheSize:(CGSize)size toSize:(CGSize *)size2;

/**
 字典转换json字符串

 @param dic json字典
 @return 返回json字符串
 */
+ (NSString*)jsonStringFromDic:(NSDictionary*)dic;

/**
 新建日历

 @param jsonDict 日历信息字典
 回调 Granted:是否允许使用日历, Error:错误明细
 */
+ (void)newCalendarFromJsonDict:(NSDictionary *)jsonDict completion:(void(^)(BOOL granted, NSError * error))completion;
+ (BOOL)isViewable:(UIView *)view;  //view是否可见
    
- (NSString*)replaceDefineString:(NSString *)urlString;

// 获取测试所需数据
- (NSDictionary*)getDataForTest;

// 存储测试所需数据
- (void)storDataForTest;

//获取手机型号
- (NSString *)iphoneType;

//下载图片
void UIImageFromURL( NSURL * URL, void (^imageBlock)(UIImage * image), void (^errorBlock)(void));

//获取controller.view的安全区域
UIEdgeInsets AdViewSafeAreaInset(UIView *view);

@end

#ifdef __cplusplus
extern "C" {
#endif

CGImageRef createForwardOrBackArrowImageRef_AdView(BOOL bForward);

#define AdViewLogDebug(...) _AdViewLogDebug(__VA_ARGS__)
#define AdViewLogInfo(...) _AdViewLogInfo(__VA_ARGS__)
void _AdViewLogDebug(NSString *format, ...);
void _AdViewLogInfo(NSString *format, ...);

typedef enum tagAdViewLogLevel {
	AdViewLogLevel_None = 0,
	AdViewLogLevel_Info = 30,
	AdViewLogLevel_Debug = 40
}AdViewLogLevel;

void setAdViewLogLevel(int level);

//显示debug日志
#define	OPENAPI_AD_DEBUGLOG 0
	
#ifdef __cplusplus
}
#endif

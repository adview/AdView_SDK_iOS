//AdViewDefines.h
//对内

#ifndef AdViewHello_AdViewDefines_h
#define AdViewHello_AdViewDefines_h

#pragma mark - 各种数据定义

#define DEBUG_LOGMODE 0             //测试日志
#define ADVIEWSDK_VERSION @"400"    //sdk版本号
#define ADVIEWSDK_PARTENER_VERSION @"4.0.0"

#define SHOWTHEPROPORTION 15/16     //页面比例
#define STATUSBARHIDDENHEIGHT [[UIApplication sharedApplication] statusBarFrame].size.height  //状态栏高度

#define SPREAD_EXIST_MOST   5       //开屏最长展示时间

#define AdViewAd_TIME_LIMIT 10.0f   //请求间隔
#define LAST_REQTIME_FMT @"lastReqTime_%zd_%zd"     //上次请求时间key
#define LAST_REQ_STAUS @"lastRequestAdStatus"       //上次请求状态key
#define USE_TEST_SERVER_KEY @"AdViewUseTestServer"  //userDefault的key.用来保存是否使用测试地址

extern NSString *const AdView_IABConsent_CCPA;      //加州CCPA保存的key

#define LAUNCH_EMPTY_AD_FILTER 1    //空白图片过滤
#define BANNER_AUTO_REQUEST 1       //Banner自动请求

#define ADVIEW_LABEL_TAG 1234       //右下角图标tag值
#define ADVIEW_GG_LABEL_TAG 1235    //广告字样图标tag值

#define WeakObj(o) try{}@finally{} __weak typeof(o) o##Weak = o;

#pragma mark - BannerSize
#define ADVIEW_SIZE_320x50        CGSizeMake(320, 50)
#define ADVIEW_SIZE_480x44        CGSizeMake(480, 44)
#define ADVIEW_SIZE_300x250       CGSizeMake(300, 250)
#define ADVIEW_SIZE_480x60        CGSizeMake(480, 60)
#define ADVIEW_SIZE_728x90        CGSizeMake(728, 90)

#pragma mark - AdFill、Video test keyword 💰使用本地文件测试
#define DEBUG_XS_FILE   0                   //⚠️ 使用xs.txt替换xs字段
#define DEBUG_VIDEO_FILE 0                  //⚠️ 是否使用本地videoData.txt视频数据debug
#define CALENDAR_PRIVACY 0                  //日历权限
#define PHOTO_PRIVACY 0                     //相册权限

//native广告block
typedef void (^ReceivedDataBlock)(NSArray* array);
typedef void (^FailLoadBlock)(NSError* error);
typedef void (^ShowPresentBlock)(void);
typedef void (^ClosedBlock)(void);

//广告获取Adapter ⚠️现在基本已经废弃,只保留AdDirect、Adview、AdFill、AdViewRTB.
typedef NS_ENUM(NSInteger, AdViewAdPlatType)
{
    AdViewAdPlatTypeAdDirect    = 0,    //直投 Adview
    AdViewAdPlatTypeAdExchange  = 1,    //交换 Adview
    AdViewAdPlatTypeSuiZong     = 2,    //suizong
    AdViewAdPlatTypeImmob       = 3,    //Immob
    AdViewAdPlatTypeInMobi      = 4,    //InMobi
    AdViewAdPlatTypeAduu        = 5,    //Aduu
    AdViewAdPlatTypeWQMobile    = 6,    //WQMobile
    AdViewAdPlatTypeKouDai      = 7,    //koudao
    AdViewAdPlatTypeAdfill      = 8,    //补余 Adview
    AdViewAdPlatTypeAdview      = 9,    //流量优化 Adview
    AdViewAdPlatTypeAdviewRTB           //RTB Adview
};

//开屏位置 1居上 2居下 ⚠️基本废弃
typedef enum{
    AdViewSpreadShowTypeTop = 1,
    AdViewSpreadShowTypeBottom = 2,
}AdViewSpreadShowType;

#pragma mark - AdFill广告类型枚举
//显示广告时的广告类型
typedef enum {
    AdViewAdSHowType_Text = 0,          //文字
    AdViewAdSHowType_ImageText,         //图文?
    AdViewAdSHowType_FullImage,         //图片
    AdViewAdSHowType_FullGif,           //动图
    AdViewAdSHowType_WebView = 10,      //mraid webview
    AdViewAdSHowType_WebView_Content,   //mraid webview
    AdViewAdSHowType_WebView_Video,     //mraid webview
    AdViewAdSHowType_AdFillImageText,   //图文
    AdViewAdSHowType_Video,             //视频
}AdViewAdSHowType;

#pragma mark - AdFill at字段
//服务器回传广告类型 at字段
typedef NS_ENUM(NSUInteger, AdFillAdType) {
    AdFillAdTypeBannerPic      = 0,     //图片
    AdFillAdTypeBannerWords    = 1,     //文字
    AdFillAdTypeBannerPicWords = 2,     //图文
    AdFillAdTypeInstl          = 3,     //插屏
    AdFillAdTypeHTML           = 4,     //HTML
    AdFillAdTypeSpread         = 5,     //开屏
    AdFillAdTypePopVideo       = 6,     //弹出视频(激励)
    AdFillAdTypeDataVideo      = 7,     //数据视频(贴片)
    AdFillAdTypeNative         = 8,     //原生
    AdFillAdTypeEmbedVieo      = 11     //嵌入式视频(横幅视频)
};

#pragma mark - AdFill广告行为枚举
typedef enum {
    AdViewAdActionType_Unknown = 0,       //Judge by schema, http:// , https:// (no itunes) WebView.
    AdViewAdActionType_Web,               //UIWebView
    AdViewAdActionType_OpenURL,           //For some server, if unknow, default may use OpenURL.
    AdViewAdActionType_AppStore,
    AdViewAdActionType_Call,
    AdViewAdActionType_Sms,
    AdViewAdActionType_Mail,
    AdViewAdActionType_Map,
    AdViewAdActionType_MiniProgram,         //小程序
}AdViewAdActionType;

typedef enum {
    AdViewContentErrorType_Generic = -1,
    AdViewContentErrorType_None = 0,
    AdViewContentErrorType_NoFill = 1,
}AdViewContentErrorType;

#pragma mark - AdFill开屏布局枚举
typedef enum {
    AdSpreadShowTypeNone,
    AdSpreadShowTypeTop = 1,
    AdSpreadShowTypeCenter,
    AdSpreadShowTypeBottom,
    AdSpreadShowTypeAllCenter,
    AdSpreadShowTypeImageCover,         //图片高度大于屏幕高度时图片整个覆盖屏幕压在logo上，文字压在底部图片上
    AdSpreadShowTypeLogoOrTextCover,    //图片+【文字】+logo大于屏幕高的时候logo和文字覆盖在图片上。文字衔接在logo上，logo放在底部。
}AdSpreadShowType;

typedef enum {
    AdSpreadDeformationModeNone = 0,    //不变形
    AdSpreadDeformationModeImage,       //只有图片平铺，html排版按照AdSpreadShowType规则
    AdSpreadDeformationModeAll,         //纯图片和html都进行平铺处理
    AdSpreadDeformationModeMax,
}AdSpreadDeformationMode;

#pragma mark - AdViewConnetcion.h
//目前的状态
typedef NS_ENUM(NSInteger, AdViewConnectionState) {
    AdViewConnectionStateNone = -1,             //无状态
    AdViewConnectionStateRequestGet = 0,        //获取广告数据
    AdViewConnectionStateParseContent,          //正在解析广告
    AdViewConnectionStateRequestImage,          //请求素材图片
    AdViewConnectionStateRequestDisplay,        //展示请求
    AdViewConnectionStateRequestClick           //点击请求
};

//请求类型
typedef NS_ENUM(NSUInteger, AdViewConnectionType) {
    AdViewConnectionTypeGetRequest = 0,
    AdViewConnectionTypeDisplayRequest,
    AdViewConnectionTypeClickRequest,
};

#import <JavaScriptCore/JavaScriptCore.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <StoreKit/StoreKit.h>

#import "AdViewView.h"
#import "AdViewDefinesPublic.h"
#import "AdViewAdapter.h"
#import "AdViewContent.h"
#import "AdViewVPAIDClient.h"
#import "AdViewExtTool.h"
#import "AdViewReachability.h"
#import "AdViewCheckTool.h"
#import "AdViewMraidParser.h"
#import "AdViewVastFileHandle.h"
#import "AdViewConnection.h"

#import "AdViewOMBaseAdUnitManager.h"

#import "AdViewToastView.h"
#import "AdViewLogWKWebView.h"
#import "AdViewMraidWebView.h"

#import "AdViewVideoViewController.h"
#import "AdViewSKStoreProductViewController.h"

#import "NSObject+AdViewJSONModel.h"
#import "UIDevice+AdViewIDFA.h"
#import "UIImage+AdViewBundle.h"
#import "NSTimer+AdViewWeakTimer.h"
#import "NSObject+AdViewFrameworkResource.h"
#import "NSObject+AdViewDeallocLog.h"
#import "UIView+AdViewDisplaying.h"
#import "UIImage+VideoThumbnail.h"

//#import "WXApiObject.h"
//#import "WXApi.h"
#endif

//
//  AdViewManager.h
//  AdViewHello
//
//  Created by AdView on 14-9-25.
//
//  总控制

#import <Foundation/Foundation.h>
#import "AdViewView.h"
#import "AdViewConnection.h"
#import "AdViewWebViewController.h"
#import <MessageUI/MessageUI.h>
#import "AdViewContent.h"
#import "AdViewDefines.h"
#import "AdViewRolloverManager.h"

@interface AdViewAdManager : NSObject <AdViewConnectionDelegate, UIWebViewDelegate, AdViewWebViewControllerDelegate, MFMessageComposeViewControllerDelegate, WKNavigationDelegate, WKUIDelegate> {
    BOOL adNeedDisplay;             //本次广告是否可以展示
    int clickNumber;                //点击计数
    BOOL adClicking;                //正在点击ing
    BOOL adNotRequest;              //pause or not?
    float moveCenterHeight;         //center移动的距离
    NSTimeInterval inActiviteTime;  //app跳转是的时间戳 （用于app跳转回来之后开屏处于某种状态-关闭/继续展示）
    NSTimeInterval requestTime;     //上次请求时间
    BOOL statusBarHiden;            //记录状态栏状态
    BOOL isWebView;                 //插屏展示区域控制，如果是webview的话不控制展示区域，可以达到边界。
}
@property (nonatomic, strong) AdViewOMBaseAdUnitManager * omsdkManager;   //OMSDK监测管理器

@property (nonatomic, copy) NSString * positionId;                  //广告位id

@property (nonatomic, strong) AdViewRolloverManager *rolloverManager;     //第三方广告轮换控制器

@property (nonatomic, retain) NSTimer* adRequestTimer;              //banner广告自动请求
@property (nonatomic, retain) AdViewContent* adContent;             //广告内容
@property (strong, atomic) NSMutableArray * adConnections;          //请求们
@property (nonatomic, assign) CGSize adPrefSize;                    //创建时传进来的size

@property (nonatomic, retain) AdViewAdapter *adapter;               //请求拼接乱七八糟的
@property (nonatomic, retain) UIViewController *modalController;    //模态弹出的controller
@property (nonatomic, weak)   UIViewController *presentController;  //在这个controller弹出

@property (nonatomic, weak)   AdViewView * rAdView;                 //广告承载界面

@property (nonatomic, strong) UIView * loadingAdView;               //正在加载的广告view 用于判断是否为白条
@property (nonatomic, strong) UIImageView *adSpreadView;            //开屏承载view

@property (nonatomic, strong)AdViewMraidWebView * adViewWebView;    //HTML广告通用webview

@property (nonatomic, assign) BOOL loadingFirstDisplay;             //广告首次显示
@property (nonatomic, strong) NSTimer *animTimer;                   //广告切换动画定时器

@property (nonatomic, assign) BOOL hitTested;                       //是否有点击动作。

@property (nonatomic,retain)UIActivityIndicatorView *activity;

@property (nonatomic,assign) AdvertType advertType;         //广告类型Banner、插屏、开屏、原生
@property (nonatomic,assign) AdvertType adverRequestType;   //⚠️ 请求广告临时使用的类型 以后要去掉.只为了传给condition
@property (nonatomic, retain) UIButton *closeButton;        //关闭按钮
@property (nonatomic, assign) float moveCenterHeight;       //center移动距离
@property (nonatomic, assign) float scaleSize;              //缩放比例大小

@property (assign, nonatomic) BOOL didClosedSpread; //开屏已经关闭
@property (retain, nonatomic) NSTimer *delayTimer;  //开屏延时展示
@property (assign, nonatomic) BOOL didResignActive; //是否切换到后台的状态
@property (assign, nonatomic) BOOL statusBarHiden;


@property (nonatomic, assign) int nativeAdCount;
@property (nonatomic, copy) ReceivedDataBlock nativeAdRecieveDataBlock; //原生广告收到数据
@property (nonatomic, copy) FailLoadBlock nativeAdFailLoadBlock;        //原生广告加载失败
@property (nonatomic, copy) ShowPresentBlock nativeAdPresentBlock;      //原生广告点击弹出
@property (nonatomic, copy) ClosedBlock nativeAdCloseBlock;             //原生广告关闭弹出


- (id)initWithAdPlatType:(AdViewAdPlatType)adPlatType;

- (void)registerObserver;
- (void)setupBannerAutoAdRequest;
- (void)setupAdRequestTimer: (NSInteger) timeVal;
- (void)requestGet;                                                 //请求广告
- (void)requestAdWithConnetion:(AdViewAdCondition*)condition;

- (void)requestDisplay;
- (void)requestClick;
- (void)reportDisplayOrClickInfoToOther:(BOOL)isDisplay;

- (void)displayAd:(BOOL)isFirstDisplay;
- (BOOL)adinstlIsOutOfSurvivalCycle;

- (void)cancelAdConnections;    //结束所有请求

- (void)openLink:(NSString*)_urlString ActionType:(AdViewAdActionType)type;
- (void)openLink:(AdViewContent*)_adContent;

- (void)pauseRequestAd;
- (void)resumeRequestAd;

- (void)performClickAction;
- (void)performDissmissSpread;

- (void)setClickPositionDicWithTouchPoint:(CGPoint)touchPoint isBegan:(BOOL)isBegan;
- (void)setClickPositionDicForClickAdInstlAction;

- (void)adinstlShowWithController:(UIViewController*)controller;

//native
- (void)didReceivedNativeData:(ReceivedDataBlock)block;
- (void)failToLoadNativeData:(FailLoadBlock)block;
- (void)nativeAdShowPresent:(ShowPresentBlock)block;
- (void)nativeAdClose:(ClosedBlock)block;
@end

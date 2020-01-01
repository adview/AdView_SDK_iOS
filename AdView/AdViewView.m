#import "AdViewConnection.h"
#import "AdViewView.h"
#import "AdViewAdapter.h"
#import "AdViewExtTool.h"
#import <QuartzCore/QuartzCore.h>
#import "AdViewReachability.h"
#import "AdViewAdManager.h"

NSString *const AdView_IABConsent_SubjectToGDPR = @"gdpr";
NSString *const AdView_IABConsent_ConsentString = @"consent";
NSString *const AdView_IABConsent_CMPPresent = @"CMPPresent";
NSString *const AdView_IABConsent_ParsedPurposeConsents = @"parsedPurposeConsents";
NSString *const AdView_IABConsent_ParsedVendorConsents = @"parsedVendorConsents";
NSString *const AdView_IABConsent_CCPA = @"us_privacy";

@interface AdViewView ()
@property (nonatomic, strong) AdViewAdManager * adViewManager;  //广告处理管理器
@property (nonatomic, assign) BOOL interstitialIsReady;         //插屏是否准备好
@property (nonatomic, readwrite,assign) AdvertType advertType;  //Banner、Interstitial、Spread
@end;

@implementation AdViewView

- (instancetype)initWithAdType:(AdvertType)adType
                    positionId:(NSString *)positionId
                    AdPlatType:(AdViewAdPlatType)adPlatType
{
	if (self = [super init])
    {
        //启动OMSDK
        [AdViewOMBaseAdUnitManager activateOMIDSDK];
        
        //几乎所有的逻辑都在AdViewAdManager里面
        self.adViewManager = [[AdViewAdManager alloc] initWithAdPlatType:adPlatType];
        _adViewManager.rAdView = self;
        _adViewManager.advertType = adType;
        _adViewManager.adverRequestType = adType;
        _adViewManager.positionId = positionId;
        self.advertType = adType;
        self.clipsToBounds = YES;
    }
    return self;
}

- (void)dealloc {
    self.adViewManager = nil;
}

extern void setAdViewViewHost(const char *host);

- (id)initBannerSize:(CGSize)size withDelegate:(id<AdViewViewDelegate>)Rtbdelegate
{
    return [AdViewView requestBannerSize:size
                              positionId:nil
                            withDelegate:Rtbdelegate
                          withAdPlatType:AdViewAdPlatTypeAdview];
}

- (id)initBannerWithDelegate:(id<AdViewViewDelegate>)Rtbdelegate
{
    return [AdViewView requestWithDelegate:Rtbdelegate withAdPlatType:AdViewAdPlatTypeAdview];
}

- (id)initAdInstWithDelegate:(id<AdViewViewDelegate>)Rtbdelegate
{
    return [AdViewView requestAdInstlWithDelegate:Rtbdelegate withAdPlatType:AdViewAdPlatTypeAdview];
}

//海外平台只请求Adview的竞价Banner。
+ (AdViewView *)requestBannerSize:(AdViewBannerSize)size
                       positionId:(NSString *)positionID
                         delegate:(id<AdViewViewDelegate>)delegate {
    CGSize bannerSize = ADVIEW_SIZE_320x50;     //size枚举在这里转换一下
    switch (size) {
        case AdViewBannerSize_320x50:  break;
        case AdViewBannerSize_480x44:  bannerSize = ADVIEW_SIZE_480x44;  break;
        case AdViewBannerSize_300x250: bannerSize = ADVIEW_SIZE_300x250; break;
        case AdViewBannerSize_480x60:  bannerSize = ADVIEW_SIZE_480x60;  break;
        case AdViewBannerSize_728x90:  bannerSize = ADVIEW_SIZE_728x90;  break;
        default: break;
    }
    return [self requestBannerSize:bannerSize
                        positionId:positionID
                      withDelegate:delegate
                    withAdPlatType:AdViewAdPlatTypeAdview];
}

+ (AdViewView *)requestBannerSize:(CGSize)size
                       positionId:(NSString *)positionID
                     withDelegate:(id<AdViewViewDelegate>)delegate
                   withAdPlatType:(int)adPlatType
{
    //更新配置信息
    [self updateSettingsWithDelegagte:delegate];

	AdViewView * adView = [[AdViewView alloc] initWithAdType:AdViewBanner
                                                  positionId:positionID
                                                  AdPlatType:adPlatType];
    adView.deallocLog = YES;
    adView.delegate = delegate;

    AdViewAdManager * adViewManager = (AdViewAdManager *)adView.adViewManager;
    if (adViewManager) {
		[adViewManager.adapter adjustAdSize:&size];
		adViewManager.adPrefSize = size;
		
        //根据传递进来的尺寸设定
        CGRect r = [adView frame];
        r.size.width = size.width;
        r.size.height = size.height;
        adView.frame = r;
        adView.userInteractionEnabled = YES;
        
        if (nil != delegate && [delegate respondsToSelector:@selector(configVersion)]) {
            adViewManager.adapter.configVer  = [adView.delegate configVersion];
        }
        
        //如果是MREC的尺寸并且positionID存在,则标记为MREC视频广告(MREC视频广告 == 普通视频广告)
        if (CGSizeEqualToSize(size, ADVIEW_SIZE_300x250)) {
            //⚠️ 11代表MREC图片版,未加入到枚举中。为了方便后台暂时这样做。以后如果有了根据positionID判断广告类型再说。
            //⚠️ 请求参数中的adverType与AdViewView中的adverType在MREC下有区别。以AdViewView的adverType为准。
            adViewManager.adverRequestType = positionID ? AdViewRewardVideo : 11;
        }
        [adView requestAd];
    }
    return adView;
}

+ (AdViewView*)requestWithDelegate:(id<AdViewViewDelegate>)delegate
                    withAdPlatType:(int)adPlatType
{
    CGSize size = [AdViewExtTool getDeviceIsIpad]?ADVIEW_SIZE_728x90:ADVIEW_SIZE_320x50;
    return [AdViewView requestBannerSize:size
                              positionId:nil
                            withDelegate:delegate
                          withAdPlatType:adPlatType];
}

//海外只请求Adview本身插屏广告
+ (AdViewView *)requestAdInterstitialWithDelegate:(id<AdViewViewDelegate>)delegate
{
    return [self requestAdInstlWithDelegate:delegate withAdPlatType:AdViewAdPlatTypeAdview];
}

+ (AdViewView*)requestAdInstlWithDelegate:(id<AdViewViewDelegate>)delegate
                           withAdPlatType:(int)adPlatType
{
    [self updateSettingsWithDelegagte:delegate];
    
    //得到展示区域移动的大小
    float moveCenterDistance = 0;
    
    if (nil != delegate && [delegate respondsToSelector:@selector(moveCentr)])
    {
		moveCenterDistance = [delegate moveCentr];
    }
    //得到展示区域移动的大小
    //得到展示区域的缩放的比例
    float proportion = 1;
    if (nil != delegate && [delegate respondsToSelector:@selector(scaleProportion)])
    {
        proportion = [delegate scaleProportion];
        if (proportion < 0.79 || proportion > 1.11)
        {
            proportion = 1;
        }
    }
    //得到展示区域的缩放的比例
	AdViewView* adInstl = (AdViewView*)[[AdViewView alloc] initWithAdType:AdViewInterstitial
                                                               positionId:nil
                                                               AdPlatType:adPlatType];
    AdViewAdManager *adViewManager = (AdViewAdManager *)adInstl.adViewManager;
    
    //移动距离赋值    缩放比例赋值
    adViewManager.moveCenterHeight = moveCenterDistance;
    adViewManager.scaleSize = proportion;
    
    if (adInstl)
    {        
        CGRect startRect = [[UIScreen mainScreen] bounds];
        
        BOOL bIsLand = [AdViewExtTool getDeviceDirection];
        CGFloat width = bIsLand?startRect.size.height:startRect.size.width;
        CGFloat height =  bIsLand?startRect.size.width:startRect.size.height;
        
        if (bIsLand && width < height) {
            width += height;
            height = width - height;
            width = width - height;
        }
        
        CGRect rect = CGRectMake(startRect.origin.x,startRect.origin.y, width, height);
        adInstl.frame = rect;
        
        //获取展示区域的大小
        if (![UIApplication sharedApplication].statusBarHidden) {
            adViewManager.adPrefSize = CGSizeMake(width * SHOWTHEPROPORTION, height * SHOWTHEPROPORTION - STATUSBARHIDDENHEIGHT);
        } else {
            adViewManager.adPrefSize = CGSizeMake(width * SHOWTHEPROPORTION, height * SHOWTHEPROPORTION);
        }
        //获取展示区域的大小
        adInstl.delegate = delegate;
        adInstl.userInteractionEnabled = YES;
        adInstl.backgroundColor = [UIColor clearColor];
        
        if (nil != delegate && [delegate respondsToSelector:@selector(configVersion)]) {
            adViewManager.adapter.configVer  = [adInstl.delegate configVersion];
        }
        //加上小花
        [adInstl addSubview:adViewManager.activity];
        //开始请求
        [adInstl requestAd];
        [adViewManager.activity startAnimating];
    }
    return adInstl;
}

//海外开屏只请求Adview自己的广告。
+ (AdViewView *)requestSpreadActivityWithDelegate:(id<AdViewViewDelegate>)delegate
{
    return [self requestSpreadActivityWithDelegate:delegate withAdPlatType:AdViewAdPlatTypeAdview];
}

+ (AdViewView *)requestSpreadActivityWithDelegate:(id<AdViewViewDelegate>)delegate withAdPlatType:(AdViewAdPlatType)adPlatType
{
    [self updateSettingsWithDelegagte:delegate];
    AdViewView * adSpread = (AdViewView *)[[AdViewView alloc] initWithAdType:AdViewSpread
                                                                  positionId:nil
                                                                  AdPlatType:adPlatType];
    AdViewAdManager *adViewManager = (AdViewAdManager *)adSpread.adViewManager;
    
    adViewManager.statusBarHiden = [UIApplication sharedApplication].statusBarHidden;
    if (!adViewManager.statusBarHiden)
    {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    }
    
    adSpread.delegate = delegate;
    adSpread.userInteractionEnabled = YES;
    adSpread.backgroundColor = [UIColor clearColor];
    
    CGSize realSize = CGSizeMake(0, 0);
    if ([UIScreen instancesRespondToSelector:@selector(currentMode)])
        realSize = [[UIScreen mainScreen] currentMode].size;    //外接屏幕分辨率
    
    //默认尺寸？
    CGSize spreadSize = CGSizeMake(realSize.width, realSize.height - realSize.width / 4);
    adViewManager.adPrefSize = spreadSize;
    
    if (nil != delegate && [delegate respondsToSelector:@selector(configVersion)])
    {
        adViewManager.adapter.configVer = [adSpread.delegate configVersion];
    }
    
    [adSpread requestAd];
    return adSpread;
}

//更新信息
+ (void)updateSettingsWithDelegagte:(id<AdViewViewDelegate>)delegate
{
    BOOL bLogMode = NO;
    
    if (nil != delegate && [delegate respondsToSelector:@selector(logMode)]) {
        bLogMode = [delegate logMode];
    }
    
    int logLevel = bLogMode ? AdViewLogLevel_Info : AdViewLogLevel_None;
    if (DEBUG_LOGMODE) logLevel = AdViewLogLevel_Debug;
    setAdViewLogLevel(logLevel);
    
    if (nil != delegate && [delegate respondsToSelector:@selector(AdViewViewHost)]) {
        setAdViewViewHost([[delegate AdViewViewHost] UTF8String]);
    }
}

+ (NSString *)sdkVersion
{
    return ADVIEWSDK_VERSION;
}

- (void)setDelegate:(id<AdViewViewDelegate>)tmpDelegate
{
    _delegate = tmpDelegate;
    if (nil == _delegate)
    {
        [self pauseRequestAd];
    }
    else
    {
        [self resumeRequestAd];
    }
}

- (void)requestAd
{
    [_adViewManager requestGet];
}

- (void)pauseRequestAd
{
    [_adViewManager pauseRequestAd];
}

- (void)resumeRequestAd
{
    [_adViewManager resumeRequestAd];
}

#pragma mark - cache clear
- (void)clearCaches
{
    [[AdViewExtTool sharedTool] removeAllCaches];
}

#pragma mark - model show viewController
//Public 模态弹出viewController
- (BOOL)showInterstitialWithRootViewController:(UIViewController *)rootViewController
{
    if (!self.interstitialIsReady) return NO;
    return [self showWithRootViewController:rootViewController];
}

//Private 仅仅是add广告到controller的view上
- (BOOL)showWithRootViewController:(UIViewController *)rootViewController
{
    AdViewAdManager *dataImpl = (AdViewAdManager*)_adViewManager;
    BOOL outOfSurvivalCycle = [dataImpl adinstlIsOutOfSurvivalCycle];
    if (outOfSurvivalCycle) return NO;
    if(dataImpl.advertType == AdViewInterstitial) {
        if (!dataImpl.adapter.bIgnoreShowRequest) {
            [dataImpl requestDisplay];
        } else {
            [dataImpl reportDisplayOrClickInfoToOther:YES];
        }
        [dataImpl adinstlShowWithController:rootViewController];
    } else {
        [rootViewController.view addSubview:self];
    }
    self.interstitialIsReady = NO;
    
    //是否可视
    dataImpl.adViewWebView.isViewable = YES;
    return YES;
}

#pragma mark - for 云图tv点击需求
- (void)clickAdInstlAction
{
    AdViewAdManager *adViewManager = (AdViewAdManager*)_adViewManager;
    if (adViewManager.advertType == AdViewInterstitial)
    {
        [adViewManager setClickPositionDicForClickAdInstlAction];
        [[AdViewExtTool sharedTool] storeObject:@"0" forKey:@"{CLICKAREA}"];
        [adViewManager performClickAction];
    }
}

#pragma mark touch event
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    AdViewAdManager *adViewManager = (AdViewAdManager*)_adViewManager;
    UITouch *touch = [touches anyObject];
    CGPoint currentPoint = [touch locationInView: adViewManager.rAdView];
    AdViewLogDebug(@"Touches began %@",NSStringFromCGPoint(currentPoint));
    if (adViewManager.adContent.adShowType != AdViewAdSHowType_WebView_Content && adViewManager.adContent.adShowType != AdViewAdSHowType_WebView)
    {
         [adViewManager setClickPositionDicWithTouchPoint:currentPoint isBegan:YES];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    AdViewAdManager *adViewManager = (AdViewAdManager*)_adViewManager;
    UITouch *touch = [touches anyObject];
    CGPoint currentPoint = [touch locationInView: adViewManager.rAdView];
    AdViewLogDebug(@"Touches Ended @ (%f, %f)", currentPoint.x, currentPoint.y);
    
    if (adViewManager.adContent.adShowType != AdViewAdSHowType_WebView_Content && adViewManager.adContent.adShowType != AdViewAdSHowType_WebView)
    {
        [adViewManager setClickPositionDicWithTouchPoint:currentPoint isBegan:NO];
    }
    
    if (adViewManager.advertType == AdViewInterstitial)
    {
        CGRect r = CGRectMake(adViewManager.adContent.clickSize.origin.x / 16 + adViewManager.adContent.clickSize.size.width / 16,
                              adViewManager.adContent.clickSize.origin.y + adViewManager.adContent.clickSize.size.height / 16,
                              adViewManager.adContent.clickSize.size.width * 14 / 16,
                              adViewManager.adContent.clickSize.size.height * 14 / 16);
        
        //CGRectContainsPoint 判断给定的点是否被这个区域包围
        if (CGRectContainsPoint(adViewManager.adContent.clickSize, currentPoint))
        {
            if (CGRectContainsPoint(r, currentPoint))
            {
                [[AdViewExtTool sharedTool] storeObject:@"0" forKey:@"{CLICKAREA}"];//没误点
            }
            else
            {
                [[AdViewExtTool sharedTool] storeObject:@"1" forKey:@"{CLICKAREA}"];//误点
            }
            [adViewManager performClickAction];
        }
    }
    else if(adViewManager.advertType == AdViewSpread)
    {
        if (CGRectContainsPoint(adViewManager.adSpreadView.bounds, currentPoint))
        {
            if (CGRectContainsPoint(adViewManager.adContent.clickSize, currentPoint) || CGRectContainsPoint(adViewManager.adContent.spreadTextViewSize, currentPoint))
            {
                [adViewManager performClickAction];
            }
        }
    }
    else
    {
        CGRect r = CGRectMake(adViewManager.rAdView.bounds.origin.x / 16 + adViewManager.rAdView.bounds.size.width / 16,
                              adViewManager.rAdView.bounds.origin.y / 16 + adViewManager.rAdView.bounds.size.height / 16,
                              adViewManager.rAdView.bounds.size.width * 14 / 16,
                              adViewManager.rAdView.bounds.size.height * 14/16);
        
        if (CGRectContainsPoint(adViewManager.rAdView.bounds, currentPoint))
        {
            if (CGRectContainsPoint(r, currentPoint))
            {
                [[AdViewExtTool sharedTool] storeObject:@"0" forKey:@"{CLICKAREA}"];
            }
            else
            {
                [[AdViewExtTool sharedTool] storeObject:@"1" forKey:@"{CLICKAREA}"];
            }
            [adViewManager performClickAction];
        }
    }
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
	BOOL itsInside = [super pointInside:point withEvent:event];
	AdViewAdManager * adViewManager = (AdViewAdManager*)_adViewManager;
    
	if (event.type == UIEventTypeTouches
		&&  AdViewAdSHowType_WebView_Video == adViewManager.adContent.adShowType)
    {
		//open web.
        [self performSelector:@selector(performClickAction)
				   withObject:nil
				   afterDelay:0.2];
	}
    if (event.type == UIEventTypeTouches && adViewManager.adContent.adShowType == AdViewAdSHowType_WebView_Content)
    {
        
        [adViewManager setClickPositionDicWithTouchPoint:point isBegan:YES];
        
        if (adViewManager.advertType == AdViewInterstitial)
        {
            AdViewLogDebug(@"插屏 Touches Ended @ (%f, %f)", point.x, point.y);
            CGRect r = CGRectMake(adViewManager.loadingAdView.frame.origin.x/16+adViewManager.loadingAdView.frame.size.width/16,
                                  adViewManager.loadingAdView.frame.origin.y+adViewManager.loadingAdView.frame.size.height/16,
                                  adViewManager.loadingAdView.frame.size.width*14/16,
                                  adViewManager.loadingAdView.frame.size.height*14/16);
            
            if (CGRectContainsPoint(adViewManager.loadingAdView.frame, point))
            {
                adViewManager.hitTested = YES;
                if (CGRectContainsPoint(r, point))
                {
                    [[AdViewExtTool sharedTool] storeObject:@"0" forKey:@"{CLICKAREA}"];//没误点
                }
                else
                {
                    [[AdViewExtTool sharedTool] storeObject:@"1" forKey:@"{CLICKAREA}"];//误点
                }
            }
            else
            {
                CGRect r = CGRectMake(adViewManager.rAdView.bounds.origin.x / 16 + adViewManager.rAdView.bounds.size.width / 16, adViewManager.rAdView.bounds.origin.y / 16 + adViewManager.rAdView.bounds.size.height / 16, adViewManager.rAdView.bounds.size.width * 14 / 16, adViewManager.rAdView.bounds.size.height * 14/16);
                
                if (CGRectContainsPoint(adViewManager.rAdView.bounds, point))
                {
                    adViewManager.hitTested = YES;
                    if (CGRectContainsPoint(r, point))
                    {
                        [[AdViewExtTool sharedTool] storeObject:@"0" forKey:@"{CLICKAREA}"];
                    }
                    else
                    {
                        [[AdViewExtTool sharedTool] storeObject:@"1" forKey:@"{CLICKAREA}"];
                    }
                }
            }
        }
        else if (adViewManager.advertType == AdViewBanner)
        {
                CGRect r = CGRectMake(adViewManager.rAdView.bounds.origin.x / 16 + adViewManager.rAdView.bounds.size.width / 16,
                                      adViewManager.rAdView.bounds.origin.y / 16 + adViewManager.rAdView.bounds.size.height / 16,
                                      adViewManager.rAdView.bounds.size.width * 14 / 16,
                                      adViewManager.rAdView.bounds.size.height * 14/16);
                if (CGRectContainsPoint(adViewManager.rAdView.bounds, point))
                {
                    adViewManager.hitTested = YES;
                    if (CGRectContainsPoint(r, point))
                    {
                        [[AdViewExtTool sharedTool] storeObject:@"0" forKey:@"{CLICKAREA}"];
                    }
                    else
                    {
                        [[AdViewExtTool sharedTool] storeObject:@"1" forKey:@"{CLICKAREA}"];
                    }
                }
        }
        else if (adViewManager.advertType == AdViewSpread)
        {
            if (CGRectContainsPoint(adViewManager.adSpreadView.bounds, point))
            {
                if (CGRectContainsPoint(adViewManager.adContent.clickSize, point) || CGRectContainsPoint(adViewManager.adContent.spreadTextViewSize, point))
                {
                    adViewManager.hitTested = YES;
                }
            }
            else
            {
                //点击区域外点击无响应
            }
        }
    }
	return itsInside;
}

@end

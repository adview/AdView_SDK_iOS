//
//  AdViewManager.m
//  AdViewHello
//
//  Created by AdView on 14-9-25.
//
//

#import "AdViewAdManager.h"
#import "AdViewOMAdImageManager.h"
#import "AdViewOMAdHTMLManager.h"

#define AD_INTERVAL			30			//默认请求间隔s
#define AD_INTERVAL_LIMIT	15			//最小请求间隔s

#define AD_CLICK_TIMEOUT    600         //单条广告超过该时间后点击无效

#define ADSERVERREPORT 1
#define LOGOIMAGE_TAG 10001

//第一次请求插屏
static bool isFirst = YES;

@interface AdViewAdManager () <SKStoreProductViewControllerDelegate,AdViewMraidViewDelegate,AdViewVideoViewControllerDelegate,AdViewRolloverManagerDelegate>
@property (nonatomic, assign) NSTimeInterval spreadShowTime;                //开屏展示的总时间
@property (nonatomic, strong) AdViewVideoViewController * videoController;  //进行视频逻辑的controller
@end

@implementation AdViewAdManager
@synthesize moveCenterHeight = _moveCenterHeight;
@synthesize statusBarHiden = _statusBarHiden;

#pragma mark -
- (id)initWithAdPlatType:(AdViewAdPlatType)adPlatType
{
    if (self = [super init])
    {
        NSMutableArray *arrTmp = [[NSMutableArray alloc] initWithCapacity:4];
        self.adConnections = arrTmp;
        
        NSString *adapterClassName = @"AdViewAdapter";
        
        switch (adPlatType)
        {
            case AdViewAdPlatTypeSuiZong:
                adapterClassName = @"AdViewAdapterSuiZong";
                break;
            case AdViewAdPlatTypeImmob:
                adapterClassName = @"AdViewAdapterImmob";
                break;
            case AdViewAdPlatTypeInMobi:
                adapterClassName = @"AdViewAdapterInMobi";
                break;
            case AdViewAdPlatTypeAduu:
                adapterClassName = @"AdViewAdapterAduu";
                break;
            case AdViewAdPlatTypeWQMobile:
                adapterClassName = @"AdViewAdapterWQMobile";
                break;
            case AdViewAdPlatTypeKouDai:
                adapterClassName = @"AdViewAdapterKoudai";
                break;
            case AdViewAdPlatTypeAdfill:
            case AdViewAdPlatTypeAdview:
            case AdViewAdPlatTypeAdviewRTB:
                adapterClassName = @"AdViewAdapterAdFill";
                break;
            default:
                break;
        }
        
        Class adapterClass = NSClassFromString(adapterClassName);
        if (nil == adapterClass) {
            adapterClass = NSClassFromString(@"AdViewAdapter");
        }
        
        AdViewAdapter *adapter_0 = (AdViewAdapter *)[[adapterClass alloc] init];
        adapter_0.adPlatType = adPlatType;
        self.adapter = adapter_0;
        
        CGRect startRect = [[UIScreen mainScreen] bounds];
        BOOL bIsLand = [AdViewExtTool getDeviceDirection];
        CGFloat width =  bIsLand?startRect.size.height:startRect.size.width;
        CGFloat height =  bIsLand?startRect.size.width:startRect.size.height;
        if (bIsLand && width < height)
        {
            width += height;
            height = width - height;
            width = width - height;
        }
        
        if (_advertType == AdViewInterstitial)
        {
            //提示小花
            _activity = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
            _activity.tag = 9999;
            _activity.userInteractionEnabled = YES;
            [_activity setCenter:CGPointMake(width/2,height/2)];
            [_activity setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];//设置进度轮显示类型
            UITapGestureRecognizer * Clicktap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeAdInstl)];
            [_activity addGestureRecognizer:Clicktap];
        }
    }
    return self;
}

- (void)dealloc {
    [_omsdkManager finishMeasurement];
    self.omsdkManager = nil;
        
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[AdViewExtTool sharedTool] removeStoredObjectForKey:@"spreadDidActived"];
    if (nil != _adRequestTimer) [_adRequestTimer invalidate];
    self.adRequestTimer = nil;
    [self cancelAnimTimer];
    [self cancelDelayTimer];
    
    if (self.advertType == AdViewBanner) {
        [self resetProtocolCount];
    }
    
    if (nil != self.modalController) {
        [AdViewExtTool dismissViewModal:self.modalController];
        self.modalController = nil;
    }
    
    if (self.videoController) {
        [self.videoController close];
    }
    
    self.videoController = nil;
    self.loadingAdView = nil;
    self.adViewWebView = nil;
    self.adSpreadView = nil;

    [self.closeButton removeFromSuperview];
    self.closeButton = nil;
    
    self.activity = nil;
    
    [self cancelAdConnections];
    self.adConnections = nil;
    
    [self.adapter cleanDummyData];
    self.adapter = nil;
}

- (void)resetProtocolCount
{
    AdViewAdSHowType showType = self.adContent.adShowType;
    if (showType == AdViewAdSHowType_WebView_Content || showType == AdViewAdSHowType_WebView || showType == AdViewAdSHowType_WebView_Video)
    {
        [AdViewExtTool sharedTool].protocolCount--;
    }
}

#pragma mark - AdSpread
//添加开屏倒计时Label
- (void)addCountdownLabel
{
    UILabel * label = [self.adSpreadView viewWithTag:15133];
    if (nil != label)
    {
        return;
    }
    
    CGSize size = self.adSpreadView.frame.size;
    UILabel *countdownLabel = [[UILabel alloc] initWithFrame:CGRectMake(size.width - 70, STATUSBARHIDDENHEIGHT + 10, 60, 30)];
    countdownLabel.text = [NSString stringWithFormat:@"%ds 跳过",self.adContent.relayTime];
    countdownLabel.textAlignment = NSTextAlignmentCenter;
    countdownLabel.tag = 15133;
    countdownLabel.backgroundColor = [AdViewExtTool hexStringToColor:@"#bb404040"];
    countdownLabel.textColor = [UIColor whiteColor];
    countdownLabel.layer.cornerRadius = 5;
    countdownLabel.layer.masksToBounds = YES;
    countdownLabel.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(performDissmissSpread)];
    [countdownLabel addGestureRecognizer:tapGes];
    tapGes = nil;
    self.adSpreadView.userInteractionEnabled = YES;
    [self.adSpreadView addSubview:countdownLabel];
}

//更新倒计时label数字
- (void)updateCountdownLabelText
{
    if (self.didClosedSpread) return;

    UILabel * label = [self.adSpreadView viewWithTag:15133];
    self.adContent.relayTime--;
    if (self.adContent.relayTime == 0)
    {
        [label removeFromSuperview];
        [self performDissmissSpread];
    }
    label.text = [NSString stringWithFormat:@"%ds 跳过",self.adContent.relayTime];
}

- (void)delayShowSpread
{
    _animTimer = nil;
    if (self.adContent.relayTime != 0) {
        [self addCountdownLabel];
        self.delayTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                           target:self
                                                         selector:@selector(updateCountdownLabelText)
                                                         userInfo:nil
                                                          repeats:YES];
    } else {
        [self performDissmissSpread];
    }
}

//添加开屏承载界面和最下方Banner的logo
- (void)addSpreadBackgroundAndLogo
{
    UIColor * bgColor = [UIColor whiteColor];
    if (self.rAdView.delegate && [self.rAdView.delegate respondsToSelector:@selector(adBackgroundColor)])
    {
        bgColor = [self.rAdView.delegate adBackgroundColor];
    }
    CGSize screenSize = [UIScreen mainScreen].bounds.size;

    UIViewController * modalVc;
    if (self.rAdView.delegate && [self.rAdView.delegate respondsToSelector:@selector(viewControllerForShowModal)]) {
        modalVc = [self.rAdView.delegate viewControllerForShowModal];
    } else {
        modalVc = [UIApplication sharedApplication].keyWindow.rootViewController;
    }
    
    if (modalVc.prefersStatusBarHidden) {
        self.rAdView.frame = CGRectMake(0, 0, screenSize.width, screenSize.height);
    }else{
        self.rAdView.frame = CGRectMake(0, STATUSBARHIDDENHEIGHT, screenSize.width, screenSize.height - STATUSBARHIDDENHEIGHT);
    }

    self.adSpreadView = [[UIImageView alloc] initWithFrame:self.rAdView.bounds];
    _adSpreadView.backgroundColor = bgColor;
    [self.rAdView addSubview:_adSpreadView];
    
    NSString *bgImgName = nil;
    if (self.rAdView.delegate && [self.rAdView.delegate respondsToSelector:@selector(adBackgroundImgName)])
    {
        bgImgName = [self.rAdView.delegate adBackgroundImgName];
    }
    if (bgImgName && [bgImgName length] > 0)
    {
        _adSpreadView.image = [UIImage imageNamed:bgImgName];
    }

    NSString *logoName = nil;
    if (self.rAdView.delegate && [self.rAdView.delegate respondsToSelector:@selector(logoImgName)])
    {
        logoName = [self.rAdView.delegate logoImgName];
    }
    self.adPrefSize = _adSpreadView.frame.size;
    
    UIImage *img = [UIImage imageNamed:logoName];
    if (!img) {
        img = [UIImage imagesNamedFromCustomBundle:@"adview_spread_logo.png"];
    }
    CGSize imgSize = img.size;
    [AdViewExtTool scaleEnlargesTheSize:&screenSize toSize:&imgSize];   //将图片的尺寸按照屏幕宽度等比缩放
    UIImageView *imgView = [[UIImageView alloc] initWithImage:img];
    imgView.tag = LOGOIMAGE_TAG;
    imgView.frame = CGRectMake(0, _adSpreadView.frame.size.height - imgSize.height, imgSize.width, imgSize.height);
    [_adSpreadView addSubview:imgView];
    
    AdViewLogDebug(@"%s - logo frame:%@", __FUNCTION__,NSStringFromCGRect(imgView.frame));
    AdViewLogDebug(@"%s - adSpreadView frame:%@", __FUNCTION__,NSStringFromCGRect(_adSpreadView.frame));
    
    void (* messageSend)(id, SEL, id) = (void (*)(id, SEL, id))objc_msgSend;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    //对外demo里不要这样调用私有API
    messageSend(self.rAdView,@selector(showWithRootViewController:),modalVc);
#pragma clang diagnostic pop
    
    [self cancelAnimTimer];
    self.animTimer = [NSTimer scheduledTimerWithTimeInterval:SPREAD_EXIST_MOST
                                                      target:self
                                                    selector:@selector(performDissmissSpread)
                                                    userInfo:nil
                                                     repeats:NO];
}

- (void)performDissmissSpread
{
    [self cancelDelayTimer];
    [self cancelAnimTimer];
    if (self.didClosedSpread) return;
    
    if (self.rAdView.delegate && [self.rAdView.delegate respondsToSelector: @selector(adViewDidDismissScreen:)] && !self.rolloverManager)
    {
        [self.rAdView.delegate adViewDidDismissScreen:self.rAdView];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:1 animations: ^{
            self.rAdView.alpha = 0;
        } completion:^(BOOL finished) {
            [self.rAdView removeFromSuperview];
            if (!self.statusBarHiden)
            {
                [[UIApplication sharedApplication] setStatusBarHidden:NO];
            }
        }];
    });
    
    [self resetProtocolCount];
    
    self.didClosedSpread = YES;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    AdViewLogDebug(@"Spread closed");
}

#pragma mark - AdInstl
- (BOOL)adinstlIsOutOfSurvivalCycle
{
    return [self isOutOfSurvivalCycle:self.adapter.adPlatType with:_advertType];
}

- (void)adinstlShowWithController:(UIViewController *)controller {
    if (controller == nil) {
        controller = [UIApplication sharedApplication].keyWindow.rootViewController;
    }
    
    if (self.videoController) {
        __weak __typeof(self) weakSelf = self;;
        [controller presentViewController:self.videoController animated:YES completion:^{
            [weakSelf.videoController play];
        }];
    } else if (self.rolloverManager) {
        [self.rolloverManager showInstlWithController:controller];
    } else {
        [controller.view addSubview:self.rAdView];
    }
}

/*
 * 旋转适配
 */
- (void)adInstlOrientationChanged
{
    if (_advertType == AdViewBanner) return;

    CGRect startRect = [[UIScreen mainScreen] bounds];
    BOOL  bIsLand = [AdViewExtTool getDeviceDirection];
    CGFloat width =  bIsLand?startRect.size.height:startRect.size.width;
    CGFloat height =  bIsLand?startRect.size.width:startRect.size.height;
    if (bIsLand && width < height) {
        width += height;
        height = width - height;
        width = width - height;
    }
    
    CGFloat heightSeven =  bIsLand?height+([UIApplication sharedApplication].statusBarHidden?0:STATUSBARHIDDENHEIGHT):height;
    
    CGFloat showScale = 1;
    if (!isWebView)
    {
        showScale = (float)SHOWTHEPROPORTION;
    }
    
    //展示的区域
    CGSize showArea;
    if (![UIApplication sharedApplication].statusBarHidden)
    {
        showArea = CGSizeMake(width * showScale, height * showScale - STATUSBARHIDDENHEIGHT);
    }
    else
    {
        showArea = CGSizeMake(width * showScale, height * showScale);
    }
    CGSize showSize;//展示区域比例
    showSize = CGSizeMake(showArea.width * self.scaleSize, showArea.height * self.scaleSize);
    //展示的区域
    
    CGRect rect = CGRectMake(0,0, width, height);
    
    self.rAdView.frame = rect;
    
    if (![UIApplication sharedApplication].statusBarHidden)
    {
        height = height - STATUSBARHIDDENHEIGHT;
    }
    
    CGFloat LandscapeHeight = ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)?heightSeven:height;
    
    CGSize  rotation = [self.adContent withTheProportion:self.adContent.adInstlImageSize withSize:showSize];
    
    if (self.adContent.adShowType == AdViewAdSHowType_Video)
    {
        self.loadingAdView.frame = self.rAdView.frame;
    }
    else
    {
        self.loadingAdView.frame = CGRectMake(0, 0, rotation.width, rotation.height);
        self.loadingAdView.center = CGPointMake(width/2, (LandscapeHeight - moveCenterHeight *2)/2);
    }
    
    self.closeButton.center = CGPointMake(self.loadingAdView.frame.origin.x + self.loadingAdView.frame.size.width - self.closeButton.bounds.size.width / 2 - 4,
                                          self.loadingAdView.frame.origin.y + self.closeButton.bounds.size.height / 2 + 4);
    
    // 调整广告字样以及logo位置
    UIImageView * tagView = [self.loadingAdView viewWithTag:ADVIEW_LABEL_TAG]; //右下角
    if (tagView)
    {
        CGRect tFrame = tagView.frame;
        tFrame.origin.x = self.loadingAdView.frame.size.width - tFrame.size.width;
        tFrame.origin.y = self.loadingAdView.frame.size.height - tFrame.size.height;
        tagView.frame = tFrame;
    }

    UIImageView * ggView = [self.loadingAdView viewWithTag:ADVIEW_GG_LABEL_TAG]; //广告字样
    if (ggView)
    {
        CGRect gFrame = ggView.frame;
        gFrame.origin.y = self.loadingAdView.frame.size.height - gFrame.size.height;
        ggView.frame = gFrame;
    }
    
    //确定插屏点击区域
    CGRect area = self.loadingAdView.frame;
    self.adContent.clickSize = area;
}

//点击activity 关闭界面
-(void)closeAdInstl
{
    [self.rAdView removeFromSuperview];
}

//添加插屏关闭按钮
- (void)addCloseButtonInFrame:(CGRect)frame
{
    UIButton * buttton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage * closeImage = [UIImage imagesNamedFromCustomBundle:@"AdInStLClOsE.png"];
    float closeButtonSize = [AdViewExtTool getDeviceIsIpad] ? 35 : 35;
    buttton.bounds = CGRectMake(0, 0, closeButtonSize, closeButtonSize);
    
    self.closeButton = buttton;
    _closeButton.center = CGPointMake(frame.origin.x + frame.size.width - _closeButton.bounds.size.width,
                                      frame.origin.y + _closeButton.bounds.size.height);
    [_closeButton addTarget:self action:@selector(closeAdInstlView:) forControlEvents:UIControlEventTouchUpInside];
    
    [_closeButton setBackgroundImage:closeImage forState:UIControlStateNormal];
    [self.rAdView addSubview:_closeButton];
}

- (void)closeAdInstlView:(id)sender
{
    if (self.rAdView.delegate && [self.rAdView.delegate respondsToSelector: @selector(adViewDidDismissScreen:)])
    {
        [self.rAdView.delegate adViewDidDismissScreen:self.rAdView];
    }
    [self resetProtocolCount];
    
    if (sender != nil)
    {
        UIButton * button = (UIButton *)sender;
        [button removeFromSuperview];
    }
  
    [self.rAdView removeFromSuperview];
    
    isFirst = YES;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - display
- (void)animDisplay
{
    self.animTimer = nil;
    [self displayAd:NO];
}

- (void)mixAnimDisplay
{
    [self cancelAnimTimer];
    [self.adContent animExchangeAd:self.rAdView];
    
    NSTimeInterval timeInterval = AD_INTERVAL / 6;
    self.animTimer = [NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(mixAnimDisplay) userInfo:nil repeats:NO];
}

- (void) cancelAnimTimer
{
    if (nil != _animTimer)
    {
        [_animTimer invalidate];
        self.animTimer = nil;
    }
}

- (void)cancelDelayTimer
{
    if (nil != _delayTimer)
    {
        [_delayTimer invalidate];
        self.delayTimer = nil;
    }
}

#pragma mark - 创建、展示广告
- (void)displayAd:(BOOL)isFirstDisplay
{
    UIColor* bgColor = [UIColor whiteColor];
    UIColor* textColor = [UIColor blackColor];
    
    if ([self.rAdView.delegate respondsToSelector:@selector(adBackgroundColor)])
    {
        bgColor = [self.rAdView.delegate adBackgroundColor];
    }
    
    if ([self.rAdView.delegate respondsToSelector:@selector(adTextColor)])
    {
        textColor = [self.rAdView.delegate adTextColor];
    }
    
    if ([self.rAdView.delegate respondsToSelector:@selector(gradientBgType)])
    {
        self.adContent.adRenderBgColorType = [self.rAdView.delegate gradientBgType];
    }
    
    switch (_advertType)
    {
        case AdViewBanner:
        {
            self.loadingFirstDisplay = isFirstDisplay;
            [self loadBannerWithBgColor:bgColor textColor:textColor];
            break;
        }
        case AdViewInterstitial:
        {
            [self.rAdView setValue:[NSNumber numberWithBool:NO] forKey:@"interstitialIsReady"];
            [self loadInstalWithBgColor:bgColor textColor:textColor];
            break;
        }
        case AdViewSpread:
        {
            [self loadAdSpreadView];
            break;
        }
        default:
            break;
    }
}

//加载Banner
- (void)loadBannerWithBgColor:(UIColor *)bgColor textColor:(UIColor *)textColor
{
    //非视频广告
    if (self.adContent.adShowType != AdViewAdSHowType_Video)
    {
        UIView * iv = [self.adContent makeBannerWithSize:self.adPrefSize
                                             withBgColor:bgColor
                                           withTextColor:textColor
                                         withWebDelegate:self];
        [self cancelAnimTimer];
        
        //如果是HTML, 在webview回调中添加loadingAdView到视图上
        self.loadingAdView = iv;
        
        //Gif不走webview逻辑(不走HTML延迟加载)
        BOOL bWebView = ([iv isKindOfClass:[AdViewMraidWebView class]] && self.adContent.adShowType != AdViewAdSHowType_FullGif);

        //图文广告
        if (self.adContent.adShowType == AdViewAdSHowType_AdFillImageText && [self.adContent needAnimDisplay])
        {
            NSTimeInterval timeInterval = AD_INTERVAL / 6;
            self.animTimer = [NSTimer scheduledTimerWithTimeInterval:timeInterval
                                                              target:self
                                                            selector:@selector(mixAnimDisplay)
                                                            userInfo:nil
                                                             repeats:NO];
        }
        else
        {
            //非图文 且不是HTML
            if (!bWebView)
            {
                if ([self.adContent currentFrame] < [self.adContent totalFrame])
                {
                    NSTimeInterval timeInterval = AD_INTERVAL * 1 / [self.adContent totalFrame];
                    self.animTimer = [NSTimer scheduledTimerWithTimeInterval:timeInterval
                                                                      target:self
                                                                    selector:@selector(animDisplay)
                                                                    userInfo:nil
                                                                     repeats:NO];
                }
            }
        }
        
        //如果不是webview 或 已经加载完毕 则添加到界面上
        if (!bWebView || self.adContent.adWebLoaded)
        {
            [self performSelector:@selector(transitIntoBannerView:) withObject:[NSNumber numberWithBool:self.loadingFirstDisplay]];
            
            self.omsdkManager = [[AdViewOMAdImageManager alloc] init];
            [_omsdkManager setMainAdview:self.rAdView];
            [_omsdkManager setFriendlyObstruction:[iv viewWithTag:ADVIEW_LABEL_TAG]];
            [_omsdkManager setFriendlyObstruction:[iv viewWithTag:ADVIEW_GG_LABEL_TAG]];
            [_omsdkManager startMeasurement];
        }
    }
    else
    {
        AdViewVideoViewController * controller = [[AdViewVideoViewController alloc] initWithDelegate:self adverType:_advertType];
        controller.enableAutoClose = NO;
        controller.allowAlertView = NO;
        [controller loadVideoWithData:[self.adContent.adBody dataUsingEncoding:NSUTF8StringEncoding]];
        UIView * contenView = [controller valueForKey:@"contentView"];
        contenView.frame = CGRectMake(0, 0, _adPrefSize.width, _adPrefSize.height);
        [self.adContent addLogoLabelWithView:contenView adType:_advertType];    //加logo
        self.videoController = controller;
    }
}

- (void)loadInstalWithBgColor:(UIColor *)bgColor textColor:(UIColor *)textColor
{
    if (self.adContent.adShowType != AdViewAdSHowType_Video)
    {
        isFirst = NO;
        [self cancelAnimTimer];
        [_activity stopAnimating];
        UIView * iv = [self.adContent makeAdInstlViewWithSize:self.adPrefSize
                                                  withBgColor:bgColor
                                                withTextColor:textColor
                                              withWebDelegate:self];
        self.loadingAdView = iv;
        //因为gif也用的webView展示，所以这里判断时如果是gif bWebView == NO；
        BOOL bWebView = ([iv isKindOfClass:[AdViewMraidWebView class]]) && self.adContent.adShowType != AdViewAdSHowType_FullGif;
        
        if (!bWebView || self.adContent.adWebLoaded) {
            [self adjustInstlView:iv];
            [self.rAdView setValue:[NSNumber numberWithBool:YES] forKey:@"interstitialIsReady"];
            
            //纯图片类型OMSDK上报
            self.omsdkManager = [[AdViewOMAdImageManager alloc] init];
            [_omsdkManager setMainAdview:self.rAdView];
            [_omsdkManager setFriendlyObstruction:[iv viewWithTag:ADVIEW_LABEL_TAG]];
            [_omsdkManager setFriendlyObstruction:[iv viewWithTag:ADVIEW_GG_LABEL_TAG]];
            [_omsdkManager startMeasurement];

            if ([self.rAdView.delegate respondsToSelector: @selector(didReceivedAd:)])
            {
                [self.rAdView.delegate didReceivedAd:self.rAdView];
            }
        }
        //纠正背景的位置
        CGRect startRect = [[UIScreen mainScreen] bounds];
        BOOL bIsLand = [AdViewExtTool getDeviceDirection];
        CGFloat width = bIsLand?startRect.size.height:startRect.size.width;
        CGFloat height = bIsLand?startRect.size.width:startRect.size.height;
        if (bIsLand && width < height)
        {
            width += height;
            height = width - height;
            width = width - height;
        }
        CGRect rect = CGRectMake(startRect.origin.x,startRect.origin.y, width, height);
        self.rAdView.frame = rect;
    }
    else
    {
        AdViewVideoViewController * controller = [[AdViewVideoViewController alloc] initWithDelegate:self
                                                                                           adverType:AdViewInterstitial];
        controller.enableAutoClose = NO;
        controller.allowAlertView = YES;
        [controller loadVideoWithData:[self.adContent.adBody dataUsingEncoding:NSUTF8StringEncoding]];
        self.adContent.adInstlImageSize = controller.view.frame.size;
        self.videoController = controller;
    }
}

//添加插屏到Adview承载界面
- (void)adjustInstlView:(UIView*)view
{
    [self.rAdView addSubview:view];
    if (self.adContent.adShowType != AdViewAdSHowType_Video)
    {
        [self addCloseButtonInFrame:view.frame];
    }
    [self adInstlOrientationChanged];//给定界面的center
    
    // 加载到别的页面为了让wkwebview渲染出来，提前判断出是否为白条
    if ([view isKindOfClass:[AdViewMraidWebView class]])
    {
        CGSize size = [UIScreen mainScreen].bounds.size;
        UIView * newView = [[UIView alloc] initWithFrame:CGRectMake(size.width + 10, 0, self.rAdView.frame.size.width, self.rAdView.frame.size.height)];
        [newView addSubview:self.rAdView];
        [[UIApplication sharedApplication].keyWindow.rootViewController.view addSubview:newView];
    }
}

//将广告添加到底层上
- (void)transitIntoBannerView:(NSNumber*)firstDisplayObj
{
    if (nil == self.loadingAdView) return;
    
    //清理承载view上的子视图
    long subviewCount = 0;
    subviewCount = [[self.rAdView subviews] count];
    CGSize toSize = _loadingAdView.frame.size;
    if (subviewCount > 2)
    {
        for (long i = subviewCount - 1; i >= 1; i--)
        {
            UIView* view = [[self.rAdView subviews] objectAtIndex:i];
            [view removeFromSuperview];
        }
    }
    
    subviewCount = [[self.rAdView subviews] count];
    if (subviewCount == 0)
    {
        [self.rAdView addSubview:_loadingAdView];
    }
    else if (subviewCount == 2)
    {
        int nAnimateType = (arc4random() % 4) + 1 + UIViewAnimationTransitionNone;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationTransition:nAnimateType forView:self.rAdView cache:YES];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:1.0f];
    
        UIView *currView = [[self.rAdView subviews] objectAtIndex:0];
        [self.rAdView addSubview:_loadingAdView];
        [currView removeFromSuperview];

        [UIView commitAnimations];
    }
    
    CGRect frm = self.rAdView.frame;
    frm.size = toSize;
    [self.rAdView setAutoresizesSubviews:NO];
    self.rAdView.frame = frm;
    
    self.loadingAdView = nil;

    adClicking = NO;
    _hitTested = NO;
    
    if ([firstDisplayObj boolValue] && self.rAdView.delegate && [self.rAdView.delegate respondsToSelector: @selector(didReceivedAd:)])
    {
        [self.rAdView.delegate didReceivedAd:self.rAdView];
    }
}

#pragma mark - 创建开屏
- (void)loadAdSpreadView {
    CGFloat availableWidth  = _adPrefSize.width;
    CGFloat availableHeight = _adPrefSize.height - [_adSpreadView viewWithTag:LOGOIMAGE_TAG].bounds.size.height;
    CGSize availableSize = CGSizeMake(availableWidth, availableHeight);
    UIView * iv = [self.adContent makeAdSpreadViewWithSize:availableSize
                                           withWebDelegate:self];
    if ([iv.subviews.firstObject isKindOfClass:[AdViewMraidWebView class]]) {   //如果是webview的,等待webview加载回调之后再倒计时
        self.loadingAdView = iv;
        self.loadingAdView.alpha = 0;       //是webview设置透明然后加上去.等待加载完毕再开始倒计时
    } else {
            [self spreadDisplayCountDown];  //不是webview的直接开始倒计时
    }
    [self spreadViewAddContentView:iv];     //因为wkWebview必须先添加到视图上,才会开始渲染,所以先加上.但是alpha设置为0
}

//开屏底层(已经添加到rAdview) 添加广告素材View
- (void)spreadViewAddContentView:(UIView *)contentView
{
    if (contentView) {
        [self.adSpreadView addSubview:contentView];
    }
    
    UIImageView * logoView = (UIImageView*)[self.adSpreadView viewWithTag:LOGOIMAGE_TAG];
    if (logoView)
    {
        if (self.adContent.spreadType == 2 || self.adContent.spreadVat == AdSpreadShowTypeImageCover)
        {
            [logoView removeFromSuperview];
        }
        else if(self.adContent.spreadType == 1)
        {
            if (self.adContent.spreadVat == AdSpreadShowTypeAllCenter)
            {
                CGRect rect = logoView.frame;
                rect.origin.y = contentView.frame.size.height + contentView.frame.origin.y;
                logoView.frame = rect;
            }
            [self.adSpreadView bringSubviewToFront:logoView];
        }
    }
    
    inActiviteTime = [[NSDate date] timeIntervalSince1970];
    if ([self.rAdView.delegate respondsToSelector: @selector(didReceivedAd:)]) {
        [self.rAdView.delegate didReceivedAd:self.rAdView];
    }
}

//开屏展示后的倒计时
- (void)spreadDisplayCountDown {
    [self cancelAnimTimer];
    _spreadShowTime = _adContent.forceTime + _adContent.relayTime;
    
    //倒计时l开始前等待期
    self.animTimer = [NSTimer scheduledTimerWithTimeInterval:_adContent.forceTime
                                                      target:self
                                                    selector:@selector(delayShowSpread)
                                                    userInfo:nil
                                                     repeats:NO];
}

- (void)transitIntoAdWKView:(NSNumber*)firstDisplayObj
{
    UInt16 subviewCount = [[self.rAdView subviews] count];
    if (subviewCount > 2)
    {
        for (long i = subviewCount - 1; i >= 1; i--)
        {
            UIView* view = [[self.rAdView subviews] objectAtIndex:i];
            [view removeFromSuperview];
        }
    }
    subviewCount = [[self.rAdView subviews] count];
    if (subviewCount == 2)
    {
        int nAnimateType = (arc4random() % 4) + 1 + UIViewAnimationTransitionNone;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationTransition:nAnimateType forView:self.rAdView cache:YES];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:1.0f];
        
        UIView *currView = [[self.rAdView subviews] lastObject];
        [currView removeFromSuperview];
        
        [UIView commitAnimations];
    }
    self.loadingAdView = nil;
    
    adClicking = NO;
    _hitTested = NO;
    
    if ([firstDisplayObj boolValue] && [self.rAdView.delegate respondsToSelector: @selector(didReceivedAd:)])
    {
        [self.rAdView.delegate didReceivedAd:self.rAdView];
    }
}

#pragma mark - control
- (void)pauseRequestAd
{
    if (nil != _adRequestTimer) [_adRequestTimer invalidate];
    
    if (_advertType != AdViewSpread)
    {
        [self cancelAnimTimer];
    }
    self.adRequestTimer = nil;
    adNotRequest = true;
}

- (void)resumeRequestAd
{
    if (!adNotRequest) return;
    
    adNotRequest = false;
    [self setupBannerAutoAdRequest];
}

- (void)resignActive:(NSNotification *)notification
{
    AdViewLogDebug(@"App become inactive, AdViewView will stop requesting ads");
    if (_advertType == AdViewSpread)
    {
        [self cancelAnimTimer];
        [self cancelDelayTimer];
        self.didResignActive = YES;
    }
    else if(_advertType == AdViewBanner)
    {
        [self pauseRequestAd];
    }
}

- (void)becomeActive:(NSNotification *)notification
{
    AdViewLogDebug(@"App become active, AdViewView will resume requesting ads");
    if (_advertType == AdViewSpread)
    {
        if(!self.didResignActive)
        {
            return;
        }
        NSTimeInterval afterTime = [[NSDate date] timeIntervalSince1970] - inActiviteTime;
        if (afterTime >= _spreadShowTime)
        {
            [self performDissmissSpread];
        }
        else if(afterTime >= _adContent.forceTime)
        {
            self.adContent.relayTime = _spreadShowTime - afterTime;
            [self delayShowSpread];
        }
        else if(afterTime >= 0)
        {
            self.animTimer = [NSTimer scheduledTimerWithTimeInterval:_adContent.forceTime - afterTime target:self selector:@selector(delayShowSpread) userInfo:nil repeats:NO];
        }
    }
    else if(_advertType == AdViewBanner)
    { // 从后台激活后如果超过广告生存周期，需要做相应处理，banner立即请求新广告；插屏关闭当前显示
        [self resumeRequestAd];
    }
    else if (_advertType == AdViewInterstitial)
    {
        if ([self isOutOfSurvivalCycle:self.adapter.adPlatType with:_advertType] && self.rAdView.superview != nil)
            [self closeAdInstlView:nil];
    }
}

//设置自动请求
- (void)setupBannerAutoAdRequest
{
    //只有banner才自动请求
    if (_advertType == AdViewBanner) {
        
        int interval = AD_INTERVAL;
        if (nil != self.rAdView.delegate && [self.rAdView.delegate respondsToSelector:@selector(autoRefreshInterval)])
        {
            interval = [self.rAdView.delegate autoRefreshInterval];
        }
        
        //如果超过广告周期需要立刻刷新
        if ([self isOutOfSurvivalCycle:self.adapter.adPlatType with:_advertType])
        {
            [self resetProtocolCount];
            [self releaseLastAdThenRequestGetNewAd];
        }
        
        if (interval < 1) return;
        
        if (interval < AD_INTERVAL_LIMIT) interval = AD_INTERVAL_LIMIT;
        
        [self setupAdRequestTimer:interval];
        
    }
}

//设置banner自动请求
- (void)setupAdRequestTimer:(NSInteger)timeInterval
{
    if (_advertType == AdViewBanner && BANNER_AUTO_REQUEST && _adverRequestType != AdViewRewardVideo)
    {
        if (adNotRequest) return;
        self.adRequestTimer = [NSTimer scheduledWeakTimerWithTimeInterval:timeInterval
                                                                   target:self
                                                                 selector:@selector(releaseLastAdThenRequestGetNewAd)
                                                                 userInfo:nil
                                                                  repeats:NO];
    }
}

- (void)registerObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(adInstlOrientationChanged)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
}

static const double AD_SURVIVAL_CYCLE = 1200;
#define FINISH_LOAD_TIME @"finishLoadTime_%zd_%zd"
/**
 * 存储广告加载成功的时间戳
 */
- (void)storeFinishLoadTime:(AdViewAdPlatType)adPlatType with:(AdvertType)adType {
    NSTimeInterval finishLoadTime = [[NSDate date] timeIntervalSince1970];
    NSString *fltStr = [NSString stringWithFormat:FINISH_LOAD_TIME, adPlatType,adType];
    [[AdViewExtTool sharedTool] storeObject:[NSNumber numberWithDouble:finishLoadTime] forKey:fltStr];
}

/**
 * 判断广告生存的周期是否超过其生存周期
 */
- (BOOL)isOutOfSurvivalCycle:(AdViewAdPlatType)adPlatType with:(AdvertType)adType {
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSString *fltStr = [NSString stringWithFormat:FINISH_LOAD_TIME,adPlatType,adType];
    NSTimeInterval finishLoadTime = 0;
    NSNumber *temp = (NSNumber*)[[AdViewExtTool sharedTool] objectStoredForKey:fltStr];
    if (nil != temp)
        finishLoadTime = [temp doubleValue];
    else
        return NO;
    return now - finishLoadTime > AD_SURVIVAL_CYCLE;
}

#pragma mark - AdConnections manage
- (void)cancelAdConnections {
    @synchronized(self.adConnections) {
        AdViewLogDebug(@"will cancel %d adConnections", [self.adConnections count]);
        for (int i = 0; i < [self.adConnections count]; i++) {
            [[self.adConnections objectAtIndex:i] cancel];
        }
        [self.adConnections removeAllObjects];
    }
}

- (void)removeAdConnection:(AdViewConnection*)connection
{
    @synchronized(self.adConnections) {
        [connection cancel];
        [self.adConnections removeObject:connection];
    }
}

//释放上一个广告,然后请求下一个广告,用于timer自动请求
- (void)releaseLastAdThenRequestGetNewAd {
    [_omsdkManager finishMeasurement];  //OMSDK汇报之前的广告finish
    self.adContent = nil;
    [self requestGet];
}

//请求广告
- (void)requestGet
{
    requestTime = [[NSDate date] timeIntervalSince1970];
    clickNumber = 0;
    self.rolloverManager = nil; // 每次发生新请求的时候重置
    self.adRequestTimer = nil;
    [self cancelAnimTimer];

    if (nil == self.rAdView.delegate)
    {
        AdViewLogDebug (@"delegate is nil, will not request.");
        return;
    }
    
    BOOL test_mode = NO;
    AdViewLogDebug (@"Request the ad from ad serer");
    NSString* appId = [self.rAdView.delegate appId];
    
    if (self.rAdView.delegate && [self.rAdView.delegate respondsToSelector:@selector(testMode)])
    {
        test_mode = [self.rAdView.delegate testMode];//正式/测试服务器切换
    }
    
    BOOL useHtml5 = NO;
    if (self.rAdView.delegate && [self.rAdView.delegate respondsToSelector:@selector(usingHTML5)])
    {
        useHtml5 = [self.rAdView.delegate usingHTML5];
    }
    
    BOOL subjectToGDPR = NO;
    NSString * consentString = nil;
    
    BOOL CMPPresen = NO;
    NSString * parsedPurposeConsents = nil;
    NSString * parsedVendorConsents  = nil;
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    
    //如果保存了则全部使用保存的GDPR设置,否则使用协议设置
    if ([userDefaults objectForKey:AdView_IABConsent_CMPPresent]) {
        CMPPresen = [[userDefaults objectForKey:AdView_IABConsent_CMPPresent] boolValue];
        subjectToGDPR = [[userDefaults objectForKey:AdView_IABConsent_SubjectToGDPR] boolValue];
        consentString = [userDefaults objectForKey:AdView_IABConsent_ConsentString];
        parsedPurposeConsents = [userDefaults objectForKey:AdView_IABConsent_ParsedPurposeConsents];
        parsedVendorConsents = [userDefaults objectForKey:AdView_IABConsent_ParsedVendorConsents];
    } else {
        if ([self.rAdView.delegate respondsToSelector:@selector(subjectToGDPR)]) {
            subjectToGDPR = [self.rAdView.delegate subjectToGDPR];
        }
        
        if ([self.rAdView.delegate respondsToSelector:@selector(userConsentString)]) {
            consentString = [self.rAdView.delegate userConsentString];
        }
        
        if ([self.rAdView.delegate respondsToSelector:@selector(CMPPresent)]) {
            CMPPresen = [self.rAdView.delegate CMPPresent];
        }
        
        if ([self.rAdView.delegate respondsToSelector:@selector(parsedPurposeConsents)]) {
            parsedPurposeConsents = [self.rAdView.delegate parsedPurposeConsents];
        }
        
        if ([self.rAdView.delegate respondsToSelector:@selector(parsedVendorConsents)]) {
            parsedVendorConsents = [self.rAdView.delegate parsedVendorConsents];
        }
    }
    
    AdViewAdCondition * condition = [[AdViewAdCondition alloc] init];
    condition.appId = appId;
    condition.positionId = _positionId;
    condition.adTest = test_mode;
    condition.adSize = _adPrefSize;
    condition.adverType = _adverRequestType;
    condition.bUseHtml5 = useHtml5;
    condition.gdprApplicability = subjectToGDPR;
    condition.consentString = consentString;
    condition.CMPPresent = CMPPresen;
    condition.parsedPurposeConsents = parsedPurposeConsents;
    condition.parsedVendorConsents = parsedVendorConsents;
    condition.CCPAString = [userDefaults objectForKey:AdView_IABConsent_CCPA];
    
    if ([self.rAdView.delegate respondsToSelector:@selector(getLocation)]) {
        CLLocation * location = [self.rAdView.delegate getLocation];
        if (location) {
            condition.hasLocationVal = YES;
            condition.latitude = location.coordinate.latitude;
            condition.longitude = location.coordinate.longitude;
            condition.accuracy = location.horizontalAccuracy;
            [[AdViewExtTool sharedTool] setValue:[NSString stringWithFormat:@"%lf", condition.latitude] forKey:@"{LATITUDE}"];
            [[AdViewExtTool sharedTool] setValue:[NSString stringWithFormat:@"%lf", condition.longitude] forKey:@"{LONGITUDE}"];
        }
    }
    
    if ([self.rAdView.delegate respondsToSelector:@selector(appPwd)]) {
        condition.appPwd = [self.rAdView.delegate appPwd];
    }
    
    NSNotificationCenter *notifCenter = [NSNotificationCenter defaultCenter];
    [notifCenter removeObserver:self];
    [notifCenter addObserver:self
                    selector:@selector(adInstlOrientationChanged)
                        name:UIApplicationDidChangeStatusBarOrientationNotification
                      object:nil];
    [notifCenter addObserver:self
                    selector:@selector(resignActive:)
                        name:UIApplicationWillResignActiveNotification
                      object:nil];
    [notifCenter addObserver:self
                    selector:@selector(becomeActive:)
                        name:UIApplicationDidBecomeActiveNotification
                      object:nil];
    
    //如果是开屏 直接添加到界面上
    if (_advertType == AdViewSpread) {
        [self addSpreadBackgroundAndLogo];
    }
    
    //⚠️ 开始请求广告
    [self requestAdWithConnetion:condition];
}

//广告请求
- (void)requestAdWithConnetion:(AdViewAdCondition*)condition {
    AdViewAdGetRequest * req = [AdViewAdGetRequest requestWithConditon:condition
                                                               adapter:self.adapter];
    AdViewConnection * con = [[AdViewConnection alloc] initWithGetRequest:req
                                                                  adapter:self.adapter
                                                                 delegate:self];
    AdViewLogInfo(@"%s - %@",__FUNCTION__,con.adRequest.httpRequest);
    [con startConnection];
    [self.adConnections addObject:con];
}

//展示汇报
- (void)requestDisplay {
    AdViewLogDebug (@"Request display ad");
    AdViewAdDisplayRequest * req = [AdViewAdDisplayRequest requestWithAdContent:self.adContent
                                                                        Adapter:self.adapter];
    AdViewConnection *con = [[AdViewConnection alloc] initWithDisplayRequest:req
                                                                    delegate:self];
    [con startConnection];
    [self.adConnections addObject:con];
}

//点击汇报
- (void)requestClick {
    AdViewLogDebug (@"Request click ad");
    AdViewAdClickRequest* req = [AdViewAdClickRequest requestWithAdContent:self.adContent
                                                                   Adapter:self.adapter];
    AdViewConnection *con = [[AdViewConnection alloc] initWithClickRequest:req
                                                                  delegate:self];
    [con startConnection];
    [self.adConnections addObject:con];
    clickNumber++;
}

#pragma mark - ConnectionDelegate
- (void)adConnection:(AdViewConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    
}

- (void)adConnection:(AdViewConnection *)connection didFailWithError:(NSError *)error
{
    [[AdViewExtTool sharedTool] storeObject:[NSNumber numberWithBool:NO] forKey:@"lastRequestAdStatus"];
    adClicking = NO;
    
    //设置广告状态为不可见
    [_adViewWebView setIsViewable:NO];
    
    //如果是展示请求失败 则去Rollover打底请求
    if (connection.connectionType == AdViewConnectionTypeGetRequest)
    {
        [self rollOverWithError:error];
    }
    else if (connection.connectionType == AdViewConnectionTypeDisplayRequest)
    {
        if (error.code == -65536)
        {
            AdViewLogDebug(@"%s - Don't display, the ad id is disable instructor",__FUNCTION__);
        }
        else
        {
            AdViewLogDebug(@"%s - Network error.",__FUNCTION__);
        }
    }
    else if ( connection.connectionType == AdViewConnectionTypeClickRequest &&![[AdViewReachability reachabilityForInternetConnection] currentReachabilityStatus])
    {
        if (_advertType != AdViewNative)
        {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"当前网络不可用" message:@" " delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alert show];
        }
        else
        {
            if (self.nativeAdFailLoadBlock)
            {
                self.nativeAdFailLoadBlock(error);
            }
        }
    }
    [self removeAdConnection:connection];
}

- (void)adConnection:(AdViewConnection *)connection didReceiveAdContent:(NSMutableArray *)contentArr
{
    AdViewContent * theAdContent = [contentArr firstObject];
    AdViewLogDebug (@"received the ad from ad serer: old id: %@, newid: %@", self.adContent.adId, theAdContent.adId);

    //如果是0,则不忽略相同广告
#if 1
    if (theAdContent != self.adContent)
    {
        if (self.advertType != AdViewSpread)
        {
            [self cancelAnimTimer]; //停止广告切换
        }
        self.adContent = theAdContent;
        self.adContent.adPlatType = self.adapter.adPlatType;
    }
    adNeedDisplay = YES;
#else
    if (![self.adContent.adId isEqualToString:theAdContent.adId]) {
        /*
         * request to Display
         */
        self.adContent = theAdContent;
        adNeedDisplay = YES;
        
    } else {
        /*
         * Setup Timer to fetch next Ad.
         */
        adNeedDisplay = NO;
    }
#endif
    if (_advertType == AdViewNative && self.nativeAdRecieveDataBlock)
    {
        self.nativeAdRecieveDataBlock([contentArr copy]);
        adNeedDisplay = NO;
    }
}

//请求成功
- (void)adConnectionDidFinishLoading:(AdViewConnection *)connection
{
    switch (connection.connectionType)
    {
        case AdViewConnectionTypeGetRequest: {
            //存储加载成功时间
            [self storeFinishLoadTime:self.adapter.adPlatType with:_advertType];
            [[AdViewExtTool sharedTool] storeObject:[NSNumber numberWithBool:YES] forKey:@"lastRequestAdStatus"];
            if (adNeedDisplay) {
                if (_advertType == AdViewInterstitial) {
                    [self displayAd:YES];
                } else {
                    if (self.adapter.bIgnoreShowRequest) {
                        [self displayAd:YES];
                        [self setupBannerAutoAdRequest];
                        [self reportDisplayOrClickInfoToOther:YES];
                    } else {
                        if (_advertType != AdViewNative) {
                            [self displayAd:YES];
                        }
                        [self requestDisplay];
                        [self setupBannerAutoAdRequest];
                        [self reportDisplayOrClickInfoToOther:YES];
                    }
                }
            } else {
                [self setupBannerAutoAdRequest];
            }
            break;
        }
        case AdViewConnectionTypeDisplayRequest:
            break;
        case AdViewConnectionTypeClickRequest:
            adClicking = NO;
            break;
        default:
            break;
    }
    [self removeAdConnection:connection];
}

- (BOOL)isNeedCache
{
    if (self.rAdView.delegate && [self.rAdView.delegate respondsToSelector:@selector(usingCache)])
    {
        return [self.rAdView.delegate usingCache];
    }
    return NO;
}


// 获取广点通转换的倍率（为上传广点通点击坐标用，与服务器向广点通请求广告的尺寸保持一致的基础做转换）
- (CGFloat)getScaleForGDTAD
{
    CGFloat scale = 1;
    int density = [AdViewExtTool getDensity];
    CGFloat dpi = density * 160;
    CGSize gdtSize = CGSizeZero;
    if (self.advertType == AdViewInterstitial)
    {
        if (dpi >= 320)
        {
            gdtSize.width = 600;
        }
        else
        {
            gdtSize.width = 300;
        }
        scale = gdtSize.width / self.loadingAdView.frame.size.width;
    }
    else if (self.advertType == AdViewBanner)
    {
        if (dpi < 160)
        {
            gdtSize.width = 240;
        }
        else if (dpi >= 160 && dpi < 240)
        {
            gdtSize.width = 320;
        }
        else if (dpi >= 240 && dpi < 320)
        {
            gdtSize.width = 480;
        }
        else if (dpi >= 320)
        {
            gdtSize.width = 640;
        }
        scale = gdtSize.width/self.rAdView.frame.size.width;
    }
    else if (self.advertType == AdViewSpread)
    {
        if (dpi < 320)
        {
            gdtSize.width = 320;
        }
        else
        {
            gdtSize.width = 640;
        }
        scale = gdtSize.width/self.adContent.spreadImgViewRect.size.width;
    }
    return scale;
}

static NSMutableDictionary *clickPositionDic;
static NSMutableDictionary *aBclickPositionDic;
- (void)setClickPositionDicWithTouchPoint:(CGPoint)touchPoint isBegan:(BOOL)isBegan
{
    if (!clickPositionDic)
    {
        clickPositionDic = [[NSMutableDictionary alloc] init];
    }
    
    if (!aBclickPositionDic)
    {
        aBclickPositionDic = [[NSMutableDictionary alloc] init];
    }
    
    CGRect suRect;
    if(self.advertType == AdViewInterstitial)
    {
        suRect = self.loadingAdView.frame;
    }
    else if (self.advertType == AdViewBanner)
    {
        suRect = CGRectMake(0, 0, self.rAdView.frame.size.width, self.rAdView.frame.size.height);
    }
    else if (self.advertType == AdViewSpread)
    {
        if (CGRectContainsPoint(self.adContent.spreadImgViewRect, touchPoint))
        {
            suRect = self.adContent.spreadImgViewRect;
        }
        else if (CGRectContainsPoint(self.adContent.spreadTextViewSize, touchPoint))
        {
            suRect = self.adContent.spreadTextViewSize;
        }
        else
        {
            suRect = CGRectMake(0, touchPoint.y, 0, 0);
        }
    }
    else if (self.advertType == AdViewNative)
    {
        suRect = CGRectMake(0, 0, self.adPrefSize.width, self.adPrefSize.height);
    }
    
    CGFloat position_x = touchPoint.x - suRect.origin.x;
    CGFloat position_y = touchPoint.y - suRect.origin.y;
    CGFloat aBPosition_x = position_x;
    CGFloat aBPosition_y = position_y;
    
    if (position_x <= 0 || position_x >= suRect.size.width)
    {
        position_x = -999;
        aBPosition_x = -999;
    }
    else
    {
        position_x = (position_x*1000)/suRect.size.width;
    }
    
    if (position_y <= 0 || position_y >= suRect.size.height)
    {
        position_y = -999;
        aBPosition_y = -999;
    }
    else
    {
        position_y = (position_y*1000/suRect.size.height);
    }

    CGFloat scale = [self getScaleForGDTAD];
    
    AdViewExtTool *tool = [AdViewExtTool sharedTool];
    if (self.adContent.adShowType == AdViewAdSHowType_WebView_Content || self.adContent.adShowType == AdViewAdSHowType_WebView)
    {
        [clickPositionDic setObject:[NSNumber numberWithFloat:position_x] forKey:@"down_x"];
        [clickPositionDic setObject:[NSNumber numberWithFloat:position_y] forKey:@"down_y"];
        [clickPositionDic setObject:[NSNumber numberWithFloat:position_x] forKey:@"up_x"];
        [clickPositionDic setObject:[NSNumber numberWithFloat:position_y] forKey:@"up_y"];
        [tool storeObject:[AdViewExtTool jsonStringFromDic:clickPositionDic] forKey:@"{RELATIVE_COORD}"];
        
        [aBclickPositionDic setObject:[NSNumber numberWithFloat:aBPosition_x] forKey:@"down_x"];
        [aBclickPositionDic setObject:[NSNumber numberWithFloat:aBPosition_y] forKey:@"down_y"];
        [aBclickPositionDic setObject:[NSNumber numberWithFloat:aBPosition_x] forKey:@"up_x"];
        [aBclickPositionDic setObject:[NSNumber numberWithFloat:aBPosition_y] forKey:@"up_y"];
        [tool storeObject:[AdViewExtTool jsonStringFromDic:aBclickPositionDic] forKey:@"{ABSOLUTE_COORD}"];
        
        // 广点通坐标宏
        CGFloat gdt_x = aBPosition_x==-999?-999:aBPosition_x*scale;
        CGFloat gdt_y = aBPosition_y==-999?-999:aBPosition_y*scale;
        [tool storeObject:[NSString stringWithFormat:@"%d", (int)gdt_x] forKey:@"__DOWN_X__"];
        [tool storeObject:[NSString stringWithFormat:@"%d", (int)gdt_x] forKey:@"__UP_X__"];
        [tool storeObject:[NSString stringWithFormat:@"%d", (int)gdt_y] forKey:@"__DOWN_Y__"];
        [tool storeObject:[NSString stringWithFormat:@"%d", (int)gdt_y] forKey:@"__UP_Y__"];
        
        clickPositionDic = nil;
        aBclickPositionDic = nil;
    }
    else
    {
        if (isBegan)
        {
            [clickPositionDic setObject:[NSNumber numberWithInt:position_x] forKey:@"down_x"];
            [aBclickPositionDic setObject:[NSNumber numberWithFloat:aBPosition_x] forKey:@"down_x"];
            [clickPositionDic setObject:[NSNumber numberWithInt:position_y] forKey:@"down_y"];
            [aBclickPositionDic setObject:[NSNumber numberWithFloat:aBPosition_y] forKey:@"down_y"];
            
            // 广点通坐标宏
            CGFloat gdt_x = aBPosition_x==-999?-999:aBPosition_x*scale;
            CGFloat gdt_y = aBPosition_y==-999?-999:aBPosition_y*scale;
            [tool storeObject:[NSString stringWithFormat:@"%d", (int)gdt_x] forKey:@"__DOWN_X__"];
            [tool storeObject:[NSString stringWithFormat:@"%d", (int)gdt_y] forKey:@"__DOWN_Y__"];
        }
        else
        {
            [clickPositionDic setObject:[NSNumber numberWithInt:position_x] forKey:@"up_x"];
            [aBclickPositionDic setObject:[NSNumber numberWithFloat:aBPosition_x] forKey:@"up_x"];
            [clickPositionDic setObject:[NSNumber numberWithInt:position_y] forKey:@"up_y"];
            [aBclickPositionDic setObject:[NSNumber numberWithFloat:aBPosition_y] forKey:@"up_y"];
            
            // 广点通坐标宏
            CGFloat gdt_x = aBPosition_x==-1?-999:aBPosition_x*scale;
            CGFloat gdt_y = aBPosition_y==-1?-999:aBPosition_y*scale;
            [tool storeObject:[NSString stringWithFormat:@"%d", (int)gdt_x] forKey:@"__UP_X__"];
            [tool storeObject:[NSString stringWithFormat:@"%d", (int)gdt_y] forKey:@"__UP_Y__"];
        }
        
        if (!isBegan)
        {
            [tool storeObject:[AdViewExtTool jsonStringFromDic:clickPositionDic] forKey:@"{RELATIVE_COORD}"];
            [tool storeObject:[AdViewExtTool jsonStringFromDic:aBclickPositionDic] forKey:@"{ABSOLUTE_COORD}"];
            clickPositionDic = nil;
            aBclickPositionDic = nil;
        }
    }
}

#warning mark 这些都是干啥的...see here
//为点击接口设置点击位置
- (void)setClickPositionDicForClickAdInstlAction{
    
    if (!clickPositionDic)
    {
        clickPositionDic = [[NSMutableDictionary alloc] init];
    }
    
    if (!aBclickPositionDic)
    {
        aBclickPositionDic = [[NSMutableDictionary alloc] init];
    }
    
    CGRect suRect;
    if(self.advertType == AdViewInterstitial)
    {
        suRect = self.loadingAdView.frame;
    }
    else
    {
        suRect = self.rAdView.frame;
    }
    
    [clickPositionDic setObject:[NSNumber numberWithFloat:500.00] forKey:@"down_x"];
    [clickPositionDic setObject:[NSNumber numberWithFloat:500.00] forKey:@"down_y"];
    [clickPositionDic setObject:[NSNumber numberWithFloat:500.00] forKey:@"up_x"];
    [clickPositionDic setObject:[NSNumber numberWithFloat:500.00] forKey:@"up_y"];
    
    [aBclickPositionDic setObject:[NSNumber numberWithFloat:suRect.size.width/2] forKey:@"down_x"];
    [aBclickPositionDic setObject:[NSNumber numberWithFloat:suRect.size.height/2] forKey:@"down_y"];
    [aBclickPositionDic setObject:[NSNumber numberWithFloat:suRect.size.width/2] forKey:@"up_x"];
    [aBclickPositionDic setObject:[NSNumber numberWithFloat:suRect.size.height/2] forKey:@"up_y"];
    
    AdViewExtTool *tool = [AdViewExtTool sharedTool];
    [tool storeObject:[AdViewExtTool jsonStringFromDic:clickPositionDic] forKey:@"{RELATIVE_COORD}"];
    [tool storeObject:[AdViewExtTool jsonStringFromDic:aBclickPositionDic] forKey:@"{ABSOLUTE_COORD}"];
    [tool storeObject:@"500" forKey:@"__DOWN_X__"];
    [tool storeObject:@"500" forKey:@"__UP_X__"];
    [tool storeObject:@"500" forKey:@"__DOWN_Y__"];
    [tool storeObject:@"500" forKey:@"__UP_Y__"];
    
    clickPositionDic = nil;
    aBclickPositionDic = nil;
}
#if 0
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch* touch = [touches anyObject];
    lastTouchPoint = [touch locationInView:self];
    
    AdViewLogDebug(@"Touches began");
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch* touch = [touches anyObject];
    CGPoint currentPoint = [touch locationInView: self];    
    
    AdViewLogDebug(@"Touches Moved: %f, %f", currentPoint.x, currentPoint.y);
}
#endif

- (void)notifyPresentScreen
{
    if (AdViewNative == _advertType)
    {
        if (self.nativeAdPresentBlock)
        {
            self.nativeAdPresentBlock();
        }
    }
    else
    {
        if ([self.rAdView.delegate respondsToSelector:@selector(adViewWillPresentScreen:)])
        {
            [self.rAdView.delegate adViewWillPresentScreen:self.rAdView];
        }
        [self pauseRequestAd];
    }
}

//点击广告弹出的界面关闭通知
- (void)notifyDismissScreen
{
    if (AdViewNative == _advertType)
    {
        if (self.nativeAdCloseBlock)
        {
            self.nativeAdCloseBlock();
        }
    }
    else
    {
        if ([self.rAdView.delegate respondsToSelector:@selector(adViewDidDismissScreen:)])
        {
            [self.rAdView.delegate adViewDidDismissScreen:self.rAdView];
        }
        [self resumeRequestAd];
    }
}

//for other adPlat to count show times;
- (void) sendMessageToOtherPlats
{
    if ( self.adContent.otherShowURL!= nil)
    {
        _adContent.otherShowURL = [[AdViewExtTool sharedTool] replaceDefineString:_adContent.otherShowURL];
        NSURL *url = [NSURL URLWithString:self.adContent.otherShowURL];
        AdViewLogDebug(@"%@",_adContent.otherShowURL);
        NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
        req.HTTPMethod = @"GET";
        [NSURLConnection connectionWithRequest:req delegate:nil];
    }
}

- (void)sendExtendUrlWithUrlArray:(NSArray*)urlArr
{
    for (NSString *string in urlArr)
    {
        if ([string length] > 0 )
        {
            NSString *urlString = [[AdViewExtTool sharedTool] replaceDefineString:string];
            AdViewLogDebug(@"%@",urlString);
            NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
            req.HTTPMethod = @"GET";
            [req setValue:[AdViewExtTool sharedTool].userAgent forHTTPHeaderField:@"User-Agent"];
            [NSURLConnection connectionWithRequest:req delegate:nil];
        }
    }
}

// es && ec 中的汇报发送
- (void)extendUrlSendWithClickOrDisplayMessage:(BOOL)isDisplay
{
    if (isDisplay)
    {
        if (nil == _adContent.extendShowUrl) return;
        for (NSString *time in [_adContent.extendShowUrl allKeys])
        {
            if ([_adContent.extendShowUrl objectForKey:time])
            {
                [self performSelector:@selector(sendExtendUrlWithUrlArray:) withObject:[_adContent.extendShowUrl objectForKey:time] afterDelay:(NSTimeInterval)[time intValue]];
            }
        }
    }
    else
    {
        if (nil == _adContent.extendClickUrl) return;
        [self sendExtendUrlWithUrlArray:_adContent.extendClickUrl];
    }
}

// 第三方汇报包括其他平台及广告商的汇报
- (void)reportDisplayOrClickInfoToOther:(BOOL)isDisplay
{
    if (isDisplay)
    {
        [self sendMessageToOtherPlats];
    }
    [self extendUrlSendWithClickOrDisplayMessage:isDisplay];
    [self adInstlSendClickOrDisplayMessage:isDisplay];
}

//插屏点击/展示代发
- (void) adInstlSendClickOrDisplayMessage:(BOOL)isDisplay
{
    NSURL *url = nil;

    if (isDisplay)
    {
        if (self.adContent.monSstring==nil) return;
        _adContent.monSstring = [[AdViewExtTool sharedTool] replaceDefineString:_adContent.monSstring];
        url = [NSURL URLWithString:self.adContent.monSstring];
    }
    else
    {
        if (self.adContent.monCstring==nil) return;
        _adContent.monCstring = [[AdViewExtTool sharedTool] replaceDefineString:_adContent.monCstring];
        url = [NSURL URLWithString:self.adContent.monCstring];
    }
    AdViewLogDebug(@"%@%@",_adContent.monCstring,_adContent.monSstring);
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    req.HTTPMethod = @"GET";
    [NSURLConnection connectionWithRequest:req delegate:nil];
    
}

- (IBAction)sendInAppSMS:(NSString*)addr Body:(NSString*)bodyStr
{
    if (![self.rAdView.delegate respondsToSelector:@selector(viewControllerForShowModal)])
        return;
    
    MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
    if([MFMessageComposeViewController canSendText])
    {
        [self notifyPresentScreen];
        
        controller.body = bodyStr;
        controller.recipients = [NSArray arrayWithObjects:addr, nil];
        controller.messageComposeDelegate = self;
        UIViewController * root = nil;
        if (self.advertType == AdViewNative) {
            root = self.presentController;
        } else {
            root = [self.rAdView.delegate viewControllerForShowModal];
        }
        [AdViewExtTool showViewModal:controller FromRoot:root];
        self.modalController = controller;
    }
}

- (void)openDeeplinkWithActionType:(AdViewAdActionType)type
{
    if (nil == self.rAdView.delegate && _advertType != AdViewNative)
    {
        AdViewLogInfo(@"AdViewView delegate is nil, can not open link.");
        return;
    }
    
    if (nil != self.adContent.deepLink && self.adContent.deepLink.length > 0)
    {
        NSURL * url = [NSURL URLWithString:self.adContent.deepLink];
        UIApplication *application = [UIApplication sharedApplication];
        if (@available(iOS 10.0, *)) {
            [application openURL:url options:@{} completionHandler:^(BOOL success) {
                if (!success)
                {
                    [self openLink:self.adContent.adLinkURL ActionType:type];
                }
            }];
        }
        else
        {
            BOOL success = [application openURL:url];
            if (!success)
            {
                [self openLink:_adContent.adLinkURL ActionType:type];
            }
        }
    }
    else
    {
        [self openLink:_adContent.adLinkURL ActionType:type];
    }
}

- (void)openLink:(NSString *)_urlString ActionType:(AdViewAdActionType)type;
{
    NSString *urlString;
    if (nil != _urlString)
    {
        // 点击字段替换宏
        _urlString = [[AdViewExtTool sharedTool] replaceDefineString:_urlString];
        urlString = [NSString stringWithString:_urlString];
    }
    
    BOOL bItunes = ([urlString rangeOfString:@"//itunes.apple.com"].location != NSNotFound);
    BOOL bHttp = ([urlString rangeOfString:@"http://"].location == 0);	//http
    BOOL bHttps = ([urlString rangeOfString:@"https://"].location == 0);
    
    //是否使用本地webview打开
    BOOL bJudgeLocalWeb = (bHttp || bHttps) && !bItunes;

    if (AdViewAdActionType_Unknown != type)
    {
        switch (type)
        {
            case AdViewAdActionType_Web:
            case AdViewAdActionType_OpenURL:
            {
                bJudgeLocalWeb = YES;
            }
                break;
            case AdViewAdActionType_AppStore:
            {
                bJudgeLocalWeb = NO;
                //[self notifyPresentScreen];
            }
                break;
            case AdViewAdActionType_Call:
            {
                if (![_urlString containsString:@"tel:"])
                {
                    urlString = [NSString stringWithFormat:@"tel://%@", _urlString];
                }
                bJudgeLocalWeb = NO;
            }
                break;
            case AdViewAdActionType_Sms:
            {
                NSArray *arrItems = [_urlString componentsSeparatedByString:@","];
                [self sendInAppSMS:[arrItems objectAtIndex:0] Body:[arrItems objectAtIndex:1]];
                return;
            }
                break;
            case AdViewAdActionType_Mail:
                break;
            case AdViewAdActionType_Map:
                break;
            case AdViewAdActionType_MiniProgram:{
//                Class WXLaunchMiniProgramReqClass = NSClassFromString(@"WXLaunchMiniProgramReq");
//                Class WXApiClass = NSClassFromString(@"WXApi");
//                WXLaunchMiniProgramReq *launchMiniProgramReq = (WXLaunchMiniProgramReq*)[WXLaunchMiniProgramReqClass object];
//                launchMiniProgramReq.userName = [self.adContent.miniProgramDict objectForKey:@"orgId"];
//                launchMiniProgramReq.path = [self.adContent.miniProgramDict objectForKey:@"path"];
//                launchMiniProgramReq.miniProgramType = [[self.adContent.miniProgramDict objectForKey:@"type"] unsignedIntegerValue];
//                [WXApiClass sendReq:launchMiniProgramReq]; // 用返回值可拓展
                return;
            }
                break;
            default:
                break;
        }
    }
    AdViewLogDebug(@"openLink:%@", urlString);
    AdViewLogDebug(@"Judge LocalWeb:%d", bJudgeLocalWeb);
    
    if (bJudgeLocalWeb)
    {
        [self notifyPresentScreen];
        
        AdViewWebViewController * webViewController = [[AdViewWebViewController alloc] initWithNibName:nil bundle:nil];
        webViewController.delegate = self;
        webViewController.urlString = urlString;
        
        UIViewController *root = nil;
        if (self.advertType == AdViewNative) {
            root = self.presentController;
        } else {
            if (self.rAdView.delegate && [self.rAdView.delegate respondsToSelector:@selector(viewControllerForShowModal)]) {
                root = [self.rAdView.delegate viewControllerForShowModal];
            }
        } if (nil == root) {
            root = [UIApplication sharedApplication].keyWindow.rootViewController;
        }
        
        [AdViewExtTool showViewModal:webViewController FromRoot:root];
        return;
    }
    
    if (bItunes) {
        BOOL isSuccess = [self isSuccessOpenAppStoreInAppWithUrlString:urlString];
        if (isSuccess) return;
    }
    
    NSURL * url = [NSURL URLWithString:urlString];
    UIApplication *application = [UIApplication sharedApplication];
    __weak typeof(self) weakSelf = self;
    
    if (@available(iOS 10.0, *))
    {
        [application openURL:url options:@{} completionHandler:^(BOOL success) {
            if (!success)
            {
                if (weakSelf.advertType == AdViewNative)
                {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:weakSelf.adContent.fallBack]];
                }
            }
        }];
    }
    else
    {
        BOOL success = [application openURL:url];
        if (!success)
        {
            if (weakSelf.advertType == AdViewNative)
            {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:_adContent.fallBack]];
            }
        }
    }
    
}

- (void)openWebBody:(NSString *)body
{
    [self notifyPresentScreen];
    
    AdViewWebViewController *webViewController = [[AdViewWebViewController alloc] initWithNibName:nil bundle:nil];
    webViewController.delegate = self;
    webViewController.bodyString = body;
    UIViewController * root = nil;
    if (self.advertType == AdViewNative) {
        root = self.presentController;
    }else{
        if ([self.rAdView.delegate respondsToSelector:@selector(viewControllerForShowModal)]) {
            root = [self.rAdView.delegate viewControllerForShowModal];
        }else{
            root = [UIApplication sharedApplication].keyWindow.rootViewController;
        }
    }
    [root presentViewController:webViewController animated:YES completion:nil];
}

- (void)moveWebView:(UIWebView*)webView
{
    [self notifyPresentScreen];
    
    AdViewWebViewController *webViewController = [[AdViewWebViewController alloc] initWithNibName:nil bundle:nil];
    webViewController.delegate = self;
    webViewController.webView = webView;
    UIViewController * root = nil;
    if (self.advertType == AdViewNative)
    {
        root = self.presentController;
    }
    else
    {
        if ([self.rAdView.delegate respondsToSelector:@selector(viewControllerForShowModal)])
        {
            root = [self.rAdView.delegate viewControllerForShowModal];
        }
        else
        {
            root = [UIApplication sharedApplication].keyWindow.rootViewController;
        }
    }
    [root presentViewController:webViewController animated:YES completion:nil];
}

- (void)openLink:(AdViewContent*)_adContent
{
    if (nil == _adContent)
    {
        AdViewLogInfo(@"No ad content, click no response");
        return;
    }
    
    if (AdViewAdSHowType_WebView_Video == self.adContent.adShowType)
    {
        for (int i = 0; i < [[self.rAdView subviews] count]; i++)
        {
            UIView *view0 = [[self.rAdView subviews] objectAtIndex:i];
            if ([view0 isKindOfClass:[UIWebView class]])
            {
                [self moveWebView:(UIWebView*)view0];
                break;
            }
        }
    }
    else
    {
#warning tel 这里需要判断mraid其他问题 发短信没写
        if ([_adContent.adLinkURL containsString:@"tel:"])
        {
            [self openDeeplinkWithActionType:AdViewAdActionType_Call];
        }
        else if ([_adContent.adLinkURL hasPrefix:@"mraid"])
        {
            return;
        }
        else
        {
            [self openDeeplinkWithActionType:_adContent.adActionType];
        }
    }
}

- (void)performClickAction
{
    if (nil == self.adContent)
    {
        AdViewLogDebug(@"No ad content, not response to click event.");
        return;
    }
    if (nil != self.loadingAdView)
    {
        AdViewLogDebug(@"In loading, not response to click event.");
        return;
    }
    
    NSTimeInterval nowTime = [[NSDate date] timeIntervalSince1970];
    if ((nowTime - requestTime > AD_CLICK_TIMEOUT))
    {
        AdViewLogDebug(@"click limited!");
        return;
    }
    
    if (clickNumber >= _adContent.maxClickNum)
    {
        [[AdViewToastView setTipInfo:@"不能多次重复点击"] showTastView];
        return;
    }
    
    if (adClicking)
    {
        AdViewLogDebug(@"in click, not more");
        return;
    }
    adClicking = YES;
    _hitTested = YES;

    BOOL testMode = NO;
    if (self.rAdView.delegate && [self.rAdView.delegate respondsToSelector:@selector(testMode)])
    {
        testMode = [self.rAdView.delegate testMode];
    }
    
    if (testMode)
    {
        adClicking = NO;
        [self openLink:self.adContent];
    }
    else
    {
        [self requestClick];
        
        [self openLink:self.adContent];
        [self reportDisplayOrClickInfoToOther:NO];
    }
    
    if (_advertType != AdViewSpread)
    {
         [self cancelAnimTimer];
    }
}

#pragma mark - AdViewWebViewControllerDelegate
- (void)dismissWebViewModal:(UIWebView*)webView
{
    [self notifyDismissScreen];
//    if (_advertType == AdViewSpread) {
//        [self becomeActive:nil];
//    }
    
    if (self.videoController) {
        [self.videoController resume];
    }
    
    //it's the moved.
    if (AdViewAdSHowType_WebView_Video == self.adContent.adShowType && [[self.rAdView subviews] count] < 1)
    {
        [self.rAdView addSubview:webView];
        webView.delegate = self;
        
        CGRect frm = self.rAdView.frame;
        frm.origin.x = 0;
        frm.origin.y = 0;
        webView.frame = frm;
    }
}

- (BOOL)isSuccessOpenAppStoreInAppWithUrlString:(NSString *)urlString
{
    BOOL usingSK = YES;
    if (self.rAdView.delegate && [self.rAdView.delegate respondsToSelector:@selector(usingSKStoreProductViewController)])
    {
        usingSK = [self.rAdView.delegate usingSKStoreProductViewController];
    }
    if (usingSK)
    {
        NSString *idStr = [[urlString componentsSeparatedByString:@"?"] firstObject];
        NSArray *arr = [idStr componentsSeparatedByString:@"id"];
        if (arr != nil && arr.count >= 2)
        {
            idStr = [arr objectAtIndex:1];
            AdViewSKStoreProductViewController *storeProductViewController = [[AdViewSKStoreProductViewController alloc] init];// Configure View Controller
            [storeProductViewController setDelegate:self];
            [storeProductViewController loadProductWithParameters:@{SKStoreProductParameterITunesItemIdentifier :idStr} completionBlock:nil];
            UIViewController *root = nil;
            if (self.advertType == AdViewNative)
            {
                root = self.presentController;
            }
            else
            {
                if ([self.rAdView.delegate respondsToSelector:@selector(viewControllerForShowModal)])
                {
                    root = [self.rAdView.delegate viewControllerForShowModal];
                }
                else
                {
                    root = [UIApplication sharedApplication].keyWindow.rootViewController;
                }
            }
            if (root.presentedViewController)
            {
                [AdViewExtTool showViewModal:storeProductViewController FromRoot:root.presentedViewController];
            }
            else
            {
                [AdViewExtTool showViewModal:storeProductViewController FromRoot:root];
            }
            [self notifyPresentScreen];
            return YES;
        }
    }
    return NO;
}

- (void)openDeeplink:(NSMutableDictionary*)urlDict
{
    NSString *deeplinkUrl = [urlDict objectForKey:@"deeplinkUrl"];
    if (nil != deeplinkUrl && deeplinkUrl.length > 0)
    {
        self.adContent.deepLink = deeplinkUrl;
        AdViewLogDebug(@"deeplinkUrl:%@",deeplinkUrl);
    }
    NSString *htmlUrl = [urlDict objectForKey:@"url"];
    if (nil != htmlUrl && deeplinkUrl.length > 0)
    {
        self.adContent.adLinkURL = htmlUrl;
        AdViewLogDebug(@"htmlUrl:%@",htmlUrl);
    }
    if (self.adapter.bIgnoreClickRequest)
    {
        [self reportDisplayOrClickInfoToOther:NO];
        [self openLink:self.adContent];
    }
    else
    {
        [self performClickAction];
    }
}

#pragma mark - html5广告抓取点击url跳转操作
- (void)htmlAdForClikcAction:(NSString*)urlStr
{
    if (self.adapter.adPlatType != AdViewAdPlatTypeAdDirect && self.adapter.adPlatType != AdViewAdPlatTypeAdExchange)
    {
        self.adContent.adLinkURL = urlStr;
    }
    else
    {
        [self.adapter adjustClickLink:self.adContent];
    }
    
    if (self.adapter.bIgnoreClickRequest)
    {
        [self openLink:self.adContent];
        [self reportDisplayOrClickInfoToOther:NO];  // 第三方汇报包括其他平台及广告商的汇报
    }
    else
    {
        [self performClickAction];
    }
}

- (void)parseCommandUrl:(NSString*)commandUrlString adViewMraidWebView:(AdViewMraidWebView*)mraidWebView
{
    AdViewMraidParser *mraidParser = [[AdViewMraidParser alloc] init];
    NSDictionary *commandDict = [mraidParser parseCommandUrl:commandUrlString];
    if (!commandDict)
    {
        AdViewLogDebug([NSString stringWithFormat:@"mraid-view:invalid command URL: %@", commandUrlString]);
        return;
    }
    
    NSString *command = [commandDict valueForKey:@"command"];
    NSObject *paramObj = [commandDict valueForKey:@"paramObj"];
    SEL selector = NSSelectorFromString(command);
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if ([mraidWebView respondsToSelector:selector])
    {
        [mraidWebView performSelector:selector withObject:paramObj];
    }
#pragma clang diagnostic pop
}

#pragma mark - VAST - AdViewvideoviewcontrollerdelegate
- (void)vastReady:(AdViewVideoViewController *)vastVC {
    AdViewLogInfo(@"%s",__func__);
    if (self.advertType == AdViewInterstitial) {
        [self.rAdView setValue:[NSNumber numberWithBool:YES] forKey:@"interstitialIsReady"];
        
        if ([self.rAdView.delegate respondsToSelector:@selector(didReceivedAd:)]) {
            [self.rAdView.delegate didReceivedAd:self.rAdView];
        }
    } else if (self.advertType == AdViewBanner) {
        //如果是Banner,把videoController的播放view放到Banner的rAdView上面去展示
        AdViewVideoGeneralView * contentView = [vastVC valueForKey:@"contentView"];
        [self.rAdView addSubview:contentView];
        [vastVC play];
        
        if ([self.rAdView.delegate respondsToSelector:@selector(didReceivedAd:)]) {
            [self.rAdView.delegate didReceivedAd:self.rAdView];
        }
    }
}

// sent when any VASTError occurs - optional
- (void)vastError:(AdViewVideoViewController *)vastVC error:(AdViewVastError)error
{
    NSString *errMsg;
    switch (error)
    {
        case VASTErrorXMLParse:
            errMsg = @"异常广告，解析失败";
            break;
        case VASTErrorNone:
            errMsg = @"播放失败";
            break;
        case VASTErrorPlayerNotReady:
            errMsg = @"视频未准备好";
            break;
        case VASTErrorNoInternetConnection:
            errMsg = @"检查网络连接";
            break;
        case VASTErrorVideoFileTooBig:
            errMsg = @"视频文件过大";
            break;
        case VASTErrorPlayerFailed:
            errMsg = @"播放失败";
            break;
        default:
            errMsg = @"广告未知";
            break;
    }
    NSError *err = [[NSError alloc] initWithDomain:errMsg code:9999 userInfo:nil];
    if (self.rAdView.delegate && [self.rAdView.delegate respondsToSelector:@selector(didFailToReceiveAd:Error:)])
    {
        [self.rAdView.delegate didFailToReceiveAd:self.rAdView Error:err];
        [_omsdkManager logErrorWithType:OMIDErrorVideo message:errMsg];
    }
}

- (void)vastVideoAllPlayEnd:(AdViewVideoViewController *)vastVC
{
    AdViewLogInfo(@"%s",__func__);
    if ([self.rAdView.delegate respondsToSelector:@selector(adViewDidFinishShow:)])
    {
        [self.rAdView.delegate adViewDidFinishShow:self.rAdView];
    }
}

- (void)vastWillPresentFullScreen:(AdViewVideoViewController *)vastVC
{
    AdViewLogInfo(@"%s",__func__);
}

- (void)vastDidDismissFullScreen:(AdViewVideoViewController *)vastVC
{
    if (self.advertType != AdViewInterstitial)
    {
        if ([self.rAdView.delegate respondsToSelector:@selector(adViewDidDismissScreen:)])
        {
            [self.rAdView.delegate adViewDidDismissScreen:self.rAdView];
        }
    }
    else    //因为插屏可以用户点击按钮关闭,所以已经单独写了一个button的点击事件
    {
        [self closeAdInstlView:nil];
    }
}

- (void)vastOpenBrowseWithUrl:(NSURL *)url
{
    AdViewLogInfo(@"%s - %@",__func__,url);
}

- (void)vastTrackingEvent:(NSString *)eventName
{
    
}

- (void)vastVideoPlayStatus:(AdViewVideoPlayStatus)videoStatus {
    
}

- (void)responsClickActionWithUrlString:(NSString*)clickStr {
    [self openLink:clickStr ActionType:self.adContent.adActionType];
}

#pragma mark - AdViewMraidServiceDelegate
//注册日历
- (void)mraidServiceCreateCalendarEventWithEventJSON:(NSString *)eventJSON
{
    NSDictionary * jsonDict = [NSJSONSerialization JSONObjectWithData:[eventJSON dataUsingEncoding:NSUTF8StringEncoding]
                                                              options:NSJSONReadingMutableContainers
                                                                error:nil];
    [AdViewExtTool newCalendarFromJsonDict:jsonDict completion:^(BOOL success, NSError *error) {
        if (success)
        {
            [[AdViewToastView setTipInfo:@"Create calendar success"] showTastView];
        }
        else
        {
            [[AdViewToastView setTipInfo:@"Create calendar fial"] showTastView];
        }
    }];
}

- (void)mraidServicePlayVideoWithUrlString:(NSString *)urlString
{
    [self htmlAdForClikcAction:urlString];
}

- (void)mraidServiceOpenBrowserWithUrlString:(NSString *)urlString
{
    [self htmlAdForClikcAction:urlString];
}

- (void)mraidServiceExpandWithUrlString:(NSString *)urlString
{
    [self htmlAdForClikcAction:urlString];
}

- (void)mraidServiceStorePictureWithUrlString:(NSString *)urlString
{
#if PHOTO_PRIVACY
    UIImageFromURL([NSURL URLWithString:urlString], ^(UIImage *image) {
        UIImageWriteToSavedPhotosAlbum(image,self, @selector(image:didFinishSavingWithError:contextInfo:),nil);
    }, nil);
#endif
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    NSString * toastMessage = nil;
    if (error)
    {
        toastMessage = @"保存失败";
    }
    else
    {
        toastMessage = @"保存成功";
    }
    [[AdViewToastView setTipInfo:@"不能多次重复点击"] showTastView];
}

#pragma mark - AdViewMraidViewDelegate
- (UIViewController *)rootViewController {
    if ([self.rAdView.delegate respondsToSelector:@selector(viewControllerForShowModal)]) {
        return [self.rAdView.delegate viewControllerForShowModal];
    }
    return nil;
}
- (void)mraidViewAdReady:(AdViewMraidWebView *)mraidView {}
- (void)mraidViewAdFailed:(AdViewMraidWebView *)mraidView {}
- (void)mraidViewWillExpand:(AdViewMraidWebView *)mraidView {}
- (void)mraidViewDidClose:(AdViewMraidWebView *)mraidView
{
    if (self.advertType == AdViewInterstitial)
    {
        [self closeAdInstlView:nil];
    }
    else if (self.advertType == AdViewSpread)
    {
        [self performDissmissSpread];
    }
}

- (void)mraidViewNavigate:(AdViewMraidWebView *)mraidView withURL:(NSURL *)url
{
//    [self openLink:url.absoluteString ActionType:AdViewAdActionType_OpenURL];
}

- (BOOL)mraidViewShouldResize:(AdViewMraidWebView *)mraidView toPosition:(CGRect)position allowOffscreen:(BOOL)allowOffscreen
{
    return YES;
}

#pragma mark - Mraid UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString *reqUrlStr = [[request URL] absoluteString];
    AdViewLogDebug(@"AdViewView URL:%@", reqUrlStr);
    
    if ([reqUrlStr hasPrefix:@"newtab:"])
    {
        [self htmlAdForClikcAction:[reqUrlStr substringFromIndex:7]];
        return NO;
    }
    
    //检测过滤自动跳转，并上报服务器自动跳转广告信息
    if (!_hitTested && [[AdViewCheckTool sharedTool] isLandingUrl:reqUrlStr])
    {
        //是自动跳转，汇报服务器。
        NSMutableURLRequest *req = [_adapter makeAdErrorReport:ERR_AUTOLANDING AdContent:_adContent Arg:reqUrlStr];
        if (nil != req)
        {
            [NSURLConnection connectionWithRequest:req delegate:nil];
        }
        return NO;
    }
    
    if ([reqUrlStr hasPrefix:@"file:///"] || [reqUrlStr isEqualToString:@"about:blank"])
    {
        return YES;
    }

    if (self.adContent.adWebLoaded && (navigationType == UIWebViewNavigationTypeLinkClicked || _hitTested))
    {
        if (!_hitTested)
        {
            //是自动跳转，汇报服务器。
            NSMutableURLRequest *req = [_adapter makeAdErrorReport:ERR_AUTOLANDING AdContent:_adContent Arg:reqUrlStr];
            if (nil != req)
            {
                [NSURLConnection connectionWithRequest:req delegate:nil];
            }
            return NO;
        }
        [self htmlAdForClikcAction:reqUrlStr];
        return NO;
    }
    
//    self.adContent.adWebLoaded = NO;
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
//    self.adContent.adWebLoaded = NO;
}


- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if (self.adContent.adWebLoaded)
    {
        return;
    }

    if (webView == _adViewWebView.uiWebView)
    {
        AdViewLogInfo(@"webViewDidFinishLoad:%@",webView);
        
        self.adContent.adWebLoaded = YES;
        NSString *JSInjection = @"javascript: var allLinks = document.getElementsByTagName('a'); if (allLinks) {var i;for (i=0; i<allLinks.length; i++) {var link = allLinks[i];var target = link.getAttribute('target'); if (target && target == '_blank') {link.setAttribute('target','_self');link.href = 'newtab:'+link.href;}}}";
        [webView stringByEvaluatingJavaScriptFromString:JSInjection];
        [self addAdviewWithWebView:_adViewWebView];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    AdViewLogInfo(@"didFailLoadWithError：%@",error.domain);
    [_adViewWebView setIsViewable:NO];
    
    if (self.rAdView.delegate && [self.rAdView.delegate respondsToSelector:@selector(didFailToReceiveAd:Error:)])
    {
        [self.rAdView.delegate didFailToReceiveAd:self.rAdView Error:error];
        [_omsdkManager logErrorWithType:OMIDErrorGeneric message:error.domain];
    }
}

#pragma mark - Mraid WKWebViewDelegate
- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures
{
    if (navigationAction.targetFrame == nil || !navigationAction.targetFrame.isMainFrame)
    {
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
    decisionHandler(WKNavigationResponsePolicyAllow);
}
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSString *reqUrlStr = [navigationAction.request.URL absoluteString];
    AdViewLogDebug(@"AdViewView URL:%@", reqUrlStr);
    
    if ([reqUrlStr hasPrefix:@"newtab:"])
    {
        [self htmlAdForClikcAction:[reqUrlStr substringFromIndex:7]];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    //检测过滤自动跳转，并上报服务器自动跳转广告信息
    if (!_hitTested && [[AdViewCheckTool sharedTool] isLandingUrl:reqUrlStr])
    {
        //是自动跳转，汇报服务器。
        NSMutableURLRequest *req = [_adapter makeAdErrorReport:ERR_AUTOLANDING AdContent:_adContent Arg:reqUrlStr];
        if (nil != req)
        {
            [NSURLConnection connectionWithRequest:req delegate:nil];
        }
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    if ([reqUrlStr hasPrefix:@"file:///"] || [reqUrlStr isEqualToString:@"about:blank"])
    {
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
    }
    
    if (self.adContent.adWebLoaded && (navigationAction.navigationType == WKNavigationTypeLinkActivated || _hitTested))
    {
        if (!_hitTested)
        {
            //是自动跳转，汇报服务器。
            NSMutableURLRequest *req = [_adapter makeAdErrorReport:ERR_AUTOLANDING AdContent:_adContent Arg:reqUrlStr];
            if (nil != req)
            {
                [NSURLConnection connectionWithRequest:req delegate:nil];
            }
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
        [self htmlAdForClikcAction:reqUrlStr];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
//    self.adContent.adWebLoaded = NO;
    decisionHandler(WKNavigationActionPolicyAllow);
}


- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation
{
//    self.adContent.adWebLoaded = NO;
}


- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    if (self.adContent.adWebLoaded) return;

    if ([self.rAdView.delegate respondsToSelector:@selector(needPreAddView:)])
    {
        [self.rAdView.delegate needPreAddView:self.rAdView];
    }
    
    //如果回调的webview是mraid的webview则进行处理
    if (_adViewWebView.wkWebView == webView)
    {
        self.adContent.adWebLoaded = YES;
        
        NSString * JSInjection = @"javascript: var allLinks = document.getElementsByTagName('a'); if (allLinks) {var i;for (i=0; i<allLinks.length; i++) {var link = allLinks[i];var target = link.getAttribute('target'); if (target && target == '_blank') {link.setAttribute('target','_self');link.href = 'newtab:'+link.href;}}}";
        
        [webView evaluateJavaScript:JSInjection completionHandler:^(id _Nullable objc, NSError * _Nullable error) {
            AdViewLogDebug(@"%@-%@",objc,error);
        }];
        [self addAdviewWithWebView:_adViewWebView];
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    AdViewLogInfo(@"didFailLoadWithError：%@",error.domain);
    [_adViewWebView setIsViewable:NO];
    
    if ((webView == _adViewWebView.wkWebView && nil == [_adViewWebView superview]) || _advertType == AdViewInterstitial)
    {
        if (self.rAdView.delegate && [self.rAdView.delegate respondsToSelector:@selector(didFailToReceiveAd:Error:)])
        {
            [self.rAdView.delegate didFailToReceiveAd:self.rAdView Error:error];
            [_omsdkManager logErrorWithType:OMIDErrorGeneric message:error.domain];
        }
    }
}

//添加广告视图
- (void)addAdviewWithWebView:(AdViewMraidWebView *)mraidWebView
{
    //如果Banner的mraidWebview没有父视图 则把mraidWebView添加底层
    if (_advertType == AdViewBanner && nil == [mraidWebView superview]) {
        [self.rAdView addSubview:mraidWebView];
        [self.rAdView sendSubviewToBack:mraidWebView];
        [self.rAdView setAutoresizesSubviews:NO];       //防止父视图变大导致子视图跟随父视图同比例变大导致广告展示异常
    }
    else if (_advertType == AdViewInterstitial && self.loadingAdView == mraidWebView && nil == [mraidWebView superview]) {
        //如果是插屏且mraidWebView没有父视图 添加插屏到rAdview 标记为html的插屏广告
        isWebView = YES;
        [self adjustInstlView:mraidWebView];
    } else if (_advertType == AdViewSpread) {
        self.loadingAdView.alpha = 1;   //显示出来
        [self spreadDisplayCountDown];  //开始倒计时
    }
    
    //因为wkWebView在加载完毕时，没有渲染完毕。导致判断为白条
    [self performSelector:@selector(delayToDoSomethingWith:) withObject:mraidWebView afterDelay:0.5];
    
    //广告添加完毕 isViewable状态更新
    [_adViewWebView setIsViewable:YES];
    
    //OMSDK监测设置
    self.omsdkManager = [[AdViewOMAdHTMLManager alloc] initWithWebView:mraidWebView.currentWebView];
    [_omsdkManager setMainAdview:self.rAdView];
    [_omsdkManager setFriendlyObstruction:_closeButton];
    [_omsdkManager setFriendlyObstruction:[mraidWebView viewWithTag:ADVIEW_LABEL_TAG]];
    [_omsdkManager setFriendlyObstruction:[mraidWebView viewWithTag:ADVIEW_GG_LABEL_TAG]];
    [_omsdkManager startMeasurement];
    AdViewLogInfo(@"%s",__FUNCTION__);
}

//对webview进行延迟判断，反之某些广告加载逻辑问题导致被误判为白条（有些广告先加底框，在加载图片，底框加载完会调用webViewDidFinishLoad:导致判定为白条）
- (void)delayToDoSomethingWith:(AdViewMraidWebView *)mraidWebView
{
    UIView * currentWebView = mraidWebView.uiWebView ?: mraidWebView.wkWebView;
    
    //是否使用过滤空广告功能
    BOOL isEmptyWebView = LAUNCH_EMPTY_AD_FILTER ? [[AdViewCheckTool sharedTool] isEmptyAd:currentWebView] : 0;
    if (isEmptyWebView)
    {
        NSMutableURLRequest *req = [_adapter makeAdErrorReport:ERR_EMPTYAD AdContent:_adContent Arg:@""];
        if (nil != req)
        {
            [NSURLConnection connectionWithRequest:req delegate:nil];
        }
        
        if (self.adViewWebView.wkWebView)
        {
            [(WKWebView *)currentWebView stopLoading];
            if (_advertType == AdViewBanner || _advertType == AdViewSpread)
            {
                [currentWebView removeFromSuperview];
            }
            else if (_advertType == AdViewInterstitial)
            {
                UIView * view = self.rAdView.superview;
                [self.rAdView removeFromSuperview];
                [view removeFromSuperview];
            }
        }
        else if (self.adViewWebView.uiWebView)
        {
            [(UIWebView *)currentWebView stopLoading];
        }
        
        //如果是空白广告 设置广告为不可见
        [_adViewWebView setIsViewable:NO];
        
        NSString * errorInfo = @"Blank Ad";
        NSError *error = [NSError errorWithDomain:errorInfo code:-100001 userInfo:nil];
        if (self.rAdView.delegate && [self.rAdView.delegate respondsToSelector:@selector(didFailToReceiveAd:Error:)])
        {
            [self.rAdView.delegate didFailToReceiveAd:self.rAdView Error:error];
            [_omsdkManager logErrorWithType:OMIDErrorGeneric message:errorInfo];
        }
    }
    else //如果不是空广告
    {
        if (_advertType == AdViewBanner)
        {
            if (self.adViewWebView.wkWebView)
            {
                [self performSelector:@selector(transitIntoAdWKView:) withObject:[NSNumber numberWithBool:self.loadingFirstDisplay]];
            }
            else if(self.adViewWebView.uiWebView) //如果是UIWebView且mraid的superView不存在
            {
                [self performSelector:@selector(transitIntoBannerView:) withObject:[NSNumber numberWithBool:self.loadingFirstDisplay]];
            }
        }
        else if (_advertType == AdViewSpread)
        {
            if (!self.didClosedSpread)  //如果没有被关闭
            {
                [self spreadViewAddContentView:_loadingAdView];   //添加正在加载的界面到开屏
            }
            self.loadingAdView = nil;
        }
        else if (_advertType == AdViewInterstitial && self.loadingAdView == mraidWebView)
        {
            //如果是wkWebView 需要多一步操作 把它从屏幕上拿下来再添加到正确的位置,因为他之前被添加到屏幕之外的地方去加载了
            if (self.adViewWebView.wkWebView)
            {
                UIView * view = self.rAdView.superview;
                [view removeFromSuperview];
            }
            [self.rAdView setValue:[NSNumber numberWithBool:YES] forKey:@"interstitialIsReady"];

            if ([self.rAdView.delegate respondsToSelector: @selector(didReceivedAd:)])
            {
                [self.rAdView.delegate didReceivedAd:self.rAdView];
            }
            self.loadingAdView = nil;
        }
    }
}


#pragma mark - sms delegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    switch (result) {
        case MessageComposeResultCancelled:
            AdViewLogInfo(@"Cancelled");
            break;
        case MessageComposeResultFailed:
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"OpenAPIAdView SDK"
                                                            message:@"Unknown Error"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles: nil];
            [alert show];
        }
            break;
        case MessageComposeResultSent:
            
            break;
        default:
            break;
    }
    [self notifyDismissScreen];
    
    [AdViewExtTool dismissViewModal:controller];
    self.modalController = nil;
}

#pragma mark - storeProductViewControllerDelegate
- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    [self notifyDismissScreen];
    [viewController dismissViewControllerAnimated:YES completion:nil];
    if (viewController.presentingViewController && [viewController.presentingViewController isKindOfClass:[AdViewWebViewController class]])
    {
        [viewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - native block
- (void)didReceivedNativeData:(ReceivedDataBlock)block {
    self.nativeAdRecieveDataBlock = block;
}
- (void)failToLoadNativeData:(FailLoadBlock)block {
    self.nativeAdFailLoadBlock = block;
}
- (void)nativeAdShowPresent:(ShowPresentBlock)block {
    self.nativeAdPresentBlock = block;
}
- (void)nativeAdClose:(ClosedBlock)block {
    self.nativeAdCloseBlock = block;
}

#pragma mark - ad roll over 当自己平台失败是用三方sdk去填充
- (void)rollOverWithError:(NSError*)error
{
    if ([self checkIsHaveOtherPlatForRollOver])
    {
        self.rolloverManager = [[AdViewRolloverManager alloc] initWithRolloverPaltInfo:self.adapter.otherPaltArray];
        self.rolloverManager.delegate = self;
        UIViewController *controller;
        if (self.advertType == AdViewNative)
        {
            controller = self.presentController;
        }
        else
        {
            if (self.rAdView.delegate && [self.rAdView.delegate respondsToSelector:@selector(viewControllerForShowModal)])
            {
                controller = [self.rAdView.delegate viewControllerForShowModal];
            }
            else
            {
                controller = [UIApplication sharedApplication].keyWindow.rootViewController;
            }
        }

        self.rolloverManager.controller = controller;
        switch (self.advertType)
        {
            case AdViewBanner:
            {
                [self.rolloverManager getBannerAd];
            }
                break;
            case AdViewInterstitial:
            {
                [self.rolloverManager loadInstlAd];
            }
                break;
            case AdViewSpread:
            {
                [self.rolloverManager loadSpreadAd];
            }
                break;
            case AdViewNative:
            {
                [self.rolloverManager loadNativeAdWithCount:self.nativeAdCount];
            }
                break;
            default:
            {
                if (self.rAdView.delegate && [self.rAdView.delegate respondsToSelector:@selector(didFailToReceiveAd:Error:)])
                {
                    [self.rAdView.delegate didFailToReceiveAd:self.rAdView Error:error];
                    [_omsdkManager logErrorWithType:OMIDErrorGeneric message:error.domain];
                }
            }
                break;
        }
    }
    else
    {
        /*判断是插屏remove*/
        if (_advertType == AdViewInterstitial)
        {
            [self.rAdView removeFromSuperview];
        }
        else if(_advertType == AdViewSpread)    //开屏关闭
        {
            [self performDissmissSpread];
        }
        else if(_advertType == AdViewBanner)    //Banner等会再次请求
        {
            [self setupBannerAutoAdRequest];
        }
        
        if (self.rAdView.delegate && [self.rAdView.delegate respondsToSelector:@selector(didFailToReceiveAd:Error:)])
        {
            [self.rAdView.delegate didFailToReceiveAd:self.rAdView Error:error];
            [_omsdkManager logErrorWithType:OMIDErrorGeneric message:error.domain];
        }
        if (self.advertType == AdViewNative)
        {
            if (self.nativeAdFailLoadBlock)
            {
                self.nativeAdFailLoadBlock(error);
            }
        }
    }
}

- (BOOL)checkIsHaveOtherPlatForRollOver
{
    if (self.adapter.otherPaltArray && self.adapter.otherPaltArray.count > 0)
    {
        return YES;
    }
    return NO;
}

#pragma mark - RolloverManagerDelegate
- (void)getAdFailedToReceiveAd
{
    if (self.rAdView.delegate && [self.rAdView.delegate respondsToSelector:@selector(didFailToReceiveAd:Error:)]) {
        [self.rAdView.delegate didFailToReceiveAd:self.rAdView Error:nil];
        [_omsdkManager logErrorWithType:OMIDErrorGeneric message:@"RolloverManagerFaildReceiveAd"];
    }
    
    if (_advertType == AdViewInterstitial) {
        [self.rAdView removeFromSuperview];
    }else if(_advertType == AdViewSpread) {
        [self performDissmissSpread];
    }else if (_advertType == AdViewNative) {
        if (self.nativeAdFailLoadBlock) {
            self.nativeAdFailLoadBlock(nil);
        }
    }else {
        [self setupBannerAutoAdRequest];
    }
    self.rolloverManager = nil;
}

#pragma mark - RolloverManagerDelegate 请求成功
- (void)getAdSuccessToReceivedAdWithView:(UIView *)bannerView
{
    if (self.advertType == AdViewBanner)
    {
        self.loadingAdView = bannerView;
        [self transitIntoBannerView:@1];
        [self setupBannerAutoAdRequest];
    }

    if (self.advertType == AdViewInterstitial)
    {
        [self.rAdView removeFromSuperview];
        [self.rAdView setValue:[NSNumber numberWithBool:YES] forKey:@"interstitialIsReady"];

        if  ([self.rAdView.delegate respondsToSelector:@selector(didReceivedAd:)])
        {
            [self.rAdView.delegate didReceivedAd:self.rAdView];
        }
    }
    
    if (self.advertType == AdViewSpread)
    {
        [self performDissmissSpread];
        if  ([self.rAdView.delegate respondsToSelector:@selector(didReceivedAd:)]) {
            [self.rAdView.delegate didReceivedAd:self.rAdView];
        }
    }
}

//RolloverManager delegate
- (void)getAdSuccessToReceivedNativeAdWithArray:(NSArray *)dataArray {
    if (self.advertType == AdViewNative) {
        self.nativeAdRecieveDataBlock(dataArray);
    }
}

- (void)adViewWillClicked {

}

- (void)adViewWillShowAd {

}

- (void)adViewWillPresentScreen
{
    if (self.advertType == AdViewNative)
    {
        self.nativeAdPresentBlock();
    }
    else {
        if (self.rAdView.delegate && [self.rAdView.delegate     respondsToSelector:@selector(adViewWillPresentScreen:)])
        {
            [self.rAdView.delegate adViewWillPresentScreen:self.rAdView];
        }
    }
}

//RollOverManagerDelegate
- (void)adViewDidDismissScreen
{
    if (self.advertType == AdViewNative)
    {
        self.nativeAdCloseBlock();
    }
    else
    {
        if (self.rAdView.delegate && [self.rAdView.delegate respondsToSelector:@selector(adViewDidDismissScreen:)])
        {
            [self.rAdView.delegate adViewDidDismissScreen:self.rAdView];
        }
    }
}

- (void)adViewWillCloseInstl
{
    if (self.rAdView.delegate && [self.rAdView.delegate respondsToSelector:@selector(adViewDidDismissScreen:)])
    {
        [self.rAdView.delegate adViewDidDismissScreen:self.rAdView];
    }
}

- (void)videoClosed {
    
}

- (void)videoPlayEnded {
    
}

- (void)videoPlayStarted {
    
}

- (void)videoReadyToPlay {
    
}

@end

//
//  AdViewMraidView.m
//  AdViewHello
//
//  Created by AdView on 15-1-20.
//
//

#import "AdViewMraidWebView.h"
#import "AdViewMraidUtil.h"
#import "AdViewMraidOrientation.h"
#import "AdViewMraidResize.h"
#import "AdViewMraidParser.h"
#import "mraidjs.h"
#import "CloseButton.h"
#import "AdViewExtTool.h"
#import "AdViewMraidModalViewController.h"
#import "AdViewOMAdHTMLManager.h"

#define kCloseEventRegionSize 50
#define SYSTEM_VERSION_LESS_THAN(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

static const NSTimeInterval kLoadTimeOut = 10;  //webview 加载超时限制

typedef enum {
    AdViewMraidStateLoading,
    AdViewMraidStateDefault,
    AdViewMraidStateExpanded,
    AdViewMraidStateResized,
    AdViewMraidStateHidden
} AdViewMraidState;

@interface AdViewMraidWebView () <WKUIDelegate, WKNavigationDelegate, UIWebViewDelegate, AdViewMraidModalViewControllerDelegate>
{
    AdViewMraidState state;
    // This corresponds to the MRAID placement type.
    BOOL isInterstitial;
    
    // The only property of the MRAID expandProperties we need to keep track of
    // on the native side is the useCustomClose property.
    // The width, height, and isModal properties are not used in MRAID v2.0.
    BOOL useCustomClose;
    
    AdViewMraidOrientation * orientationProperties;
    AdViewMraidResize * resizeProperties;
    AdViewMraidParser * mraidParser;
    
    NSString * mraidjs;
    
    NSURL * baseURL;
    
    NSArray * mraidFeatures;
    NSArray * supportedFeatures;
    
    CGSize previousMaxSize;
    CGSize previousScreenSize;
    
    NSTimer * loadTimeOut;      //加载超时计时器（为了防止部分广告webviewdelegate不给响应，模拟一个失败响应）
}
@property (nonatomic, weak) id <WKNavigationDelegate,WKUIDelegate,UIWebViewDelegate> webViewDelegate;
@property (nonatomic, weak) UIViewController * rootViewController;        //模态弹出的根控制器
@property (nonatomic, strong) AdViewMraidModalViewController * modalVC;     //模态弹出承载控制器
@property (nonatomic, strong) UIButton * closeButton;                       //关闭模态弹出按钮
@property (nonatomic, strong) UIView *resizeView;                           //变形view
@property (nonatomic, strong) UIButton * resizeCloseButton;                 //关闭变形广告按钮
//// "hidden" method for interstitial support
//- (void)showAsInterstitial;
- (void)deviceOrientationDidChange:(NSNotification *)notification;
- (void)setResizeViewPosition;

// These methods provide the means for native code to talk to JavaScript code.
- (void)injectJavaScript:(NSString *)js;
// convenience methods to fire MRAID events
- (void)fireErrorEventWithAction:(NSString *)action message:(NSString *)message;
- (void)fireReadyEvent;
- (void)fireSizeChangeEvent;
- (void)fireStateChangeEvent;
- (void)fireViewableChangeEvent;
// setters
- (void)setDefaultPosition;
- (void)setMaxSize;
- (void)setScreenSize;

//- (void)initWebView;
- (void)parseCommandUrl:(NSString *)commandUrlString;
@end

@implementation AdViewMraidWebView
@synthesize webViewDelegate = _webViewDelegate;
@synthesize isViewable=_isViewable;

- (id)init
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"-init is not a valid initializer for the class MRAIDView" userInfo:nil];
    return nil;
}

- (id)initWithFrame:(CGRect)frame
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"-initWithFrame is not a valid initializer for the class MRAIDView" userInfo:nil];
    return nil;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"-initWithCoder is not a valid initializer for the class MRAIDView" userInfo:nil];
    return nil;
}

- (id)initWithFrame:(CGRect)frame
       withHtmlData:(NSString*)htmlData
        withBaseURL:(NSURL*)bsURL
  supportedFeatures:(NSArray *)features
           delegate:(id<AdViewMraidViewDelegate>)delegate

    serviceDelegate:(id<AdViewMRAIDServiceDelegate>)serviceDelegate
    webViewDelegate:(id<WKNavigationDelegate,WKUIDelegate,UIWebViewDelegate>)webViewDelegate
{
    return [self initWithFrame:frame
                  withHtmlData:htmlData
                   withBaseURL:bsURL
                asInterstitial:NO
             supportedFeatures:features
                      delegate:delegate
               serviceDelegate:serviceDelegate
               webViewDelegate:webViewDelegate];
}

//designated initializer
- (id)initWithFrame:(CGRect)frame
       withHtmlData:(NSString*)htmlData
        withBaseURL:(NSURL*)bsURL
     asInterstitial:(BOOL)isInter
  supportedFeatures:(NSArray *)currentFeatures
           delegate:(id<AdViewMraidViewDelegate>)delegate
    serviceDelegate:(id<AdViewMRAIDServiceDelegate>)serviceDelegate
    webViewDelegate:(id<WKNavigationDelegate,WKUIDelegate,UIWebViewDelegate>)webViewDelegate
{
    if (self = [super initWithFrame:frame])
    {
        isInterstitial = isInter;
        _mraidDelegate = delegate;
        _serviceDelegate = serviceDelegate;
        _webViewDelegate = webViewDelegate;
        
        AdViewLogDebug(@"%s - %@",__FUNCTION__,htmlData);
        
        self.rootViewController = [self.mraidDelegate rootViewController];
        state = AdViewMraidStateLoading;
        _isViewable = NO;
        useCustomClose = NO;
        
        orientationProperties = [[AdViewMraidOrientation alloc] init];
        resizeProperties = [[AdViewMraidResize alloc] init];
        
        mraidParser = [[AdViewMraidParser alloc] init];
        
        mraidFeatures = @[AdViewMraidSupportsSMS,
                          AdViewMraidSupportsTel,
                          AdViewMraidSupportsCalendar,
                          AdViewMraidSupportsStorePicture,
                          AdViewMraidSupportsInlineVideo];
        
        if([self isValidFeatureSet:currentFeatures] && serviceDelegate) {
            supportedFeatures = currentFeatures;
        }
        
        //创建webview
        [self initWebViewWithFrame:frame];
        
        previousMaxSize = CGSizeZero;
        previousScreenSize = CGSizeZero;
        
        [self addObserver:self forKeyPath:@"self.frame" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
        
        //加载mraid支持JS
        mraidjs = [NSString stringWithContentsOfFile:[self pathForFrameworkResource:@"mraid" ofType:@"js"] encoding:NSUTF8StringEncoding error:nil];      
        baseURL = bsURL;
        state = AdViewMraidStateLoading;
        
        if (mraidjs) {
            [self injectJavaScript:mraidjs];    //mraid.js脚本注入webview
        }
        
        //会导致OMSDK出现问题.所以要先执行这个
        htmlData = [AdViewMraidUtil processRawHtml:htmlData];
        
        //OMSDK 脚本注入
        NSError * injectError = nil;
        htmlData = [AdViewOMAdHTMLManager injectOMJSIntoAdHTML:htmlData error:&injectError];
        if (injectError) {
            AdViewLogInfo(@"%s - %@",__FUNCTION__, injectError);
        }
        
        if (htmlData) {
            if (self.wkWebView) {
                self.navigation = [self.wkWebView loadHTMLString:htmlData baseURL:baseURL];
            } else if (self.wkWebView) {
                [self.uiWebView loadHTMLString:htmlData baseURL:baseURL];
            }
        } else {
            AdViewLogInfo(@"mraid-view:Ad html is invalid, cann't load");
            if ([self.mraidDelegate respondsToSelector:@selector(mraidViewAdFailed:)]) {
                [self.mraidDelegate mraidViewAdFailed:self];
            }
        }
        [self newTimer];    //启动加载超时计时器
    }
    return self;
}

- (void)dealloc
{
    self.isViewable = NO;
    
    self.rootViewController = nil;
    self.currentWebView = nil;
    self.closeButton = nil;
    self.resizeView = nil;
    self.resizeCloseButton = nil;
    self.modalVC = nil;
    
    [self.wkWebView stopListenJSLog];
    self.wkWebView = nil;
    self.uiWebView = nil;
    
    [self removeObserver:self forKeyPath:@"self.frame"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    
    mraidParser = nil;
    resizeProperties = nil;
    orientationProperties = nil;

    mraidFeatures = nil;
    supportedFeatures = nil;
    
    self.mraidDelegate = nil;
    self.serviceDelegate = nil;
    self.webViewDelegate = nil;
}

- (BOOL)isValidFeatureSet:(NSArray *)features
{
    NSArray *kFeatures = @[AdViewMraidSupportsSMS,
                           AdViewMraidSupportsTel,
                           AdViewMraidSupportsCalendar,
                           AdViewMraidSupportsStorePicture,
                           AdViewMraidSupportsInlineVideo];
    
    // Validate the features set by the user
    for (id feature in features) {
        if (![kFeatures containsObject:feature]) {
            AdViewLogDebug([NSString stringWithFormat:@"mraid-view:feature %@ is unknown, no supports set", feature]);
            return NO;
        }
    }
    return YES;
}

- (void)setIsViewable:(BOOL)newIsViewable {
    //如果更新后的isViewable状态和之前的不同 则更新一下 发个通知
    BOOL isInScreen = [AdViewExtTool isViewable:self];
    if (_isViewable != newIsViewable && isInScreen) {
        _isViewable = newIsViewable && isInScreen;
        [self fireViewableChangeEvent];
    }
    AdViewLogDebug([NSString stringWithFormat:@"mraid-view:isViewable: %@", _isViewable?@"YES":@"NO"]);
}

- (BOOL)isViewable {
    AdViewLogDebug([NSString stringWithFormat: @"mraid-view:%@ %@", [self.class description], NSStringFromSelector(_cmd)]);
    return _isViewable;
}

- (void)deviceOrientationDidChange:(NSNotification *)notification {
    AdViewLogDebug([NSString stringWithFormat: @"mraid-view:%@ %@", [self.class description], NSStringFromSelector(_cmd)]);
    @synchronized (self) {
        [self setScreenSize];
        [self setMaxSize];
        [self setDefaultPosition];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (!([keyPath isEqualToString:@"self.frame"])) return;
    
    AdViewLogDebug(@"mraid-view:self.frame has changed");
    CGRect oldFrame = CGRectNull;
    CGRect newFrame = CGRectNull;
    if (change[@"old"] != [NSNull null])
    {
        oldFrame = [change[@"old"] CGRectValue];
    }
    if ([object valueForKeyPath:keyPath] != [NSNull null])
    {
        newFrame = [[object valueForKeyPath:keyPath] CGRectValue];
    }
    AdViewLogDebug([NSString stringWithFormat:@"mraid-view:old %@", NSStringFromCGRect(oldFrame)]);
    AdViewLogDebug([NSString stringWithFormat:@"mraid-view:new %@", NSStringFromCGRect(newFrame)]);
    
    if (state == AdViewMraidStateResized)
    {
        [self setResizeViewPosition];
    }
    [self setDefaultPosition];
    [self setMaxSize];
    [self fireSizeChangeEvent];
}

//#pragma mark - interstitial support
//
//- (void)showAsInterstitial
//{
//    AdViewLogDebug([NSString stringWithFormat: @"mraid-view:%@", NSStringFromSelector(_cmd)]);
//    [self expand:nil];
//}

#pragma mark LoadTimeOut method
- (void)newTimer
{
    [self removeTimer];
    loadTimeOut = [NSTimer scheduledTimerWithTimeInterval:kLoadTimeOut target:self selector:@selector(didLoadTimeOut) userInfo:nil repeats:NO];
}

- (void)removeTimer
{
    if (nil != loadTimeOut)
    {
        [loadTimeOut invalidate];
    }
    loadTimeOut = nil;
}

- (void)didLoadTimeOut
{
    loadTimeOut = nil;
    NSError *error = [NSError errorWithDomain:@"load time out" code:00000 userInfo:nil];
    
    if (self.wkWebView)
    {
        [self.wkWebView stopLoading];
        [self.wkWebView.navigationDelegate webView:self.wkWebView didFailNavigation:self.navigation withError:error];
    } else if (self.uiWebView) {
        [self.uiWebView stopLoading];
        [self.uiWebView.delegate webView:self.uiWebView didFailLoadWithError:error];
    }
}

#pragma mark - JavaScript --> native support
- (void)addCloseEventRegion
{
    self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _closeButton.backgroundColor = [UIColor clearColor];
    [_closeButton addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
    
    if (!useCustomClose)
    {
        // get button image from header file
        NSData* buttonData = [NSData dataWithBytesNoCopy:__MRAID_CloseButton_png
                                                  length:__MRAID_CloseButton_png_len
                                            freeWhenDone:NO];
        UIImage *closeButtonImage = [UIImage imageWithData:buttonData];
        [_closeButton setBackgroundImage:closeButtonImage forState:UIControlStateNormal];
    }
    
    _closeButton.frame = CGRectMake(0, 0, kCloseEventRegionSize, kCloseEventRegionSize);
    CGRect frame = _closeButton.frame;
    
    // align on top right
    int x = CGRectGetWidth(_modalVC.view.frame) - CGRectGetWidth(frame);
    frame.origin = CGPointMake(x, 0);
    _closeButton.frame = frame;
    _closeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    [_modalVC.view addSubview:_closeButton];
}

- (void)showResizeCloseRegion
{
    if (!_resizeCloseButton) {
        self.resizeCloseButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _resizeCloseButton.frame = CGRectMake(0, 0, kCloseEventRegionSize, kCloseEventRegionSize);
        _resizeCloseButton.backgroundColor = [UIColor clearColor];
        [_resizeCloseButton addTarget:self action:@selector(closeFromResize) forControlEvents:UIControlEventTouchUpInside];
        [_resizeView addSubview:_resizeCloseButton];
    }
    
    if (!useCustomClose) {
        // get button image from header file
        NSData* buttonData = [NSData dataWithBytesNoCopy:__MRAID_CloseButton_png
                                                  length:__MRAID_CloseButton_png_len
                                            freeWhenDone:NO];
        UIImage *closeButtonImage = [UIImage imageWithData:buttonData];
        [_resizeCloseButton setBackgroundImage:closeButtonImage forState:UIControlStateNormal];
    }
    
    // align appropriately
    int x;
    int y;
    UIViewAutoresizing autoresizingMask = UIViewAutoresizingNone;
    
    switch (resizeProperties.customClosePosition) {
        case AdViewMraidCustomClosePositionTopLeft:
        case AdViewMraidCustomClosePositionBottomLeft:
            x = 0;
            break;
        case AdViewMraidCustomClosePositionTopCenter:
        case AdViewMraidCustomClosePositionCenter:
        case AdViewMraidCustomClosePositionBottomCenter:
            x = (CGRectGetWidth(_resizeView.frame) - CGRectGetWidth(_resizeCloseButton.frame)) / 2;
            autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
            break;
        case AdViewMraidCustomClosePositionTopRight:
        case AdViewMraidCustomClosePositionBottomRight:
            x = CGRectGetWidth(_resizeView.frame) - CGRectGetWidth(_resizeCloseButton.frame);
            autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            break;
    }
    
    switch (resizeProperties.customClosePosition) {
        case AdViewMraidCustomClosePositionTopLeft:
        case AdViewMraidCustomClosePositionTopCenter:
        case AdViewMraidCustomClosePositionTopRight:
            y = 0;
            break;
        case AdViewMraidCustomClosePositionCenter:
            y = (CGRectGetHeight(_resizeView.frame) - CGRectGetHeight(_resizeCloseButton.frame)) / 2;
            autoresizingMask |= UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
            break;
        case AdViewMraidCustomClosePositionBottomLeft:
        case AdViewMraidCustomClosePositionBottomCenter:
        case AdViewMraidCustomClosePositionBottomRight:
            y = CGRectGetHeight(_resizeView.frame) - CGRectGetHeight(_resizeCloseButton.frame);
            autoresizingMask |= UIViewAutoresizingFlexibleTopMargin;
            break;
    }
    
    CGRect resizeCloseRegionFrame = _resizeCloseButton.frame;
    resizeCloseRegionFrame.origin = CGPointMake(x, y);
    _resizeCloseButton.frame = resizeCloseRegionFrame;
    _resizeCloseButton.autoresizingMask = autoresizingMask;
}

- (void)removeResizeCloseRegion
{
    if (_resizeCloseButton) {
        [_resizeCloseButton removeFromSuperview];
        _resizeCloseButton = nil;
    }
}


- (void)close
{
    AdViewLogDebug([NSString stringWithFormat: @"mraid-view:JS callback %@", NSStringFromSelector(_cmd)]);
    
    if (state == AdViewMraidStateLoading || (state == AdViewMraidStateDefault && !isInterstitial) || state == AdViewMraidStateHidden)
    {
        return;
    }
    
    //如果状态是resize 则调用另外一套关闭
    if (state == AdViewMraidStateResized)
    {
        [self closeFromResize];
        return;
    }
    
    if (_modalVC)
    {
        [_closeButton removeFromSuperview]; self.closeButton = nil;
        [_currentWebView removeFromSuperview];
        [_modalVC dismissViewControllerAnimated:NO completion:nil];
    }

    _currentWebView.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    [self addSubview:_currentWebView];
    [self sendSubviewToBack:_currentWebView];
    
    if (!isInterstitial)
    {
        [self fireSizeChangeEvent];
    }
    else
    {
        self.isViewable = NO;
        [self fireViewableChangeEvent];
    }
    
    if (state == AdViewMraidStateDefault && isInterstitial)
    {
        state = AdViewMraidStateHidden;
    }
    else if (state == AdViewMraidStateExpanded || state == AdViewMraidStateResized)
    {
        state = AdViewMraidStateDefault;
    }
    
    [self fireStateChangeEvent];
    
    if ([self.mraidDelegate respondsToSelector:@selector(mraidViewDidClose:)])
    {
        [self.mraidDelegate mraidViewDidClose:self];
    }
}

// This is a helper method which is not part of the official MRAID API.
- (void)closeFromResize
{
    AdViewLogDebug([NSString stringWithFormat: @"mraid-view:JS callback helper %@", NSStringFromSelector(_cmd)]);
    [self removeResizeCloseRegion];
    state = AdViewMraidStateDefault;
    [self fireStateChangeEvent];
    
    [_currentWebView removeFromSuperview];
    _currentWebView.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    [self addSubview:_currentWebView];
    [self sendSubviewToBack:_currentWebView];
    
    [_resizeView removeFromSuperview];
    self.resizeView = nil;
    
    [self fireSizeChangeEvent];

    if ([self.mraidDelegate respondsToSelector:@selector(mraidViewDidClose:)])
    {
        [self.mraidDelegate mraidViewDidClose:self];
    }
}

- (void)createCalendarEvent:(NSString *)eventJSON
{
    eventJSON = [eventJSON stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    AdViewLogDebug([NSString stringWithFormat: @"mraid-view:JS callback %@ %@", NSStringFromSelector(_cmd), eventJSON]);
    
    if ([supportedFeatures containsObject:AdViewMraidSupportsCalendar])
    {
        if ([self.serviceDelegate respondsToSelector:@selector(mraidServiceCreateCalendarEventWithEventJSON:)])
        {
            [self.serviceDelegate mraidServiceCreateCalendarEventWithEventJSON:eventJSON];
        }
    }
    else
    {
        AdViewLogDebug([NSString stringWithFormat:@"mraid-viwe:No calendar support has been included."]);
    }
}

// Note: This method is also used to present an interstitial ad.
- (void)expand:(NSString *)urlString
{
    AdViewLogDebug([NSString stringWithFormat: @"mraid-view:JS callback %@ %@", NSStringFromSelector(_cmd), (urlString ? urlString : @"1-part")]);
    
    // The only time it is valid to call expand is when the ad is currently in either default or resized state.
    if (state != AdViewMraidStateDefault && state != AdViewMraidStateResized) return;
    
    self.modalVC = [[AdViewMraidModalViewController alloc] initWithOrientationProperties:orientationProperties];
    CGRect screenFrame = [[UIScreen mainScreen] bounds];
    _modalVC.view.frame = screenFrame;
    _modalVC.delegate = self;
    
    if (!urlString)
    {
        _currentWebView.frame = screenFrame;
        [_currentWebView removeFromSuperview];
    }
    else
    {
        if (mraidjs)
        {
            [self injectJavaScript:mraidjs];
        }
        
        // Check to see whether we've been given an absolute or relative URL.
        // If it's relative, prepend the base URL.
        urlString = [urlString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        if (![[NSURL URLWithString:urlString] scheme])
        {
            // relative URL
            urlString = [[[baseURL absoluteString] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] stringByAppendingString:urlString];
        }
        
        // Need to escape characters which are URL specific
        urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSError *error;
//        NSString *content = [NSString stringWithContentsOfURL:[NSURL URLWithString:urlString] encoding:NSUTF8StringEncoding error:&error];
        if (!error)
        {
            
        }
        else
        {
            // Error! Clean up and return.
            AdViewLogInfo([NSString stringWithFormat:@"mraid-view:Could not load part 2 expanded content for URL: %@" ,urlString]);
            return;
        }
    }
    
    if ([self.mraidDelegate respondsToSelector:@selector(mraidViewWillExpand:)])
    {
        [self.mraidDelegate mraidViewWillExpand:self];
    }
    
    [_modalVC.view addSubview:_currentWebView];

    //添加一个关闭按钮
    [self addCloseEventRegion];
    
    [_rootViewController presentViewController:_modalVC animated:NO completion:nil];
    
    if (!isInterstitial)
    {
        state = AdViewMraidStateExpanded;
        [self fireStateChangeEvent];
    }
    [self fireSizeChangeEvent];
    self.isViewable = YES;
}

- (void)open:(NSString *)urlString
{
    urlString = [urlString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    AdViewLogDebug([NSString stringWithFormat: @"mraid-view:JS callback %@ %@", NSStringFromSelector(_cmd), urlString]);
    
    // Notify the callers
    if ([self.serviceDelegate respondsToSelector:@selector(mraidServiceOpenBrowserWithUrlString:)])
    {
        [self.serviceDelegate mraidServiceOpenBrowserWithUrlString:urlString];
    }
}

- (void)playVideo:(NSString *)urlString
{
    urlString = [urlString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    AdViewLogDebug([NSString stringWithFormat: @"mraid-view:JS callback %@ %@", NSStringFromSelector(_cmd), urlString]);
    if ([self.serviceDelegate respondsToSelector:@selector(mraidServicePlayVideoWithUrlString:)])
    {
        [self.serviceDelegate mraidServicePlayVideoWithUrlString:urlString];
    }
}

- (void)resize
{
    AdViewLogDebug([NSString stringWithFormat: @"mraid-view:JS callback %@", NSStringFromSelector(_cmd)]);
    // If our delegate doesn't respond to the mraidViewShouldResizeToPosition:allowOffscreen: message,
    // then we can't do anything. We need help from the app here.
    if (![self.mraidDelegate respondsToSelector:@selector(mraidViewShouldResize:toPosition:allowOffscreen:)])
    {
        return;
    }
    
    CGRect resizeFrame = CGRectMake(resizeProperties.offSetX, resizeProperties.offSetY, resizeProperties.width, resizeProperties.height);
    CGPoint bannerOriginInRootView = [self.rootViewController.view convertPoint:CGPointZero fromView:self];
    resizeFrame.origin.x += bannerOriginInRootView.x;
    resizeFrame.origin.y += bannerOriginInRootView.y;
    
    if (![self.mraidDelegate mraidViewShouldResize:self toPosition:resizeFrame allowOffscreen:resizeProperties.allowOffScreen])
    {
        return;
    }
    
    state = AdViewMraidStateResized;
    [self fireStateChangeEvent];
    
    if (!_resizeView)
    {
        self.resizeView = [[UIView alloc] initWithFrame:resizeFrame];
        [_currentWebView removeFromSuperview];
        [_resizeView addSubview:_currentWebView];
        [self.rootViewController.view addSubview:_resizeView];
    }
    
    _resizeView.frame = resizeFrame;
    _currentWebView.frame = _resizeView.bounds;
    [self showResizeCloseRegion];
    [self fireSizeChangeEvent];
}

- (void)setOrientationProperties:(NSDictionary *)properties;
{
    BOOL allowOrientationChange = [[properties valueForKey:@"allowOrientationChange"] boolValue];
    NSString *forceOrientation = [properties valueForKey:@"forceOrientation"];
    AdViewLogDebug([NSString stringWithFormat: @"mraid-view:JS callback %@ %@ %@", NSStringFromSelector(_cmd), (allowOrientationChange ? @"YES" : @"NO"), forceOrientation]);
    orientationProperties.allowOrientationChange = allowOrientationChange;
    orientationProperties.forceOrientation = [AdViewMraidOrientation mraidForceOrientationFromString:forceOrientation];
    [_modalVC forceToOrientation:orientationProperties];
}

- (void)setResizeProperties:(NSDictionary *)properties;
{
    int width = [[properties valueForKey:@"width"] intValue];
    int height = [[properties valueForKey:@"height"] intValue];
    int offsetX = [[properties valueForKey:@"offsetX"] intValue];
    int offsetY = [[properties valueForKey:@"offsetY"] intValue];
    NSString *customClosePosition = [properties valueForKey:@"customClosePosition"];
    BOOL allowOffscreen = [[properties valueForKey:@"allowOffscreen"] boolValue];
    AdViewLogDebug([NSString stringWithFormat: @"mraid-view:JS callback %@ %d %d %d %d %@ %@", NSStringFromSelector(_cmd), width, height, offsetX, offsetY, customClosePosition, (allowOffscreen ? @"YES" : @"NO")]);
    resizeProperties.width = width;
    resizeProperties.height = height;
    resizeProperties.offSetX = offsetX;
    resizeProperties.offSetY = offsetY;
    resizeProperties.customClosePosition = [AdViewMraidResize mraidCustomClosePositionFromString:customClosePosition];
    resizeProperties.allowOffScreen = allowOffscreen;
}

-(void)storePicture:(NSString *)urlString
{
    urlString=[urlString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    AdViewLogDebug([NSString stringWithFormat: @"mraid-view:JS callback %@ %@", NSStringFromSelector(_cmd), urlString]);
    
    if ([supportedFeatures containsObject:AdViewMraidSupportsStorePicture])
    {
        if ([self.serviceDelegate respondsToSelector:@selector(mraidServiceStorePictureWithUrlString:)])
        {
            [self.serviceDelegate mraidServiceStorePictureWithUrlString:urlString];
        }
    }
    else
    {
        AdViewLogDebug([NSString stringWithFormat:@"mraid-view:No MRAIDSupportsStorePicture feature has been included"]);
    }
}

- (void)useCustomClose:(NSString *)isCustomCloseString
{
    BOOL isCustomClose = [isCustomCloseString boolValue];
    AdViewLogDebug([NSString stringWithFormat: @"mraid-view:JS callback %@ %@", NSStringFromSelector(_cmd), (isCustomClose ? @"YES" : @"NO")]);
    useCustomClose = isCustomClose;
}

#pragma mark - JavaScript --> native support helpers
// These methods are helper methods for the ones above.
- (void)setResizeViewPosition
{
    AdViewLogDebug([NSString stringWithFormat: @"mraid-view:%@", NSStringFromSelector(_cmd)]);
   
    CGRect newResizeFrame = CGRectMake(resizeProperties.offSetX, resizeProperties.offSetY, resizeProperties.width, resizeProperties.height);
    if (self.wkWebView)
    {
         CGRect oldResizeFrame = self.wkWebView.frame;
        if (!CGRectEqualToRect(oldResizeFrame, newResizeFrame))
        {
            self.wkWebView.frame = newResizeFrame;
        }
    }
    else if (self.uiWebView)
    {
        CGRect oldResizeFrame = self.uiWebView.frame;
        if (!CGRectEqualToRect(oldResizeFrame, newResizeFrame))
        {
            self.uiWebView.frame = newResizeFrame;
        }
    }
}

#pragma mark - native -->  JavaScript support
- (void)injectJavaScript:(NSString *)js
{
    if (self.wkWebView) {
        [self.wkWebView evaluateJavaScript:js completionHandler:^(id _Nullable objc, NSError * _Nullable error) {
            AdViewLogDebug(@"injectJavaScript - objc:%@, error:%@",objc,error);
        }];
    } else if (self.uiWebView) {
        [self.uiWebView stringByEvaluatingJavaScriptFromString:js];
    }
}

// convenience methods
- (void)fireErrorEventWithAction:(NSString *)action message:(NSString *)message
{
    [self injectJavaScript:[NSString stringWithFormat:@"mraid.fireErrorEvent('%@','%@');", message, action]];
}

- (void)fireReadyEvent
{
    [self injectJavaScript:@"mraid.fireReadyEvent()"];
}

- (void)fireSizeChangeEvent
{
    @synchronized(self)
    {
        CGRect rect;
        if (self.wkWebView) {
            rect = self.wkWebView.frame;
        } else {
            rect = self.uiWebView.frame;
        }
        
        UIInterfaceOrientation interfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
        BOOL isLandscape = UIInterfaceOrientationIsLandscape(interfaceOrientation);
        BOOL adjustOrientationForIOS8 = isInterstitial &&  isLandscape && !SYSTEM_VERSION_LESS_THAN(@"8.0");
        NSString * jsString = [NSString stringWithFormat:@"mraid.setCurrentPosition(%d,%d,%d,%d);",(int)rect.origin.x,
                               (int)rect.origin.y,
                               adjustOrientationForIOS8 ? (int)rect.size.height:(int)rect.size.width,
                               adjustOrientationForIOS8?(int)rect.size.width:(int)rect.size.height];
        
        [self injectJavaScript:jsString];
    }
}

- (void)fireStateChangeEvent
{
    @synchronized(self)
    {
        NSArray * stateNames = @[@"loading", @"default", @"expanded", @"resized", @"hidden"];
        
        NSString * stateName = stateNames[state];
        [self injectJavaScript:[NSString stringWithFormat:@"mraid.fireStateChangeEvent('%@');", stateName]];
    }
}

//发送通知isViewable改变
- (void)fireViewableChangeEvent
{
    [self injectJavaScript:[NSString stringWithFormat:@"mraid.fireViewableChangeEvent(%@);", (self.isViewable ? @"true" : @"false")]];
}

- (void)setDefaultPosition
{
    if (isInterstitial)
    {
        // For interstitials, we define defaultPosition to be the same as screen size, so set the value there.
        return;
    }
    
    //getDefault position from the parent frame if we are not directly added to the rootview
    UIView * webView = _uiWebView ?: _wkWebView;
    if(webView.superview != self.rootViewController.view)
    {
        [self injectJavaScript:[NSString stringWithFormat:@"mraid.setDefaultPosition(%f,%f,%f,%f);", webView.superview.frame.origin.x, webView.superview.frame.origin.y, webView.superview.frame.size.width, webView.superview.frame.size.height]];
    }
    else
    {
        [self injectJavaScript:[NSString stringWithFormat:@"mraid.setDefaultPosition(%f,%f,%f,%f);", webView.frame.origin.x, webView.frame.origin.y, webView.frame.size.width, webView.frame.size.height]];
    }
}

- (void)setMaxSize
{
    if (isInterstitial)
    {
        // For interstitials, we define maxSize to be the same as screen size, so set the value there.
        return;
    }
    CGSize maxSize = self.rootViewController.view.bounds.size;
    if (!CGSizeEqualToSize(maxSize, previousMaxSize))
    {
        [self injectJavaScript:[NSString stringWithFormat:@"mraid.setMaxSize(%d,%d);",
                                (int)maxSize.width,
                                (int)maxSize.height]];
        previousMaxSize = CGSizeMake(maxSize.width, maxSize.height);
    }
}

- (void)setScreenSize
{
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    // screenSize is ALWAYS for portrait orientation, so we need to figure out the
    // actual interface orientation to get the correct current screenRect.
    UIInterfaceOrientation interfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
    BOOL isLandscape = UIInterfaceOrientationIsLandscape(interfaceOrientation);
    // [SKLogger debug:[NSString stringWithFormat:@"orientation is %@", (isLandscape ?  @"landscape" : @"portrait")]];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0"))
    {
        screenSize = CGSizeMake(screenSize.width, screenSize.height);
    }
    else
    {
        if (isLandscape)
        {
            screenSize = CGSizeMake(screenSize.height, screenSize.width);
        }
    }
    if (!CGSizeEqualToSize(screenSize, previousScreenSize))
    {
        [self injectJavaScript:[NSString stringWithFormat:@"mraid.setScreenSize(%d,%d);",
                                (int)screenSize.width,
                                (int)screenSize.height]];
        previousScreenSize = CGSizeMake(screenSize.width, screenSize.height);
        if (isInterstitial)
        {
            [self injectJavaScript:[NSString stringWithFormat:@"mraid.setMaxSize(%d,%d);",
                                    (int)screenSize.width,
                                    (int)screenSize.height]];
            [self injectJavaScript:[NSString stringWithFormat:@"mraid.setDefaultPosition(0,0,%d,%d);",
                                    (int)screenSize.width,
                                    (int)screenSize.height]]; 
        }
    }
}

-(void)setSupports:(NSArray *)currentFeatures
{
    for (id aFeature in mraidFeatures)
    {
        [self injectJavaScript:[NSString stringWithFormat:@"mraid.setSupports('%@',%@);", aFeature, [currentFeatures containsObject:aFeature] ? @"true" : @"false"]];
    }
 
}

#pragma mark - webView init
- (void)initWebViewWithFrame:(CGRect)frame
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10)
    {
        WKWebViewConfiguration * wkWebConfig = [[WKWebViewConfiguration alloc] init];
        if ([supportedFeatures containsObject:AdViewMraidSupportsInlineVideo])
        {
            wkWebConfig.allowsInlineMediaPlayback = true;
            wkWebConfig.mediaPlaybackRequiresUserAction = NO;
        }
        else
        {
            wkWebConfig.allowsInlineMediaPlayback = NO;
            wkWebConfig.mediaPlaybackRequiresUserAction = YES;
            AdViewLogDebug([NSString stringWithFormat:@"mraid-view:No inline video support has been included, videos will play full screen without autoplay."]);
        }
        WKPreferences *preferences = [[WKPreferences alloc] init];
        preferences.javaScriptCanOpenWindowsAutomatically = YES;
        wkWebConfig.preferences = preferences;
        
        self.wkWebView = [[AdViewLogWKWebView alloc] initWithFrame:frame configuration:wkWebConfig];
        _wkWebView.opaque = NO;
        _wkWebView.UIDelegate = self;
        _wkWebView.navigationDelegate = self;
        _wkWebView.scrollView.scrollEnabled = NO;
        _wkWebView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        _wkWebView.autoresizesSubviews = YES;
        [self addSubview:_wkWebView];
        
        self.currentWebView = _wkWebView;
    }
    else
    {
        
        self.uiWebView = [[UIWebView alloc] initWithFrame:frame];
        _uiWebView.opaque = NO;
        _uiWebView.delegate = self;
        _uiWebView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        _uiWebView.autoresizesSubviews = YES;
        _uiWebView.scrollView.scrollEnabled = NO;
        [self addSubview:_uiWebView];
        
        self.currentWebView = _uiWebView;
        if ([supportedFeatures containsObject:AdViewMraidSupportsInlineVideo])
        {
            _uiWebView.allowsInlineMediaPlayback = YES;
            _uiWebView.mediaPlaybackRequiresUserAction = NO;
        }
        else
        {
            _uiWebView.allowsInlineMediaPlayback = NO;
            _uiWebView.mediaPlaybackRequiresUserAction = YES;
            AdViewLogDebug([NSString stringWithFormat:@"mraid-view:No inline video support has been included, videos will play full screen without autoplay."]);
        }
    }
    
    //disable selection
    NSString * js = @"window.getSelection().removeAllRanges();";
    [self injectJavaScript:js];
}

- (void)parseCommandUrl:(NSString *)commandUrlString
{
    NSDictionary * commandDict = [mraidParser parseCommandUrl:commandUrlString];
    if (!commandDict)
    {
        AdViewLogDebug([NSString stringWithFormat:@"mraid-view:invalid command URL: %@", commandUrlString]);
        return;
    }
    
    NSString * command  = [commandDict valueForKey:@"command"];
    NSObject * paramObj = [commandDict valueForKey:@"paramObj"];
    SEL selector = NSSelectorFromString(command);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self performSelector:selector withObject:paramObj];
#pragma clang diagnostic pop
}

#pragma mark - webViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL *url = [request URL];
    NSString *scheme = [url scheme];
    NSString *absUrlString = [url absoluteString];
    
    if ([scheme isEqualToString:@"mraid"])
    {
        [self parseCommandUrl:absUrlString];
    }
    else if ([scheme isEqualToString:@"console-log"])
    {
        AdViewLogInfo([NSString stringWithFormat:@"JS console: %@",[[absUrlString substringFromIndex:14] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]);
    }
    else
    {
        AdViewLogDebug([NSString stringWithFormat:@"Found URL %@ with type %@", absUrlString, @(navigationType)]);
        
        // Links, Form submissions
        if (navigationType == UIWebViewNavigationTypeLinkClicked)
        {
            // For banner views
            if ([self.mraidDelegate respondsToSelector:@selector(mraidViewNavigate:withURL:)])
            {
                [self.mraidDelegate mraidViewNavigate:self withURL:url];
            }
        }
    }
    
    if ([self.webViewDelegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)])
    {
        return [self.webViewDelegate webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
    }
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    if ([self.webViewDelegate respondsToSelector:@selector(webViewDidStartLoad:)])
    {
        [self.webViewDelegate webViewDidStartLoad:webView];
    }
}

//UIWebview加载完毕
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self webViewFinishedLoadMraidJs];
    [self removeTimer];
    
    if ([self.webViewDelegate respondsToSelector:@selector(webViewDidFinishLoad:)])
    {
        [self.webViewDelegate webViewDidFinishLoad:webView];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self removeTimer];
    
    if ([self.webViewDelegate respondsToSelector:@selector(webView:didFailLoadWithError:)])
    {
        [self.webViewDelegate webView:webView didFailLoadWithError:error];
    }
}

#pragma mark - WKWebViewNaviDelegate
//在发送请求之前，决定是否跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL * url = navigationAction.request.URL ;
    NSString * scheme = [url scheme];
    NSString * absUrlString = [url absoluteString];
    
    if ([scheme isEqualToString:@"mraid"]) {
        [self parseCommandUrl:absUrlString];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    } else if ([[navigationAction.request URL].scheme isEqualToString:@"console-log"]) {
        AdViewLogInfo([NSString stringWithFormat:@"mraid-view:JS console: %@", [[absUrlString substringFromIndex:14] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding ]]);
        decisionHandler(WKNavigationActionPolicyCancel);
    } else {
        //暂时和下面的webviewDelegate冲突
        // Links, Form submissions
        if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
            // For banner views
            if ([self.mraidDelegate respondsToSelector:@selector(mraidViewNavigate:withURL:)]) {
                [self.mraidDelegate mraidViewNavigate:self withURL:url];
            }
        }
    }
    
    if ([self.webViewDelegate respondsToSelector:@selector(webView:decidePolicyForNavigationAction:decisionHandler:)]) {
        [self.webViewDelegate webView:webView decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
    } else {
        decisionHandler(WKNavigationActionPolicyCancel);
    }
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
    if ([self.webViewDelegate respondsToSelector:@selector(webView:decidePolicyForNavigationResponse:decisionHandler:)])
    {
        [self.webViewDelegate webView:webView decidePolicyForNavigationResponse:navigationResponse decisionHandler:decisionHandler];
    }
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation
{
    if ([self.webViewDelegate respondsToSelector:@selector(webView:didStartProvisionalNavigation:)])
    {
        [self.webViewDelegate webView:webView didStartProvisionalNavigation:navigation];
    }
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    if ([self.webViewDelegate respondsToSelector:@selector(webView:didFailProvisionalNavigation:withError:)])
    {
        [self.webViewDelegate webView:webView didFailProvisionalNavigation:navigation withError:error];
    }
}

//已开始加载页面
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation
{
    if ([self.webViewDelegate respondsToSelector:@selector(webView:didCommitNavigation:)])
    {
        [self.webViewDelegate webView:webView didCommitNavigation:navigation];
    }
}

//WkWebView页面已全部加载
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    [self webViewFinishedLoadMraidJs];
    [self removeTimer];
    
    if ([self.webViewDelegate respondsToSelector:@selector(webView:didFinishNavigation:)])
    {
        [self.webViewDelegate webView:webView didFinishNavigation:navigation];
    }
}

//失败
- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    [self removeTimer];
    if ([self.webViewDelegate respondsToSelector:@selector(webView:didFailProvisionalNavigation:withError:)])
    {
        [self.webViewDelegate webView:webView didFailNavigation:navigation withError:error];
    }
}

#define WKWebview UIDelegate
//创建一个新的WebView
- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures
{
    if ([self.webViewDelegate respondsToSelector:@selector(webView:createWebViewWithConfiguration:forNavigationAction:windowFeatures:)])
    {
        return [self.webViewDelegate webView:webView createWebViewWithConfiguration:configuration forNavigationAction:navigationAction windowFeatures:windowFeatures];
    }
    return nil;
}

- (void)webViewFinishedLoadMraidJs
{
    if (state == AdViewMraidStateLoading)
    {
        state = AdViewMraidStateDefault;
        
        //必须提前告知delegate已经加载完毕 否则不会被添加到父视图上
        if ([self.mraidDelegate respondsToSelector:@selector(mraidViewAdReady:)])
        {
            [self.mraidDelegate mraidViewAdReady:self];
        }
        
        [self injectJavaScript:[NSString stringWithFormat:@"mraid.setPlacementType('%@');", (isInterstitial ? @"interstitial" : @"inline")]];
        [self setSupports:supportedFeatures];
        [self setDefaultPosition];
        [self setMaxSize];
        [self setScreenSize];
        [self fireStateChangeEvent];
        [self fireSizeChangeEvent];
        [self fireReadyEvent];
        
        // Start monitoring device orientation so we can reset max Size and screenSize if needed.
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(deviceOrientationDidChange:)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];
    }
}

#pragma mark - MRAIDModalViewControllerDelegate
- (void)mraidModalViewControllerDidRotate:(AdViewMraidModalViewController *)modalViewController
{
    [self setScreenSize];
    [self fireSizeChangeEvent];
}
@end

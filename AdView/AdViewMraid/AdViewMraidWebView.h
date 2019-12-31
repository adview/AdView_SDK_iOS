//
//  AdViewMraidWebView.h
//  AdViewHello
//
//  Created by AdView on 16/9/1.
//
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "AdViewDefines.h"

static NSString* AdViewMraidSupportsSMS = @"sms";
static NSString* AdViewMraidSupportsTel = @"tel";
static NSString* AdViewMraidSupportsCalendar = @"calendar";
static NSString* AdViewMraidSupportsStorePicture = @"storePicture";
static NSString* AdViewMraidSupportsInlineVideo = @"inlineVideo";

// A delegate for MRAIDView/MRAIDInterstitial to listen for notifications when the following events
// are triggered from a creative: SMS, Telephone call, Calendar entry, Play Video (external) and
// saving pictures. If you don't implement this protocol, the default for
// supporting these features for creative will be FALSE.
@protocol AdViewMRAIDServiceDelegate <NSObject>
@optional
// These callbacks are to request other services.
- (void)mraidServiceCreateCalendarEventWithEventJSON:(NSString *)eventJSON;
- (void)mraidServicePlayVideoWithUrlString:(NSString *)urlString;
- (void)mraidServiceOpenBrowserWithUrlString:(NSString *)urlString;
- (void)mraidServiceExpandWithUrlString:(NSString *)urlString;
- (void)mraidServiceStorePictureWithUrlString:(NSString *)urlString;
@end

@class AdViewMraidWebView;
// A delegate for MRAIDView to listen for notification on ad ready or expand related events.
@protocol AdViewMraidViewDelegate <NSObject>
@required
//need a rootViewController to expand etc
- (UIViewController *)rootViewController;
@optional
// These callbacks are for basic banner ad functionality.
- (void)mraidViewAdReady:(AdViewMraidWebView *)mraidView;
- (void)mraidViewAdFailed:(AdViewMraidWebView *)mraidView;
- (void)mraidViewWillExpand:(AdViewMraidWebView *)mraidView;
- (void)mraidViewDidClose:(AdViewMraidWebView *)mraidView;
- (void)mraidViewNavigate:(AdViewMraidWebView *)mraidView withURL:(NSURL *)url;
// This callback is to ask permission to resize an ad.
- (BOOL)mraidViewShouldResize:(AdViewMraidWebView *)mraidView toPosition:(CGRect)position allowOffscreen:(BOOL)allowOffscreen;
@end

@interface AdViewMraidWebView : UIView

@property (nonatomic, weak) id <AdViewMraidViewDelegate> mraidDelegate;
@property (nonatomic, weak) id <AdViewMRAIDServiceDelegate> serviceDelegate;
@property (nonatomic, assign, getter = isViewable, setter = setIsViewable:) BOOL isViewable;
@property (nonatomic, strong)WKNavigation *navigation;
@property (nonatomic, strong) UIView * currentWebView;  //当前webView （WKWebView UIWebView）
@property (nonatomic, strong) AdViewLogWKWebView *wkWebView;
@property (nonatomic, strong) UIWebView *uiWebView;


/**
 初始化mraidWebView唯一方法

 @param frame 尺寸
 @param htmlData 需要加载的HTML代码
 @param bsURL CSS位置
 @param features 支持的功能:比如打开相册、打电话等
 @param delegate Mraid广告的一些回调:打开、关闭等。
 @param serviceDelegate 需要进行的service:保存照片、创建日历等。
 @param webViewDelegate 内置的真正展示广告的webView的回调。用于适配之前代码。
 @return AdViewMraidWebView.new()
 */
- (id)initWithFrame:(CGRect)frame
       withHtmlData:(NSString*)htmlData
        withBaseURL:(NSURL*)bsURL
  supportedFeatures:(NSArray *)features
           delegate:(id<AdViewMraidViewDelegate>)delegate
    serviceDelegate:(id<AdViewMRAIDServiceDelegate>)serviceDelegate
    webViewDelegate:(id<WKNavigationDelegate,WKUIDelegate,UIWebViewDelegate>)webViewDelegate;

@end

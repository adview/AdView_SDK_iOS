//
//  AdViewVideoViewController.h
//  KOpenAPIAdView
//
//  Created by AdView on 2018/4/26.
//

#import <UIKit/UIKit.h>
#import "AdViewVastError.h"
#import "AdViewDefines.h"
#import "AdViewVideoGeneralView.h"

@class AdViewVideoViewController;

typedef enum {
    AdViewVideoPlayStart,
    AdViewVideoPlayEnd,
}AdViewVideoPlayStatus;

@protocol AdViewVideoViewControllerDelegate <NSObject>
@required
- (void)vastReady:(AdViewVideoViewController *)vastVC;  //VAST准备完毕可以播放
@optional
- (void)vastError:(AdViewVideoViewController *)vastVC error:(AdViewVastError)error;
- (void)vastVideoAllPlayEnd:(AdViewVideoViewController *)vastVC;
- (void)vastVideoSkipped;

// These optional callbacks are for basic presentation, dismissal, and calling video clickthrough url browser.
- (void)vastWillPresentFullScreen:(AdViewVideoViewController *)vastVC;
- (void)vastDidDismissFullScreen:(AdViewVideoViewController *)vastVC;
- (void)vastOpenBrowseWithUrl:(NSURL *)url;
- (void)vastTrackingEvent:(NSString *)eventName;

//⚠️ 非Nexage SDK原本回调.也没有用到.不知道作用
- (void)vastVideoPlayStatus:(AdViewVideoPlayStatus)videoStatus;
- (void)responsClickActionWithUrlString:(NSString*)clickStr;
@end

@interface AdViewVideoViewController : UIViewController
@property (nonatomic, weak) id<AdViewVideoViewControllerDelegate>delegate;
@property (nonatomic, strong) NSURL * clickThrough;
@property (nonatomic, assign) float leftGap;
@property (nonatomic, assign) float topGap;
@property (nonatomic, assign) BOOL enableAutoClose;
@property (nonatomic, assign) BOOL allowAlertView;                      //流量提示框是否展示
@property (nonatomic, assign) UIInterfaceOrientation orientation;       //视频展示方向
@property (nonatomic, assign) AdvertType adverType;                     //广告类型
@property (nonatomic, assign) ADVASTMediaFileType mediaFileType;        //VAST、VPAID

- (id)initWithDelegate:(id<AdViewVideoViewControllerDelegate>)delegate adverType:(AdvertType)adverType; //初始化方法,只设置delegate和进入前台后台时的暂停开始播放逻辑
- (void)loadVideoWithURL:(NSURL *)url;                                  //从URL加载VAST的XML(暂时没用)
- (void)loadVideoWithData:(NSData *)xmlContent;                         //从NSdata加载加载VAST的XML

- (void)play;                       // command to play the video, this is only valid after receiving the vastReady: callback
- (void)waitUserAllowPlay;          // 等待用户点击播放
- (void)pause;                      // pause the video, useful when modally presenting a browser, for example
- (void)resume;                     // resume the video, useful when modally dismissing a browser, for example
//- (void)info;                       // callback to host class for opening a browser to the URL specified in 'clickthrough'
- (void)close;                      // dismisses a video playing on screen
- (BOOL)isPlaying;                  // playing state

- (void)showFaildInfomation:(NSString*)failStr; //显示失败信息（通过Alert实现，AdViewVideo可以控制是否展示该失败信息）
@end


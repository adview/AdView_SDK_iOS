//
//  AdViewVideo.h
//  AdViewHello
//
//  Created by AdView on 2018/8/1.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "AdViewViewDelegate.h"
#import "AdViewDefinesPublic.h"
@class AdViewVideo;

@protocol AdViewVideoDelegate <AdViewGDPRProcotol>
@optional
//***** ADVideoTypeInstl 应用回调

/*
 * 视频可以开始播放该回调调用后可以调用showVideoWithController:展示视频广告
 */
- (void)adViewVideoIsReadyToPlay:(AdViewVideo *)video;

/*
 * 视频广告播放开始回调
 */
- (void)adViewVideoPlayStarted;

/*
 * 视频广告播放结束回调
 */
- (void)adViewVideoPlayEnded;

/*
 * 视频广告关闭回调
 */
- (void)adViewVideoClosed;

/// 广告跳过回调
- (void)adViewVideoSkipped;

//***** 两种模式共用部分回调
/*
 * 请求广告数据成功回调
 * @param vastString:贴片模式下返回视频内容字符串(vast协议标准);非贴片模式下返回为nil;
 */

- (void)adViewVideoDidReceiveAd:(NSString *)vastString;

/*
 * 请求广告数据失败回调
 * @param error:数据加载失败错误信息;(播放失败回调也包含再该回调中)
 */
- (void)adViewVideoFailReceiveDataWithError:(NSError*)error;
@end

@interface AdViewVideo : NSObject
@property (nonatomic, assign) BOOL enableGPS; // 是否打开位置信息获取功能，默认为NO；

+ (AdViewVideo *)playVideoWithAppId:(NSString *)appId
                         positionId:(NSString *)positionID
                          videoType:(AdViewVideoType)videoType
                           delegate:(id<AdViewVideoDelegate>)videoDelegate;

/**
 设置视频展示方向

 @param orientation 视频展示方向 默认为竖屏（UIInterfaceOrientationPortrait）
 */
- (void)setInterfaceOrientations:(UIInterfaceOrientation)orientation;

/**
 * 加载视频广告
 */
- (void)getVideoAD;

/**
 * 设置视频背景颜色，默认为黑色，建议在showVideoWithController:方法之前使用，否则延迟生效
 */
- (void)setVideoBackgroundColor:(UIColor*)backgroundColor;

/**
 * 展示广告，AdViewVideoIsReadyToPlay:回调之后调用，否则展示不出来；
 */
- (BOOL)showVideoWithController:(UIViewController *)controller;

/**
 * 是否展示流量提醒提示框（非wifi以及无缓存情况下使用该功能）
 * @param isShow 是否展示（YES为展示，默认为NO）
 */
- (void)isShowTrafficReminderView:(BOOL)isShow;

/**
 * 清理视频缓存
 */
- (void)clearVideoBuffer;

@end

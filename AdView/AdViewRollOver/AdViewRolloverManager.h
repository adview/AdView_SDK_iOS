//
//  RolloverManager.h
//  AdViewHello
//
//  Created by AdView on 2018/8/15.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AdViewRolloverAdapter.h"

/**
 回调 Banner、插屏、开屏、视频、原生在一起
 */
@protocol AdViewRolloverManagerDelegate <NSObject>
- (void)getAdSuccessToReceivedAdWithView:(UIView*)bannerView;
- (void)getAdSuccessToReceivedNativeAdWithArray:(NSArray*)dataArray;
- (void)getAdFailedToReceiveAd;
- (void)adViewWillShowAd;
- (void)adViewWillClicked;
- (void)adViewWillPresentScreen;
- (void)adViewDidDismissScreen;
- (void)adViewWillCloseInstl;

//打底视频回调
- (void)videoReadyToPlay;
- (void)videoPlayStarted;
- (void)videoPlayEnded;
- (void)videoClosed;
@end

@interface AdViewRolloverManager : NSObject
@property (nonatomic, strong) UIViewController *controller;
@property (nonatomic, weak) id<AdViewRolloverManagerDelegate> delegate;
- (instancetype)initWithRolloverPaltInfo:(NSArray*)platInfoArray;

/**
 Banner请求
 */
- (void)getBannerAd;

/**
 插屏请求
 */
- (void)loadInstlAd;
- (void)showInstlWithController:(UIViewController*)controller;

/**
 开屏请求
 */
- (void)loadSpreadAd;

/**
 原生请求

 @param count 请求个数
 */
- (void)loadNativeAdWithCount:(int)count;
- (void)showNativeAdWithIndex:(NSUInteger)index toView:(UIView*)view;
- (void)clickNativeAdWithIndex:(NSUInteger)index onView:(UIView*)view;

/**
 停止请求
 */
- (void)stopGetAd;

/**
 打底视频
 */
- (void)loadVideoAd;
- (void)showVideoWithController:(UIViewController*)controller;

/**
 以下是行为汇报

 @param adapter 适配器具体类型
 @param view 展示界面
 */
- (void)adapter:(AdViewRolloverAdapter*)adapter didReceiveAdView:(UIView*)view;
- (void)adapter:(AdViewRolloverAdapter*)adapter didReceiveAdWithArray:(NSArray*)adArray;
- (void)adapter:(AdViewRolloverAdapter*)adapter didFailAdWithError:(NSError*)error;
- (void)adapter:(AdViewRolloverAdapter*)adapter displayOrClickAd:(BOOL)beDisplay;
- (void)willPresentAdViewWithAdapter:(AdViewRolloverAdapter*)adapter;
- (void)didDismissAdViewWithAdapter:(AdViewRolloverAdapter*)adapter;
- (void)closeInstlWithAdapter:(AdViewRolloverAdapter*)adapter;

- (void)didCacheVdieoWithAdapter:(AdViewRolloverAdapter*)adapter;     //缓存视频
- (void)videoPlayStartWithAdapter:(AdViewRolloverAdapter*)adatper;    //视频播放开始
- (void)videoPlayFinishedWithAdapter:(AdViewRolloverAdapter*)adatper; //视频播放完成
- (void)videoClosedWithAdapter:(AdViewRolloverAdapter*)adatper;       //视频关闭
@end

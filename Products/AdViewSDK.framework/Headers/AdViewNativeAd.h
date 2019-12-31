//
//  AdViewManager.h
//  AdViewHello
//
//  Created by AdView on 14-9-25.
//
//  原生广告 目前video只支持vast

#import <Foundation/Foundation.h>
#import "AdViewDefinesPublic.h"
#import "AdViewViewDelegate.h"

@class AdViewRolloverManager;
@class AdViewNativeAd;
@class AdViewNativeData;

@protocol AdViewNativeAdDelegate <AdViewGDPRProcotol>
/*
 * 原⽣广告加载广告数据成功回调
 * @param nativeDataArray 为 AdViewNativeData 对象的数组，即广告内容数组
 */
- (void)adViewNativeAdSuccessToLoadAd:(AdViewNativeAd *)adViewNativeAd NativeData:(NSArray <AdViewNativeData *>*)nativeDataArray;

/*
 * 原⽣广告加载广告数据失败回调
 * @param error 为加载失败返回的错误信息
 */
- (void)adViewNativeAdFailToLoadAd:(AdViewNativeAd *)adViewNativeAd WithError:(NSError *)error;

/*
 * 原⽣广告后将要展示内嵌浏览器回调
 */
- (void)adViewNativeAdWillShowPresent;

/*
 * 原⽣广告点击后，内嵌浏览器被关闭时回调
 */
- (void)adViewNativeAdClosed;

/*
 * 原⽣广告点击之后应用进入后台时回调
 */
- (void)adViewNativeAdResignActive;
@end

@interface AdViewNativeData : NSObject
@property (nonatomic, strong) NSString * nativeAdId;
@property (nonatomic, strong) NSDictionary * adProperties;
@property (nonatomic, strong) AdViewRolloverManager *rolloverManager;
@end

@interface AdViewNativeAd : NSObject
@property (nonatomic, weak) id<AdViewNativeAdDelegate> delegate;
/*
 * viewControllerForPresentingModalView
 */
@property (nonatomic, weak) UIViewController * controller;

/*
 * 初始化方法
 * @param appkey 为应用id
 * @param positionID 为广告位id
 */
- (instancetype)initWithAppKey:(NSString *)appkey positionID:(NSString *)positionID;

/*
 * 广告加载方法
 * @param count 一次请求广告的个数
 */
- (void)loadNativeAdWithCount:(int)count;

/**
 如果您需要使用OMSDK,则务必在发送展示汇报之前从VAST里解析这三个参数,并且传递进来

 @param nativeData 广告模型
 @param vendorKey <Verification vendor="AdView">
 @param verificationScriptURLString <JavaScriptResource apiFramework="omid" browserOptional="true">
 @param verificationParameters <VerificationParameters>
 */
- (void)vastVideoOMSDKAdNativeData:(AdViewNativeData *)nativeData
             setParameterVendorKey:(NSString *)vendorKey
       verificationScriptURLString:(NSString *)verificationScriptURLString
            verificationParameters:(NSString *)verificationParameters
                     videoDuration:(CGFloat)duration
                        skipOffset:(CGFloat)skipOffset
                 videoPlayerVolume:(CGFloat)videoPlayerVolume
                          position:(NSUInteger)position
                          autoPlay:(BOOL)autoPlay;

/*
 * 广告view渲染完毕后即将展示调用方法（用于发送相关汇报）
 * @param nativeData 渲染广告的数据对象
 * @param view 渲染出的广告页面
 */
- (void)showNativeAdWithData:(AdViewNativeData*)nativeData
    friendlyObstructionArray:(NSArray<UIView *> *)friendlyViewArray
                      onView:(UIView*)view;

//OMSDK监测事件点
- (void)reportVideoQuartile:(AdViewOMSDKVideoQuartile)quartile withData:(AdViewNativeData *)nativeData;
- (void)reportVideoSkippedWithData:(AdViewNativeData *)nativeData;
- (void)reportVideoPauseWithData:(AdViewNativeData *)nativeData;
- (void)reportVideoResumeWithData:(AdViewNativeData *)nativeData;
- (void)reportVideoVolumeChangeTo:(CGFloat)playerVolume  withData:(AdViewNativeData *)nativeData;
- (void)videoOrientation:(UIInterfaceOrientation)orientation withData:(AdViewNativeData *)nativeData;

/*
 * 广告点击调用的方法
 * 当⽤户点击广告时,开发者需调用本方法,sdk会做出相应响应（用于发送点击汇报）
 * @param nativeData 被点击的广告的数据对象
 * @param point 点击坐标，广告需要用户点击坐标的位置，否则会影响收益；如果广告视图size为（300，200），左上角point值为（0，0），右下角为（300，200）,以此为例计算point大小；
 * @param view 渲染出的广告页面
 */
- (void)clickNativeAdWithData:(AdViewNativeData *)nativeData
               withClickPoint:(CGPoint)point
                       onView:(UIView *)view;
@end

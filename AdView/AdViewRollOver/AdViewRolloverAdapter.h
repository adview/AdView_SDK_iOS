//
//  RolloverAdapter.h
//  KOpenAPIAdView
//
//  Created by AdView on 2018/8/15.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "AdViewRolloverAdapterModel.h"

@class AdViewRolloverManager;
@interface AdViewRolloverAdapter : NSObject

@property (nonatomic, strong) AdViewRolloverManager *manager;
@property (nonatomic, copy) NSString *appID;                // AppID
@property (nonatomic, copy) NSString *positionID;           // 广告位ID
@property (strong, nonatomic) UIViewController *controller; // 广告展示controller
@property (assign, nonatomic) int responseCount;            // 回调响应次数
@property (copy, nonatomic) NSArray *nativeAdArray;         // 原生广告数组

- (instancetype)initWithDataModel:(AdViewRolloverAdapterModel*)model;

- (void)presetConfig;

- (void)getBannerAd;

- (void)loadInstallAd;
- (void)showInstallWithController:(UIViewController*)controller;

- (void)loadSplashAd;

- (void)loadVideoAd;
- (void)showVideoWithController:(UIViewController*)controller;

- (void)loadNativeAdWithConunt:(int)count;
- (void)showNativeAdWithIndex:(NSUInteger)index toView:(UIView*)view;
- (void)clickNativeAdWithIndex:(NSUInteger)index onView:(UIView*)view;

- (void)releaseAdapter;

@end

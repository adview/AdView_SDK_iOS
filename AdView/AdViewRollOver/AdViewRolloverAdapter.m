//
//  RolloverAdapter.m
//  KOpenAPIAdView
//
//  Created by AdView on 2018/8/15.
//

#import "AdViewRolloverAdapter.h"

@interface AdViewRolloverAdapter ()


@end

@implementation AdViewRolloverAdapter
- (instancetype)initWithDataModel:(AdViewRolloverAdapterModel *)model {
    if (self = [super init]) {
        self.appID = model.appid;
        self.positionID = model.posid;
        self.responseCount = 0;
        [self presetConfig];
    }
    return self;
}

- (void)presetConfig {}

- (void)getBannerAd {}

- (void)loadInstallAd {}
- (void)showInstallWithController:(UIViewController*)controller {}

- (void)loadSplashAd {}

- (void)loadNativeAdWithConunt:(int)count {}
- (void)loadNativeViewWithConunt:(int)count withSize:(CGSize)size {}
- (void)showNativeAdWithIndex:(NSUInteger)index toView:(UIView*)view {}
- (void)clickNativeAdWithIndex:(NSUInteger)index onView:(UIView *)view {}

- (void)loadVideoAd {}
- (void)showVideoWithController:(UIViewController*)controller {}

- (void)releaseAdapter {}

@end

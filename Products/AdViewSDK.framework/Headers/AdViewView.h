//
//  AdViewView.h
//  Adview SDK
//
//  Created by Adview on 1/1/19.
//  Copyright © 2019 Adview. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AdViewViewDelegate.h"
#import "AdViewDefinesPublic.h"

@interface AdViewView : UIView
@property (nonatomic, weak) id <AdViewViewDelegate> delegate;
@property (nonatomic, readonly,assign) AdvertType advertType;   //Banner、Interstitial、Spread

/**
 Banner request

 @param size banner size
 @param positionId banner positionId
 @param delegate see AdViewViewDelegate
 @return the Banner view
 */
+ (AdViewView *)requestBannerSize:(AdViewBannerSize)size
                       positionId:(NSString *)positionId
                         delegate:(id<AdViewViewDelegate>)delegate;

/**
 Interstitial request

 @param delegate see AdViewViewDelegate
 @return the interstitial view
 */
+ (AdViewView *)requestAdInterstitialWithDelegate:(id<AdViewViewDelegate>)delegate;

/**
 Spread request

 @param delegate see AdViewViewDelegate
 @return the Spread view
 */
+ (AdViewView *)requestSpreadActivityWithDelegate:(id<AdViewViewDelegate>)delegate;

/**
 SDK version

 @return version stiring
 */
+ (NSString *)sdkVersion;

/**
 Show the Interstitial with a viewController

 @param rootViewController where Interstitial to show
 @return show success
 */
- (BOOL)showInterstitialWithRootViewController:(UIViewController *)rootViewController;
- (void)pauseRequestAd;
- (void)resumeRequestAd;
- (void)clearCaches;

@end

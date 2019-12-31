
#ifndef AdViewDefinesPublic_h
#define AdViewDefinesPublic_h
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

/**
 The Banner sizes
 */
typedef NS_ENUM(NSInteger, AdViewBannerSize)
{
    AdViewBannerSize_320x50,
    AdViewBannerSize_480x44,
    AdViewBannerSize_300x250,   //MREC
    AdViewBannerSize_480x60,
    AdViewBannerSize_728x90,
};

/**
 The ad type
 */
typedef NS_ENUM(NSInteger, AdvertType){
    AdViewBanner       = 0,
    AdViewInterstitial = 1,
    AdViewSpread       = 4,
    AdViewRewardVideo  = 5,
    AdViewNative       = 6
};

/**
 Video type
 */
typedef NS_ENUM(NSUInteger, AdViewVideoType) {
    AdViewVideoTypeInstl,       //present video
    AdViewVideoTypePreMovie,    //custom  video
};

/**
 Network error
 */
typedef NS_ENUM(NSInteger, AdViewHTTPStatus) {
    HTTPStatusUnkonw  = 0,
    HTTPStatusSuccess = 200,
};

//OMSDK video
typedef NS_ENUM(NSInteger, AdViewOMSDKVideoQuartile){
    AdViewOMSDKVideoQuartile_None,              // None
    AdViewOMSDKVideoQuartile_Start,             // 0/1 begin
    AdViewOMSDKVideoQuartile_FirstQuartile,     // 1/4
    AdViewOMSDKVideoQuartile_Midpoint,          // 1/2
    AdViewOMSDKVideoQuartile_ThirdQuartile,     // 3/4
    AdViewOMSDKVideoQuartile_Complete           // 1/4 finish
};

#endif /* AdViewDefinesPublic_h */

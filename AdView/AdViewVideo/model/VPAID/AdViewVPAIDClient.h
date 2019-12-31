//
//  AdViewVPAIDClient.h
//  AdViewSDK
//
//  Copyright (c) 2016 AdView. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <JavaScriptCore/JavaScriptCore.h>

@protocol AdViewVpaidProtocol;
extern const struct AdViewVPAIDViewModeStruct {
    __unsafe_unretained NSString *normal;
    __unsafe_unretained NSString *thumbnail;
    __unsafe_unretained NSString *fullscreen;

} AdViewVPAIDViewMode;

@interface AdViewVPAIDClient : NSObject
- (instancetype)initWithDelegate:(id<AdViewVpaidProtocol>)deleagate jsContext:(JSContext *)context;
- (double)handshakeVersion;
- (void)initAdWithWidth:(int)width
                 height:(int)height
               viewMode:(NSString *)viewMode
         desiredBitrate:(double)desiredBitrate
           creativeData:(NSDictionary *)creativeData
        environmentVars:(NSDictionary *)environmentVars;
- (void)resizeAdWithWidth:(int)width
                   height:(int)height
                 viewMode:(NSString *)viewMode;
- (void)startAd;
- (void)stopAd;
- (void)pauseAd;
- (void)resumeAd;
- (void)expandAd;
- (void)collapseAd;
- (void)skipAd;
- (BOOL)getAdExpanded;
- (BOOL)getAdSkippableState;
- (BOOL)getAdLinear;
- (NSInteger)getAdWidth;
- (NSInteger)getAdHeight;
- (NSInteger)getAdRemainingTime;
- (NSInteger)getAdDuration;
- (double)getAdVolume;
- (void)setAdVolume:(double)volume;
- (NSString *)getAdViewanions;
- (BOOL)getAdIcons;
- (void)stopActionTimeOutTimer;

@end

@protocol AdViewVpaidProtocol <JSExport>

- (void)vpaidAdLoaded;
- (void)vpaidAdSizeChange;
- (void)vpaidAdStarted;
- (void)vpaidAdStopped;
- (void)vpaidAdPaused;
- (void)vpaidAdPlaying;
- (void)vpaidAdExpandedChange;
- (void)vpaidAdSkipped;
- (void)vpaidAdVolumeChanged;
- (void)vpaidAdSkippableStateChange;
- (void)vpaidAdLinearChange;
- (void)vpaidProgressChanged;
- (void)vpaidAdDurationChange;
- (void)vpaidAdRemainingTimeChange;
- (void)vpaidAdImpression;

- (void)vpaidAdVideoStart;
- (void)vpaidAdVideoFirstQuartile;
- (void)vpaidAdVideoMidpoint;
- (void)vpaidAdVideoThirdQuartile;
- (void)vpaidAdVideoComplete;

- (void)vpaidAdClickThru:(NSString *)url id:(NSString *)Id playerHandles:(BOOL)playerHandles;
- (void)vpaidAdInteraction:(NSString *)eventID;
- (void)vpaidAdUserAcceptInvitation;
- (void)vpaidAdUserMinimize;
- (void)vpaidAdUserClose;

- (void)vpaidAdError:(NSString *)error;
- (void)vpaidAdLog:(NSString *)message;

- (void)vpaidJSError:(NSString *)message;

@end

//JSBridge的protocol消息转发者
@interface AdViewVPAIDClientProxy : NSProxy <AdViewVpaidProtocol>       //⚠️ 必须遵循协议 否则消息转发找不到协议方法
@property (nonatomic, weak) NSObject <AdViewVpaidProtocol>* target;
+ (instancetype)proxyWithTarget:(id)target;
@end


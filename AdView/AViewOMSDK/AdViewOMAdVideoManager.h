//
//  ADVGOMAdVideoManager.h
//  AdViewHello
//
//  Created by unakayou on 7/24/19.
//

#import "AdViewOMBaseAdUnitManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface AdViewOMAdVideoManager : AdViewOMBaseAdUnitManager
@property (nonatomic, copy) NSString * vendorKey;
@property (nonatomic, copy) NSString * verificationScriptURLString;
@property (nonatomic, copy) NSString * verificationParameters;

@property (nonatomic, assign) CGFloat skipOffset;       //几秒之后可以跳过
@property (nonatomic, assign) BOOL autoPlay;            //自动播放
@property (nonatomic, assign) OMIDPosition position;    //???
@property (nonatomic, assign) CGFloat duration;         //视频时长
@property (nonatomic, assign) CGFloat volume;           //声音


@property (nonatomic, strong, readonly) OMIDAdviewVideoEvents * videoEvent;     //video专用事件
@property (nonatomic, assign, readonly) AdViewOMSDKVideoQuartile quartile;      //当前video状态

- (instancetype)initWithVendorKey:(NSString *)vendor
           verificationParameters:(NSString *)verificationParameters
      verificationScriptURLString:(NSString *)verificationScriptURLString;

- (void)reportQuartileChange:(AdViewOMSDKVideoQuartile)quartile;        //进度
- (void)adUserInteractionWithType:(OMIDInteractionType)interactionType; //点击
- (void)skipped;
- (void)pause;
- (void)resume;
- (void)volumeChangeTo:(CGFloat)playerVolume;
- (void)videoOrientation:(UIInterfaceOrientation)orientation;
@end

NS_ASSUME_NONNULL_END

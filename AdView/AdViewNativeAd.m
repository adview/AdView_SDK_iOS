//
//  AdViewNativeAd.m
//  AdViewHello
//
//  Created by AdView on 15/10/22.
//
//

#import "AdViewNativeAd.h"
#import "AdViewAdManager.h"
#import "AdViewExtTool.h"
#import "AdViewContent.h"
#import "AdViewOMAdImageManager.h"
#import "AdViewOMAdVideoManager.h"

@implementation AdViewNativeData
@synthesize adProperties;
@synthesize nativeAdId;
@end

@interface AdViewNativeAd ()
@property (nonatomic, strong) AdViewAdManager *adData;
@property (nonatomic, strong) AdViewAdCondition *condition;
@property (nonatomic, strong) NSArray <AdViewContent *>*contentArr;
@property (nonatomic, assign) BOOL isTest;
@property (nonatomic, strong) UIView *adView;
@property (nonatomic, strong) NSMutableDictionary <NSString *,AdViewOMBaseAdUnitManager *>* omsdkManagerDict;
@end

@implementation AdViewNativeAd
- (instancetype)initWithAppKey:(NSString*)appkey positionID:(NSString*)positionID {
    if (self = [super init]) {
        //启动OMSDK
        [AdViewOMBaseAdUnitManager activateOMIDSDK];
        
        _adData = [[AdViewAdManager alloc] initWithAdPlatType:AdViewAdPlatTypeAdview];
        _condition = [[AdViewAdCondition alloc] init];
        _condition.appId = appkey;
        _condition.positionId = positionID;
        
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(nativeAdResignActive:)
         name:UIApplicationDidEnterBackgroundNotification
         object:nil];
        
        @WeakObj(self)
        [self.adData didReceivedNativeData:^(NSArray* contentArr) {
            selfWeak.contentArr = [NSArray arrayWithArray:contentArr];
            selfWeak.omsdkManagerDict = [[NSMutableDictionary alloc] initWithCapacity:contentArr.count];
            
            if ([selfWeak.delegate respondsToSelector:@selector(adViewNativeAdSuccessToLoadAd: NativeData:)]) {
                [selfWeak.delegate adViewNativeAdSuccessToLoadAd:selfWeak NativeData:[selfWeak exchangeContentAdToNativeData]];
            }
        }];
        
        [self.adData failToLoadNativeData:^(NSError* error) {
            if ([selfWeak.delegate respondsToSelector:@selector(adViewNativeAdFailToLoadAd: WithError:)]) {
                [selfWeak.delegate adViewNativeAdFailToLoadAd:selfWeak WithError:error];
            }
        }];

        //点击广告弹出
        [self.adData nativeAdShowPresent:^() {
            if ([selfWeak.delegate respondsToSelector:@selector(adViewNativeAdWillShowPresent)]) {
                [selfWeak.delegate adViewNativeAdWillShowPresent];
            }
        }];

        //关闭广告弹出
        [self.adData nativeAdClose:^() {
            if (selfWeak.delegate && [selfWeak.delegate respondsToSelector:@selector(adViewNativeAdClosed)]) {
                [selfWeak.delegate adViewNativeAdClosed];
            }
        }];
    }
    return self;
}

- (void)nativeAdResignActive:(NSNotification*)notifation {
    if (self.delegate && [self.delegate respondsToSelector:@selector(adViewNativeAdResignActive)])
        [self.delegate adViewNativeAdResignActive];
}

- (NSArray*)exchangeContentAdToNativeData {
    NSMutableArray *nativeDataArr = [[NSMutableArray alloc] init];
    for (AdViewContent * content in self.contentArr) {
        if ([content isKindOfClass:[AdViewContent class]]) {
            AdViewNativeData *nativeData = [[AdViewNativeData alloc] init];
            nativeData.nativeAdId = content.adId;
            nativeData.adProperties = content.nativeDict;
            [nativeDataArr addObject:nativeData];
        } else {
            [nativeDataArr addObject:content];
        }
    }
    return nativeDataArr;
}

- (void)setTestMode {
    self.isTest = YES;
}

- (void)loadNativeAdWithCount:(int)count {
    _adData.presentController = self.controller;
    _adData.advertType = AdViewNative;
    _adData.nativeAdCount = count;
    
    if (!_condition.appId || ![_condition.appId length]) {
        NSError *error = [NSError errorWithDomain:@"appkey异常" code:0 userInfo:nil];
        [self.delegate adViewNativeAdFailToLoadAd:self WithError:error];
        return;
    }
    
    if (!_condition.positionId || ![_condition.positionId length]) {
        NSError *error = [NSError errorWithDomain:@"广告位异常" code:0 userInfo:nil];
        [self.delegate adViewNativeAdFailToLoadAd:self WithError:error];
        return;
    }
    
    BOOL subjectToGDPR = NO;
    NSString * consentString = nil;
    
    BOOL CMPPresen = NO;
    NSString * parsedPurposeConsents = nil;
    NSString * parsedVendorConsents  = nil;
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    
    //如果保存了则全部使用保存的GDPR设置,否则使用协议设置
    if ([userDefaults objectForKey:AdView_IABConsent_CMPPresent]) {
        CMPPresen = [[userDefaults objectForKey:AdView_IABConsent_CMPPresent] boolValue];
        subjectToGDPR = [[userDefaults objectForKey:AdView_IABConsent_SubjectToGDPR] boolValue];
        consentString = [userDefaults objectForKey:AdView_IABConsent_ConsentString];
        parsedPurposeConsents = [userDefaults objectForKey:AdView_IABConsent_ParsedPurposeConsents];
        parsedVendorConsents = [userDefaults objectForKey:AdView_IABConsent_ParsedVendorConsents];
    } else {
        if ([self.delegate respondsToSelector:@selector(subjectToGDPR)]) {
            subjectToGDPR = [self.delegate subjectToGDPR];
        }
        
        if ([self.delegate respondsToSelector:@selector(userConsentString)]) {
            consentString = [self.delegate userConsentString];
        }
        
        if ([self.delegate respondsToSelector:@selector(CMPPresent)]) {
            CMPPresen = [self.delegate CMPPresent];
        }
        
        if ([self.delegate respondsToSelector:@selector(parsedPurposeConsents)]) {
            parsedPurposeConsents = [self.delegate parsedPurposeConsents];
        }
        
        if ([self.delegate respondsToSelector:@selector(parsedVendorConsents)]) {
            parsedVendorConsents = [self.delegate parsedVendorConsents];
        }
    }
    
    //拼接请求参数model
    _condition.adCount = count;
    _condition.adTest = self.isTest;
    _condition.adverType = AdViewNative;
    _condition.CMPPresent = CMPPresen;
    _condition.gdprApplicability = subjectToGDPR;
    _condition.consentString = consentString;
    _condition.parsedPurposeConsents = parsedPurposeConsents;
    _condition.parsedVendorConsents = parsedVendorConsents;
    _condition.CCPAString = [userDefaults objectForKey:AdView_IABConsent_CCPA];
    
    //开始请求
    [_adData requestAdWithConnetion:_condition];
    
    //如果开始load下一次广告,则把目前已经发送开始监测的广告统统发送展示完毕
    [self finishOMSDKMeasurement];
}

//通过对外Model获取对内Model
- (AdViewContent*)matchNativeAdIDWith:(AdViewNativeData*)nativeData {
    for (AdViewContent *content in self.contentArr) {
        if ([content.adId isEqualToString:nativeData.nativeAdId]) {
            return content;
        }
    }
    return nil;
}

//展示汇报
- (void)showNativeAdWithData:(AdViewNativeData*)nativeData
    friendlyObstructionArray:(NSArray<UIView *> *)friendlyViewArray
                      onView:(UIView *)view {
    AdViewContent * content = [self matchNativeAdIDWith:nativeData];
    if (nativeData.rolloverManager) {
        [nativeData.rolloverManager showNativeAdWithIndex:[nativeData.nativeAdId integerValue] toView:view];
    } else {
        self.adView = view;
        _adData.adContent = content;
        [_adData requestDisplay];
    }
    
    //初始化一个广告配套的omsdkManager,并且开启监测
    AdViewOMBaseAdUnitManager * omsdkManager = [self makeOMSDKManagerWithAdContent:content
                                                          friendlyObstructionArray:friendlyViewArray
                                                                            onView:view];
    [_omsdkManagerDict setObject:omsdkManager forKey:nativeData.nativeAdId];
}

- (void)reportVideoQuartile:(AdViewOMSDKVideoQuartile)quartile withData:(AdViewNativeData *)nativeData {
    AdViewContent * content = [self matchNativeAdIDWith:nativeData];
    AdViewOMAdVideoManager * videoManager = (AdViewOMAdVideoManager *)[_omsdkManagerDict objectForKey:content.adId];
    if ([videoManager isKindOfClass:[AdViewOMAdVideoManager class]]) {
        [videoManager reportQuartileChange:quartile];
    }
}

- (void)reportVideoPauseWithData:(AdViewNativeData *)nativeData {
    AdViewContent * content = [self matchNativeAdIDWith:nativeData];
    AdViewOMAdVideoManager * videoManager = (AdViewOMAdVideoManager *)[_omsdkManagerDict objectForKey:content.adId];
    if ([videoManager isKindOfClass:[AdViewOMAdVideoManager class]]) {
        [videoManager pause];
    }
}

- (void)reportVideoResumeWithData:(AdViewNativeData *)nativeData {
    AdViewContent * content = [self matchNativeAdIDWith:nativeData];
    AdViewOMAdVideoManager * videoManager = (AdViewOMAdVideoManager *)[_omsdkManagerDict objectForKey:content.adId];
    if ([videoManager isKindOfClass:[AdViewOMAdVideoManager class]]) {
        [videoManager resume];
    }
}

- (void)reportVideoSkippedWithData:(AdViewNativeData *)nativeData {
    AdViewContent * content = [self matchNativeAdIDWith:nativeData];
    AdViewOMAdVideoManager * videoManager = (AdViewOMAdVideoManager *)[_omsdkManagerDict objectForKey:content.adId];
    if ([videoManager isKindOfClass:[AdViewOMAdVideoManager class]]) {
        [videoManager skipped];
    }
}

- (void)reportVideoVolumeChangeTo:(CGFloat)playerVolume withData:(AdViewNativeData *)nativeData {
    AdViewContent * content = [self matchNativeAdIDWith:nativeData];
    AdViewOMAdVideoManager * videoManager = (AdViewOMAdVideoManager *)[_omsdkManagerDict objectForKey:content.adId];
    if ([videoManager isKindOfClass:[AdViewOMAdVideoManager class]]) {
        [videoManager volumeChangeTo:playerVolume];
    }
}

- (void)videoOrientation:(UIInterfaceOrientation)orientation withData:(AdViewNativeData *)nativeData {
    AdViewContent * content = [self matchNativeAdIDWith:nativeData];
    AdViewOMAdVideoManager * videoManager = (AdViewOMAdVideoManager *)[_omsdkManagerDict objectForKey:content.adId];
    if ([videoManager isKindOfClass:[AdViewOMAdVideoManager class]]) {
        [videoManager videoOrientation:orientation];
    }
}

- (void)clickNativeAdWithData:(AdViewNativeData*)nativeData withClickPoint:(CGPoint)point onView:(UIView *)view
{
    AdViewContent * content = [self matchNativeAdIDWith:nativeData];
    if (nativeData.rolloverManager) {
        [nativeData.rolloverManager clickNativeAdWithIndex:[nativeData.nativeAdId integerValue] onView:view];
    } else {
        _adData.adContent = content;
        [_adData requestClick];
        
        _adData.adPrefSize = self.adView.frame.size;
        [_adData setClickPositionDicWithTouchPoint:point isBegan:YES];
        [_adData setClickPositionDicWithTouchPoint:point isBegan:NO];
        
        [_adData openLink:_adData.adContent];
        [_adData reportDisplayOrClickInfoToOther:NO];
    }
    
    AdViewOMAdVideoManager * videoManager = (AdViewOMAdVideoManager *)[_omsdkManagerDict objectForKey:content.adId];
    if ([videoManager isKindOfClass:[AdViewOMAdVideoManager class]]) {
        [videoManager adUserInteractionWithType:OMIDInteractionTypeClick];
    }

}

//typedef NS_ENUM(NSUInteger, AdViewNativeVideoStatus) {
//    AdViewNativeVideoStatus_StartPlay,
//    AdViewNativeVideoStatus_MiddlePlay,
//    AdViewNativeVideoStatus_CompletePlay,
//    AdViewNativeVideoStatus_Pause,
//    AdViewNativeVideoStatus_TerminationPlay,
//};

/*
 * 用于视频原生数据汇报方法
 * 当触发AdViewNativeVideoStatus中某个状态时，调用该方法
 * @param nativeData 当前广告使用的数据对象
 * @param videoStatus 视频播放的状态
 * @param dataAcquistionObj 该对象中的数据用于替换响应汇报中的宏字段，务必填写
 */
//- (void)reportWithData:(AdViewNativeData *)nativeData
//                status:(AdViewNativeVideoStatus)videoStatus
// dataAcquisitionObject:(AdViewNativeVideoDataAcquisitionObject *)dataAcquistionObj {
//    NSDictionary *videoDict = [nativeData.adProperties objectForKey:@"video"];
//    int duration = [[videoDict objectForKey:@"duration"] intValue];
//    if (dataAcquistionObj.duration <= 0) {
//        dataAcquistionObj.duration = duration;
//    }
//    [self setDefineStringWithObject:dataAcquistionObj];
//    NSMutableArray *strArr;
//    switch (videoStatus) {
//        case AdViewNativeVideoStatus_StartPlay: {
//            strArr = [videoDict objectForKey:@"sptrackers"];
//        }
//            break;
//        case AdViewNativeVideoStatus_MiddlePlay: {
//            strArr = [videoDict objectForKey:@"mptrackers"];
//        }
//            break;
//        case AdViewNativeVideoStatus_CompletePlay: {
//            NSArray *cStrArr = [videoDict objectForKey:@"cptrackers"];
//            NSArray *pStrArr = [videoDict objectForKey:@"playmonurls"];
//            [strArr addObjectsFromArray:cStrArr];
//            [strArr addObjectsFromArray:pStrArr];
//        }
//            break;
//        case AdViewNativeVideoStatus_Pause: {
//            strArr = [videoDict objectForKey:@"playmonurls"];
//        }
//            break;
//        case AdViewNativeVideoStatus_TerminationPlay: {
//            strArr = [videoDict objectForKey:@"playmonurls"];
//        }
//            break;
//        default:
//            break;
//    }
//    [self reportVideoAddressWithArray:strArr];
//}
//
//- (void)setDefineStringWithObject:(AdViewNativeVideoDataAcquisitionObject*)dataAcquistionObj {
//    [[AdViewExtTool sharedTool] storeObject:[NSString stringWithFormat:@"%d", dataAcquistionObj.duration] forKey:@"__DURATION__"];
//    [[AdViewExtTool sharedTool] storeObject:[NSString stringWithFormat:@"%d", dataAcquistionObj.beginTime] forKey:@"__BEGINTIME__"];
//    [[AdViewExtTool sharedTool] storeObject:[NSString stringWithFormat:@"%d", dataAcquistionObj.endTime] forKey:@"__ENDTIME__"];
//    [[AdViewExtTool sharedTool] storeObject:[NSString stringWithFormat:@"%d", dataAcquistionObj.firstFrame] forKey:@"__FIRST_FRAME__"];
//    [[AdViewExtTool sharedTool] storeObject:[NSString stringWithFormat:@"%d", dataAcquistionObj.lastFrame] forKey:@"__LAST_FRAME__"];
//    [[AdViewExtTool sharedTool] storeObject:[NSString stringWithFormat:@"%d", dataAcquistionObj.scene] forKey:@"__SCENE__"];
//    [[AdViewExtTool sharedTool] storeObject:[NSString stringWithFormat:@"%d", dataAcquistionObj.type] forKey:@"__TYPE__"];
//    [[AdViewExtTool sharedTool] storeObject:[NSString stringWithFormat:@"%d", dataAcquistionObj.behavior] forKey:@"__BEHAVIOR__"];
//    [[AdViewExtTool sharedTool] storeObject:[NSString stringWithFormat:@"%d", dataAcquistionObj.status] forKey:@"__STATUS__"];
//}
//
//- (void)reportVideoAddressWithArray:(NSArray *)stringArray {
//    if (!stringArray || stringArray.count <= 0) {
//        return;
//    }
//    for (NSString *urlString in stringArray) {
//        if (urlString && urlString.length) {
//            NSString *urlStr = [[AdViewExtTool sharedTool] replaceDefineString:urlString];
//            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
//            [NSURLConnection connectionWithRequest:request delegate:nil];
//        }
//    }
//}

- (void)vastVideoOMSDKAdNativeData:(AdViewNativeData *)nativeData
             setParameterVendorKey:(NSString *)vendorKey
       verificationScriptURLString:(NSString *)verificationScriptURLString
            verificationParameters:(NSString *)verificationParameters
                     videoDuration:(CGFloat)duration
                        skipOffset:(CGFloat)skipOffset
                 videoPlayerVolume:(CGFloat)videoPlayerVolume
                          position:(NSUInteger)position
                          autoPlay:(BOOL)autoPlay {
    //如果设置了这些,则提前初始化manager
    AdViewContent * content = [self matchNativeAdIDWith:nativeData];
    AdViewOMAdVideoManager * omsdkVideoManager = [[AdViewOMAdVideoManager alloc] initWithVendorKey:vendorKey
                                                                            verificationParameters:verificationParameters
                                                                       verificationScriptURLString:verificationScriptURLString];
    omsdkVideoManager.autoPlay = autoPlay;
    omsdkVideoManager.position = position;
    omsdkVideoManager.volume   = videoPlayerVolume;
    omsdkVideoManager.duration = duration;
    omsdkVideoManager.skipOffset = skipOffset;
    [_omsdkManagerDict setObject:omsdkVideoManager forKey:content.adId];
}

- (AdViewOMBaseAdUnitManager *)makeOMSDKManagerWithAdContent:(AdViewContent *)content
                                  friendlyObstructionArray:(NSArray<UIView *> *)friendlyViewArray
                                                    onView:(UIView*)view {
    AdViewOMBaseAdUnitManager * omsdkManager = nil;
    if (content.nativeDict[@"video"]) {
        //video的manager已经提前在设置vendorkey等方法中初始化了
        omsdkManager = (AdViewOMAdVideoManager *)_omsdkManagerDict[content.adId];
    } else {
        //图片
        omsdkManager = [[AdViewOMAdImageManager alloc] initWithVendorKey:content.nativeDict[@"omvendor"]
                                                  verificationParameters:content.nativeDict[@"ompara"]
                                             verificationScriptURLString:content.nativeDict[@"omurl"]];
    }
    [omsdkManager setMainAdview:view];
    for (UIView * view in friendlyViewArray) {
        [omsdkManager setFriendlyObstruction:view];
    }
    [omsdkManager startMeasurement];
    return omsdkManager;
}

- (void)finishOMSDKMeasurement {
    for (AdViewOMAdImageManager * manager in _omsdkManagerDict.allValues) {
        [manager finishMeasurement];
    }
    [self.omsdkManagerDict removeAllObjects];
}

- (void)dealloc {
    [self finishOMSDKMeasurement];
}
@end

//@interface AdViewNativeVideoDataAcquisitionObject : NSObject
//
//@property (nonatomic, assign) int duration;     // 视频总时长，单位为秒
//@property (nonatomic, assign) int beginTime;    // 视频播放开始时间，单位为妙。如果视频从头开始播放，则为0
//@property (nonatomic, assign) int endTime;      // 视频播放结束时间，单位为妙。如果视频播放到结尾，则等于视频总时长
//@property (nonatomic, assign) int firstFrame;   // 视频是否从第一帧开始播放。是的话为1，否则为0
//@property (nonatomic, assign) int lastFrame;    // 视频是否播放到最后一帧。播放到最后一帧则为1；否则为0
//@property (nonatomic, assign) int scene;
//// 视频播放场景；
//// 1-> 在广告曝光区域播放
//// 2-> 全屏竖屏、只展示视频
//// 3-> 全屏竖屏、屏幕上方展示视频、下方展示广告推广页面
//// 4-> 全屏横屏、只展示视频
//// 0-> 其他自定义场景
//
//@property (nonatomic, assign) int type;
//// 播放类型
//// 1-> 第一次播放
//// 2-> 暂停后继续播放
//// 3-> 重新开始播放
//
//@property (nonatomic, assign) int behavior;
//// 播放行为
//// 1-> 自动播放
//// 2-> 点击播放
//
//@property (nonatomic, assign) int status;
//// 播放状态
//// 0-> 正常播放
//// 1-> 视频加载中
//// 2-> 下载或播放错误
//
//@end
//
//
//@implementation AdViewNativeVideoDataAcquisitionObject
//- (instancetype)init {
//    if (self = [super init]) {
//        self.duration = 0;
//        self.beginTime = 0;
//        self.endTime = 0;
//        self.firstFrame = 1;
//        self.lastFrame = 1;
//        self.scene = 0;
//        self.type = 1;
//        self.behavior = 1;
//        self.status = 0;
//    }
//    return self;
//}
//@end

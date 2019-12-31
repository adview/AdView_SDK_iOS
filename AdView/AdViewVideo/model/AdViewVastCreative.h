//
//  ADVASTMediaFileModel.h
//  KOpenAPIAdView
//
//  Created by AdView on 2018/4/27.
//  AD里的Creative

#import <Foundation/Foundation.h>
#import "AdViewVastMediaFile.h"
#import "AdViewVastUrlWithId.h"
#import "ADVASTIconModel.h"

typedef enum {
    ADVideoEventTrackCreativeView,
    ADVideoEventTrackStart,
    ADVideoEventTrackFirstQuartile,
    ADVideoEventTrackMidpoint,
    ADVideoEventTrackThirdQuartile,
    ADVideoEventTrackComplete,
    ADVideoEventTrackCloseLinear,
    ADVideoEventTrackPause,
    ADVideoEventTrackResume,
    ADVideoEventTrackMute,
    ADVideoEventTrackUnMute,
    ADVideoEventTrackSkip
}ADVideoEvent;

@interface AdViewVastCreative : NSObject
@property (nonatomic, strong) NSArray <AdViewVastMediaFile *>* mediaFiles;
@property (nonatomic, strong) AdViewVastMediaFile *mediaFile;       // mediaFiles数组中选出一个合适的mediafile
@property (nonatomic, strong) NSString *skipoffset;                 // 跳过时间 -1
@property (nonatomic, strong) NSString *duration;                   // 持续时间
@property (nonatomic, strong) NSDictionary *trackings;              // 监听网址
@property (nonatomic, strong) AdViewVastUrlWithId *clickThrough;    // 点击跳转地址
@property (nonatomic, strong) NSArray *clickTrackings;              // 点击事件监听
@property (nonatomic, strong) NSArray *iconArray;                   // icon数组
@property (nonatomic, strong) NSArray *adParametersArray;           // 发送到媒体JS文件的数据
@property (nonatomic, strong) NSString *sequence;                   // 编号

@property (nonatomic, copy) NSArray *wrapperTrackingArray;          // wrapper相关tracking监听网址数组
@property (nonatomic, copy) NSArray *wrapperClickTrackingArray;     // wrapper相关点击事件监听

- (void)trackEvent:(ADVideoEvent)vastEvent;                         // sends the given ADVideoEvent
- (void)reportClickTrackings;
@end

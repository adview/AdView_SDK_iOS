//
//  AdViewVideoGeneralView.h
//  KOpenAPIAdView
//
//  Created by AdView on 2018/4/26.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AdViewDefinesPublic.h"
#import "AdViewVastAdModel.h"
#import "AdViewVastCreative.h"

typedef enum {
    VASTFirstQuartile,
    VASTSecondQuartile,
    VASTThirdQuartile,
    VASTFourtQuartile,
} CurrentVASTQuartile;

@protocol AdViewVideoGeneralViewDelegate <NSObject>
- (void)videoStartPlay;
- (void)videotEndPlay;
- (void)videoSkipped;
- (void)videoPaused;
- (void)videoResumed;
- (void)videoPlayError;
- (void)videoMute:(BOOL)isMute;
- (void)videoUpdatePlayTime:(NSString*)timeString;
- (void)videoUpdateCurrentVASTQuartile:(CurrentVASTQuartile)currentVastQuartile;
//- (void)image;
- (void)showSkipView;
- (void)contentViewClickedWithUrl:(NSURL*)url;
@end

@interface AdViewVideoGeneralView : UIWebView
@property (nonatomic, weak) id<AdViewVideoGeneralViewDelegate> eventDelegate;
@property (nonatomic, strong) AdViewVastAdModel * vastModel;            //VAST的AD标签
@property (nonatomic, strong) AdViewVastCreative * mediaFileModel;      //包含媒体信息的模型
@property (nonatomic, assign) ADVASTMediaFileType mediaFileType;        //视频、VPAID、HTML等
@property (nonatomic, assign) AdvertType adverType;                     //Banner、插屏、video
@property (nonatomic, assign) BOOL cancelCountdown;                     //最后一个Creative创建伴随?

- (void)loadGeneralViewWithFileModel:(AdViewVastCreative *)creative delegate:(id<AdViewVideoGeneralViewDelegate>)delegate;
- (void)replaceFileModel:(AdViewVastCreative *)creative;
- (CGSize)getViewSizeWith:(AdViewVastMediaFile*)mediaFile;      //获取播放界面尺寸

- (void)stopVideo;                          //主动停止播放
- (void)skipVideo;                          //用户点击跳过video
- (void)videoPause;                         //暂停video
- (void)videoResume;                        //恢复video
- (BOOL)getVideoMute;                       //获取音量状态
- (void)setVideoMute:(BOOL)isMute;          //设置静音
- (NSString*)getVideoTotalTime;             //获取视频总时长
- (void)closeCreative;
@end

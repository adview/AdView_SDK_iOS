//
//  ADVASTViewController.h
//  AdViewVideoSample
//
//  Created by maming on 16/10/8.
//  Copyright © 2016年 maming. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "ADVASTError.h"

@class ADVASTViewController;

typedef enum {
    VASTVideoPlayStart,
    VASTVideoPlayEnd,
}ADVASTVideoStatus;

@protocol ADVASTViewControllerDelegate <NSObject>

@required

- (void)vastReady:(ADVASTViewController *)vastVC;  // sent when the video is ready to play - required

@optional

- (void)vastError:(ADVASTViewController *)vastVC error:(ADVASTError)error;  // sent when any VASTError occurs - optional

- (void)vastVideoAllPlayEnd:(ADVASTViewController *)vastVC;

// These optional callbacks are for basic presentation, dismissal, and calling video clickthrough url browser.
- (void)vastWillPresentFullScreen:(ADVASTViewController *)vastVC;
- (void)vastDidDismissFullScreen:(ADVASTViewController *)vastVC;
- (void)vastOpenBrowseWithUrl:(NSURL *)url;
- (void)vastTrackingEvent:(NSString *)eventName;

- (void)vastVideoPlayStatus:(ADVASTVideoStatus)videoStatus;
- (void)responsClickActionWithUrlString:(NSString*)clickStr;

@end

@interface ADVASTViewController : UIViewController
@property (nonatomic, unsafe_unretained) id<ADVASTViewControllerDelegate>delegate;
@property (nonatomic, strong) NSURL *clickThrough;
@property (nonatomic, assign) float leftGap;
@property (nonatomic, assign) float topGap;
@property (nonatomic, assign) BOOL enableAutoClose;
@property (nonatomic, assign) BOOL isShowAlertView; // 流量提示框是否展示
@property (nonatomic, assign) UIInterfaceOrientation orientation; //视频展示方向

- (id)initWithDelegate:(id<ADVASTViewControllerDelegate>)delegate;  // designated initializer for VASTViewController

- (void)loadVideoWithURL:(NSURL *)url;            // load and prepare to play a VAST video from a URL
- (void)loadVideoWithData:(NSData *)xmlContent;   // load and prepare to play a VAST video from existing XML data

// These actions are called by the VASTControls toolbar; the are exposed to enable an alternative custom VASTControls toolbar
- (void)play;                        // command to play the video, this is only valid after receiving the vastReady: callback
- (void)pause;                       // pause the video, useful when modally presenting a browser, for example
- (void)resume;                      // resume the video, useful when modally dismissing a browser, for example
- (void)info;                        // callback to host class for opening a browser to the URL specified in 'clickthrough'
- (void)close;                       // dismisses a video playing on screen
- (BOOL)isPlaying;                   // playing state

- (void)showFaildInfomation:(NSString*)failStr; //显示失败信息（通过Alert实现，AdViewVideo可以控制是否展示该失败信息）

@end

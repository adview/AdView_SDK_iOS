//
//  ADVASTViewController.m
//  AdViewVideoSample
//
//  Created by maming on 16/10/8.
//  Copyright © 2016年 maming. All rights reserved.
//

#import "ADVASTViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "ADVASTSettings.h"
#import "AdCompExtTool.h"
#import "ADVASTModel.h"
#import "ADVASTEventProcessor.h"
#import "ADVASTUrlWithId.h"
#import "ADVASTMediaFile.h"
#import "ADVAST2Parser.h"
#import "ADVASTMediaFilePicker.h"
#import "AdCompReachability.h"
#import <AVFoundation/AVFoundation.h>
#import "ADVASTNonVideoView.h"
#import "ADVASTVideoDownloadManager.h"
#import "ADVASTFileHandle.h"
#import "ADVASTResourceLoader.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

static const NSString* kPlaybackFinishedUserInfoErrorKey=@"error";

typedef enum {
    VASTFirstQuartile,
    VASTSecondQuartile,
    VASTThirdQuartile,
    VASTFourtQuartile,
} CurrentVASTQuartile;

@interface ADVASTViewController() <ADVASTNonVideoViewDelegate,UIAlertViewDelegate,ADVASTVideoDownloadManagerDelegate>
{
    NSURL *mediaFileURL;
    NSArray *clickTracking;
    NSArray *vastErrors;
    NSArray *impressions;
    NSTimer *playbackTimer;
    NSTimer *videoLoadTimeoutTimer;
    NSTimeInterval movieDuration;
    CMTime durationTime;
    CMTime currentT;
    NSTimeInterval playedSeconds;
    
    float currentPlayedPercentage;
    BOOL isPlaying;
    BOOL isViewOnScreen;
    BOOL hasPlayerStarted;
    BOOL isLoadCalled;
    BOOL vastReady;
    BOOL statusBarHidden;
    BOOL didSkipped; // 是否已经跳过
    BOOL willBackGround; // 是否切入到后台
    CurrentVASTQuartile currentQuartile;
    UIActivityIndicatorView *loadingIndicator;
    
    AdCompReachability *reachabilityForVAST;
    
    int skipTime; // 多少秒后可跳过视频
    
    float scale;
    ADVASTMediaFile *currentMediaFile;
    ADVASTModel *adModel;
    BOOL videoIsFinished; // 记录播放的视频是否播放完成/失败
    CGSize currentVideoSize;
    NSMutableArray *nonVideoViewArr;
    BOOL isPaused;
    
    BOOL isBufferEmpty; // 是否缓存为空
    BOOL isNoWifiAndNoBuffer; // 非wifi并且没有缓存
    
    UIButton *timeButton;
}

@property(nonatomic, strong) AVPlayerItem *playerItem;
@property(nonatomic, strong) AVPlayerLayer *playerLayer;
@property(nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) ADVASTResourceLoader *loader;

@property(nonatomic, strong) ADVASTEventProcessor *eventProcessor;
@property(nonatomic, strong) NSMutableArray *videoHangTest;
@property(nonatomic, assign) BOOL networkCurrentlyReachable;
@property(nonatomic, assign) float scale;
@property(nonatomic, strong) ADVASTMediaFile *currentMediaFile;
@property(nonatomic, strong) ADVASTModel *adModel;
@property(nonatomic, strong) ADVASTVideoDownloadManager *manager;

@end

@implementation ADVASTViewController
@synthesize leftGap;
@synthesize topGap;
@synthesize orientation;
@synthesize scale;
@synthesize currentMediaFile;
@synthesize adModel;
@synthesize enableAutoClose;

#pragma mark - Init & dealloc
- (id)init
{
    return [self initWithDelegate:nil];
}

// designated initializer
- (id)initWithDelegate:(id<ADVASTViewControllerDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
        isPaused = NO;
        currentQuartile=VASTFirstQuartile;
        self.videoHangTest=[NSMutableArray arrayWithCapacity:20];
        [self setupReachability];
        
        self.manager = [[ADVASTVideoDownloadManager alloc] init];
        self.manager.delegate = self;
        _isShowAlertView = NO; // 默认为NO
        self.player = [[AVPlayer alloc] init];
        self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        self.view.backgroundColor = [UIColor blackColor];
        [self.view.layer addSublayer:self.playerLayer];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(becomeActive:)
                                                     name: UIApplicationDidBecomeActiveNotification
                                                   object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(resignActive:)
                                                     name: UIApplicationWillResignActiveNotification
                                                   object: nil];
    }
    return self;
}

- (void)dealloc
{
    [reachabilityForVAST stopNotifier];
    [self removeObservers];
    
    self.loader = nil;
    _eventProcessor = nil;
    _videoHangTest = nil;
    currentMediaFile = nil;
    adModel = nil;
    _manager = nil;
    AdCompAdLogDebug(@"AdVastViewController dealloc");
}

#pragma mark - Load methods

- (void)loadVideoWithURL:(NSURL *)url
{
    [self loadVideoUsingSource:url];
}

- (void)loadVideoWithData:(NSData *)xmlContent
{
    [self loadVideoUsingSource:xmlContent];
}

- (void)loadVideoUsingSource:(id)source
{
    if ([source isKindOfClass:[NSURL class]])
    {
        AdCompAdLogDebug(@"VAST - View Controller : Starting loadVideoWithURL");
    } else {
        AdCompAdLogDebug(@"VAST - View Controller : Starting loadVideoWithData");
    }
    
    if (isLoadCalled) {
        AdCompAdLogDebug(@"VAST - View Controller : Ignoring loadVideo because a load is in progress.");
        return;
    }
    isLoadCalled = YES;
    
    void (^parserCompletionBlock)(ADVASTModel *vastModel, ADVASTError vastError) = ^(ADVASTModel *vastModel, ADVASTError vastError) {
        AdCompAdLogDebug(@"VAST - View Controller : back from block in loadVideoFromData.");
        
        if (!vastModel) {
            AdCompAdLogDebug(@"VAST - View Controller : parser error");
            if ([self.delegate respondsToSelector:@selector(vastError:error:)]) {  // The VAST document was not readable, so no Error urls exist, thus none are sent.
                [self.delegate vastError:self error:vastError];
            }
            return;
        }
        
        [vastModel getInLineAvailableAd];
        self.adModel = vastModel;
        
        NSString *statusString = [self checkNetworkType];
        if ([statusString isEqualToString:@"WiFi"]) {
            
            NSMutableArray *array = [[NSMutableArray alloc] init];
            for (NSDictionary *dict in self.adModel.adsArray) {
                if ([[dict objectForKey:@"sequence"] intValue] != 999) {
                    NSURL *url = [ADVASTMediaFilePicker pick:[dict objectForKey:@"mediaFiles"]].url;
                    [array addObject:url];
                }
            }
            
            // wifi情况下添加缓存任务
            if (array.count == 0) {
                NSDictionary *dict = [self.adModel getCurrentAd];
                NSURL *url = [ADVASTMediaFilePicker pick:[dict objectForKey:@"mediaFiles"]].url;
                [self.manager addNewTaskWithUrl:url];
            }else {
                [self.manager addNewTaskWithArray:array];

            }
            return;
        }
        
        if (![self setVideoInfoWithModel]) return;
            
        // VAST document parsing OK, player ready to attempt play, so send vastReady
        AdCompAdLogDebug(@"VAST - View Controller : Sending vastReady: callback");
        [self.delegate vastReady:self];
    };
    
    ADVAST2Parser *parser = [[ADVAST2Parser alloc] init];
    if ([source isKindOfClass:[NSURL class]]) {
        if (!self.networkCurrentlyReachable) {
            AdCompAdLogDebug(@"VAST - View Controller : No network available - VASTViewcontroller will not be presented");
            if ([self.delegate respondsToSelector:@selector(vastError:error:)]) {
                [self.delegate vastError:self error:VASTErrorNoInternetConnection];  // There is network so no requests can be sent, we don't queue errors, so no external Error event is sent.
            }
            return;
        }
        [parser parseWithUrl:(NSURL *)source completion:parserCompletionBlock];     // Load the and parse the VAST document at the supplied URL
    } else {
        [parser parseWithData:(NSData *)source completion:parserCompletionBlock];   // Parse a VAST document in supplied data
    }
}

#pragma mark - View lifecycle
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    isViewOnScreen=YES;
    if (hasPlayerStarted) {
        // resuming from background or phone call, so resume if was playing, stay paused if manually paused
        [self handleResumeState];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    statusBarHidden = [[UIApplication sharedApplication] isStatusBarHidden];
    if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
        [[UIApplication sharedApplication] setStatusBarHidden:statusBarHidden withAnimation:UIStatusBarAnimationNone];
    }
}

#pragma mark - 调整方向方法
// force to always play in Landscape
- (BOOL)shouldAutorotate
{
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    if (self.orientation == UIInterfaceOrientationUnknown) {
        self.orientation = [[UIApplication sharedApplication] statusBarOrientation];
    }
    return self.orientation;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}

- (BOOL)prefersStatusBarHidden{
    return YES;//隐藏状态栏
}

#pragma mark - 加载菊花添加&移除
- (void)addActivityView {
    loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0") ) {
        loadingIndicator.frame = CGRectMake( (self.view.frame.size.width/2)-25.0, (self.view.frame.size.height/2)-25.0,50,50);
    }
    else {
        loadingIndicator.frame = CGRectMake( (self.view.frame.size.height/2)-25.0, (self.view.frame.size.width/2)-25.0,50,50);
    }
    [loadingIndicator startAnimating];
    [self.view addSubview:loadingIndicator];
}

- (void)removeActivityView {
    if (loadingIndicator) {
        [loadingIndicator stopAnimating];
        [loadingIndicator removeFromSuperview];
        loadingIndicator = nil;
    }
    [self stopVideoLoadTimeoutTimer];
}

#pragma mark - 图标&伴随&读秒Label(添加&移除)
- (void)updateTimeLabelText {
    CMTime currentTime = [self.playerItem currentTime];
    playedSeconds = CMTimeGetSeconds(currentTime);
    if (skipTime != -1) {
        int time = (skipTime- (int)playedSeconds);
        if (time <= 0) {
            [timeButton setTitle:@"跳过" forState:UIControlStateNormal];
            timeButton.enabled = YES;
        }else
            [timeButton setTitle:[NSString stringWithFormat:@"%dS后跳过",time] forState:UIControlStateNormal];
    }else {
        int time = (int)(movieDuration-playedSeconds);
        if (time <= 0) {
            [timeButton setTitle:@"播放完成" forState:UIControlStateNormal];
        }else {
            [timeButton setTitle:[NSString stringWithFormat:@"%dS后结束",time] forState:UIControlStateNormal];
        }
    }
}

- (void)createTimeLabel {
    // 避免从后台切入回程序是重复更给button值
    if (nil != timeButton) {
        return;
    }
    
    timeButton = [[UIButton alloc] init];
    CGSize size = [UIScreen mainScreen].bounds.size;
    CGFloat y = 10;
    if (![UIApplication sharedApplication].statusBarHidden) {
        y += 20;
    }
    timeButton.frame = CGRectMake( size.width - 100, y, 90, 30);
    timeButton.layer.cornerRadius = 15;
    [timeButton setBackgroundColor:[AdCompExtTool hexStringToColor:@"#44404040"]];
    [timeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [timeButton addTarget:self
                   action:@selector(skipVideo) forControlEvents:UIControlEventTouchUpInside];
    timeButton.enabled = NO;
    [self.view addSubview:timeButton];
    
    if (skipTime != -1) {
        [timeButton setTitle:[NSString stringWithFormat:@"%d后跳过",skipTime - (int)playedSeconds] forState:UIControlStateNormal];
    }else {
        timeButton.enabled = NO;
        [timeButton setTitle:[NSString stringWithFormat:@"%dS后结束",(int)movieDuration] forState:UIControlStateNormal];
    }
    
    if (timeButton.hidden) {
        timeButton.hidden = NO;
    }
}

- (void)createIconAndCompanion {
    //清理上个video的伴随和icon
    if (nonVideoViewArr && nonVideoViewArr.count > 0) {
        for (ADVASTNonVideoView *view in nonVideoViewArr) {
            view.delegate = nil;
            [view removeFromSuperview];
        }
        [nonVideoViewArr removeAllObjects];
    }
    
    if (nil == nonVideoViewArr) {
        nonVideoViewArr = [[NSMutableArray alloc] init];
    }
    
    CGSize size = [UIScreen mainScreen].bounds.size;
    float originX = (size.width - currentVideoSize.width) / 2;
    float originY = (size.height - currentVideoSize.height) / 2;
    
    CGFloat iconYBegin = 0;
    CGFloat iconYEnd = 0;
    
    NSDictionary *adDict = [self.adModel getCurrentAd];
    NSDictionary *iconDict = [adDict objectForKey:@"icon"];
    if (iconDict) {
        ADVASTNonVideoView *icon = [[ADVASTNonVideoView alloc] initWithInfoDict:iconDict isIcon:YES scale:self.scale size:currentVideoSize];
        [icon createView];
        icon.delegate = self;
        CGRect rect = icon.frame;
        iconYBegin = rect.origin.y;
        iconYEnd = iconYBegin + rect.size.height;
        rect.origin.x += originX;
        rect.origin.y += originY;
        icon.frame = rect;
        [self.view addSubview:icon];
        [icon reportImpressionTracking];
        [nonVideoViewArr addObject:icon];
    }
    
    // 创建伴随
    id object = [adDict objectForKey:@"companion"];
    if (object) {
        if ([object isKindOfClass:[NSArray class]] && ((NSArray*)object).count > 0) {
            object = [object firstObject];
        }
        ADVASTNonVideoView *companion = [[ADVASTNonVideoView alloc] initWithInfoDict:object isIcon:NO scale:self.scale size:currentVideoSize];
        [companion createView];
        CGRect rect = companion.frame;
        rect.origin.x += originX;
        
        if (companion.companionIsBanner) {
            if (rect.origin.y >= iconYBegin && rect.origin.y <= iconYEnd) {
                rect.origin.y = 0;
            }
        }
        
        rect.origin.y += originY;
        
        companion.frame = rect;
        companion.delegate = self;
        [self.view addSubview:companion];
        [companion reportImpressionTracking];
        [nonVideoViewArr addObject:companion];
    }
}

#pragma mark - 计时器开始和停止以及响应方法
// playbackTimer - keeps track of currentPlayedPercentage
- (void)startPlaybackTimer
{
//    @synchronized (self) {
    [self stopPlaybackTimer];
    AdCompAdLogDebug(@"VAST - View Controller start playback timer");
    playbackTimer = [NSTimer scheduledTimerWithTimeInterval:kPlayTimeCounterInterval
                                                     target:self
                                                   selector:@selector(updatePlayedSeconds)
                                                   userInfo:nil
                                                    repeats:YES];
    
}

- (void)stopPlaybackTimer
{
    AdCompAdLogDebug(@"VAST - View Controller stop playback timer");
    [playbackTimer invalidate];
    playbackTimer = nil;
}

- (void)updatePlayedSeconds {
    @try {
        CMTime currentTime = [self.playerItem currentTime];
        playedSeconds = CMTimeGetSeconds(currentTime);
    }
    @catch (NSException *e) {
        AdCompAdLogDebug(@"VAST - View Controller : Exception - updatePlayedSeconds: %@", e);
        // The hang test below will fire if playedSeconds doesn't update (including a NaN value), so no need for further action here.
    }

    [self updateTimeLabelText];
    
    [self.videoHangTest addObject:@((int) (playedSeconds * 10.0))];     // add new number to end of hang test buffer
    
    if ([self.videoHangTest count]>20) {  // only check for hang if we have at least 20 elements or about 5 seconds of played video, to prevent false positives
        if ([[self.videoHangTest firstObject] integerValue]==[[self.videoHangTest lastObject] integerValue]) {
            [self failedPlayToEnd:nil];
            if (vastErrors) {
                AdCompAdLogDebug(@"VAST - View Controller : Sending Error requests");
                [self.eventProcessor sendVASTUrlsWithId:vastErrors];
            }
            return;
        }
        [self.videoHangTest removeObjectAtIndex:0];   // remove oldest number from start of hang test buffer
    }
    
   	currentPlayedPercentage = (float)100.0*(playedSeconds/movieDuration);
    
    switch (currentQuartile) {
            
        case VASTFirstQuartile:
            if (currentPlayedPercentage>25.0) {
                [self.eventProcessor trackEvent:VASTEventTrackFirstQuartile];
                currentQuartile=VASTSecondQuartile;
            }
            break;
            
        case VASTSecondQuartile:
            if (currentPlayedPercentage>50.0) {
                [self.eventProcessor trackEvent:VASTEventTrackMidpoint];
                currentQuartile=VASTThirdQuartile;
            }
            break;
            
        case VASTThirdQuartile:
            if (currentPlayedPercentage>75.0) {
                [self.eventProcessor trackEvent:VASTEventTrackThirdQuartile];
                currentQuartile=VASTFourtQuartile;
            }
            break;
            
        default:
            break;
    }
}

// Reports error if vast video document times out while loading
- (void)startVideoLoadTimeoutTimer
{
    AdCompAdLogDebug(@"VAST - View Controller : Start Video Load Timer");
    videoLoadTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:[ADVASTSettings vastVideoLoadTimeout]
                                                             target:self
                                                           selector:@selector(videoLoadTimerFired)
                                                           userInfo:nil
                                                            repeats:NO];
}

- (void)stopVideoLoadTimeoutTimer
{
    [videoLoadTimeoutTimer invalidate];
    videoLoadTimeoutTimer = nil;
    AdCompAdLogDebug(@"VAST - View Controller : Stop Video Load Timer");
}

- (void)videoLoadTimerFired
{
    if (vastErrors) {
        AdCompAdLogDebug(@"VAST - View Controller : Sending Error requests");
        [self.eventProcessor sendVASTUrlsWithId:vastErrors];
    }
    [self failedPlayToEnd:nil];
}

- (void)killTimers
{
    [self stopPlaybackTimer];
    [self stopVideoLoadTimeoutTimer];
}

#pragma mark - 视频循环
- (void)rollOver {
    self.adModel.currentIndex ++;
    // 所有视频都处理完成
    if  (self.adModel.currentIndex >= self.adModel.adsArray.count) {
        if (videoIsFinished) {
            //成功
            if ([self.delegate respondsToSelector:@selector(vastVideoAllPlayEnd:)]) {
                [self.delegate vastVideoAllPlayEnd:self];
                [self addCloseAction];
            }
        }else {
            //失败
            if ([self.delegate respondsToSelector:@selector(vastError:error:)]) {
                // 视频都失败移除加载菊花
                [self removeActivityView];
                [self.delegate vastError:self error:VASTErrorNone];
                [self addCloseAction];
            }
        }
        return;
    }
    
    if (videoIsFinished) {
        NSDictionary *dict = [self.adModel getCurrentAd];
        if ([[dict objectForKey:@"sequence"] intValue] != 999) {
            if ([self setVideoInfoWithModel]) {
                [self playIsRollOver:YES];
            }else {
                [self rollOver];
            }
            return;
        }
        // 通知成功
        if ([self.delegate respondsToSelector:@selector(vastVideoAllPlayEnd:)]) {
            [self.delegate vastVideoAllPlayEnd:self];
            [self addCloseAction];
        }
    }else {
        NSDictionary *dict = [self.adModel getCurrentAd];
        if ([[dict objectForKey:@"sequence"] intValue] == 999) {
            if ([self setVideoInfoWithModel]) {
                [self playIsRollOver:YES];
                return;
            }
        }
        
        [self rollOver];
    }
}

#pragma mark - 视频播放前置操作
// 初始化即将展示视频广告的相关信息,成功返回Yes
- (BOOL)setVideoInfoWithModel {
    NSDictionary *currentAdDict = [self.adModel getCurrentAd];
    self.eventProcessor = [[ADVASTEventProcessor alloc] initWithTrackingEvents:[currentAdDict objectForKey:@"trackings"] withDelegate:_delegate];
    impressions = [currentAdDict objectForKey:@"impressions"];
    vastErrors = [currentAdDict objectForKey:@"errors"];
    self.clickThrough = [[currentAdDict objectForKey:@"clickThroughs"] url];
    clickTracking = [currentAdDict objectForKey:@"clickTrackings"];
    currentMediaFile = [ADVASTMediaFilePicker pick:[currentAdDict objectForKey:@"mediaFiles"]];
    mediaFileURL = currentMediaFile.url;
    skipTime = [AdCompExtTool dateStringChangeToSeconds:[currentAdDict objectForKey:@"skipoffset"]];
    videoIsFinished = NO;
    
    if(!mediaFileURL) {
        if (vastErrors) {
            AdCompAdLogDebug(@"VAST - View Controller : Sending Error requests");
            [self.eventProcessor sendVASTUrlsWithId:vastErrors];
        }
        return NO;
    }
    vastReady = YES;
    return YES;
}

// 播放前item等设置
- (void)prepareToLoadVideoData {
    playedSeconds = 0.0;
    currentPlayedPercentage = 0.0;
    movieDuration = 0;
    durationTime = kCMTimeZero;
    didSkipped = NO;

    [self addActivityView];
    [self startVideoLoadTimeoutTimer];
    if (self.playerItem) {
        [self removeObserver];
    }
    
    // 设置item
    if (isNoWifiAndNoBuffer) {
        self.loader = [[ADVASTResourceLoader alloc] init];
        self.loader.delegate = self;
        
        NSURLComponents *components = [[NSURLComponents alloc] initWithURL:mediaFileURL resolvingAgainstBaseURL:NO];
        components.scheme = @"streaming";
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[components URL] options:nil];
        [asset.resourceLoader  setDelegate:self.loader queue:dispatch_get_main_queue()];
        self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
    }else {
        self.playerItem = [AVPlayerItem playerItemWithURL:mediaFileURL];
    }
    
    [self addObserver]; // 添加观察者
    CGSize size = [UIScreen mainScreen].bounds.size;
    CGSize availableSize = CGSizeMake(size.width-2*leftGap, size.height-2*topGap);
    
    CGSize videoSize = CGSizeZero;
    if (currentMediaFile.width != 0 && currentMediaFile.height != 0) {
        videoSize = CGSizeMake(currentMediaFile.width, currentMediaFile.height);
    }else {
        NSArray *array = self.playerItem.asset.tracks;
        for (AVAssetTrack *track in  array) {
            if ([track.mediaType isEqualToString:AVMediaTypeVideo]) {
                videoSize = track.naturalSize;
            }
        }
    }
    
    CGSize actualSize = [self changeSize:videoSize withSize:availableSize];
    currentVideoSize = actualSize;
    self.playerLayer.frame = CGRectMake((size.width-actualSize.width)/2.0, (size.height-actualSize.height)/2, actualSize.width, actualSize.height);
    [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
}

- (void)setMovieDuration:(CMTime)duration
{
    movieDuration = CMTimeGetSeconds(duration);
    durationTime = duration;
    
    AdCompAdLogDebug(@"VAST - View Controller : playback duration is %f", movieDuration);
    
    if (movieDuration < 0.5 || isnan(movieDuration)) {
        // movie too short - ignore it
        [self stopVideoLoadTimeoutTimer];  // don't time out in this case
        AdCompAdLogDebug(@"VAST - View Controller : Movie too short - will dismiss player");
        [self failedPlayToEnd:nil];
        if (vastErrors) {
            AdCompAdLogDebug(@"VAST - View Controller : Sending Error requests");
            [self.eventProcessor sendVASTUrlsWithId:vastErrors];
        }
    }
}

// 视频开始播放前相关操作
- (void)doSameingBeforePlayVideo {
    [self removeActivityView];
    [self createIconAndCompanion];
    [self showAndPlayVideo];
    [self createTimeLabel];
    [self startPlaybackTimer];
    isPlaying = YES;
}

#pragma mark - 播放器操作方法

- (void)play {
    NSString *cacheFilePath = [ADVASTFileHandle cacheFileExistsWithURL:mediaFileURL];
    
    if (nil != cacheFilePath) {
        if (![cacheFilePath hasSuffix:@".mp4"]) {
            cacheFilePath = [NSString stringWithFormat:@"%@.mp4",cacheFilePath];
        }
        mediaFileURL = [NSURL fileURLWithPath:cacheFilePath];
    }else {
        NSString *statusString = [self checkNetworkType];
        if (![statusString isEqualToString:@"WiFi"]) {
            isNoWifiAndNoBuffer = YES;
            if (self.isShowAlertView) {
                [self addAlertView];
                return;
            }
        }
    }
    
    [self playIsRollOver:NO];
    if (self.delegate && [self.delegate respondsToSelector:@selector(vastVideoPlayStatus:)]) {
        [self.delegate vastVideoPlayStatus:VASTVideoPlayStart];
    }
}

- (void)playIsRollOver:(BOOL)roll {
    @synchronized (self) {
        AdCompAdLogDebug(@"VAST - View Controller : playVideo");
        
        if (!vastReady) {
            if ([self.delegate respondsToSelector:@selector(vastError:error:)]) {
                [self.delegate vastError:self error:VASTErrorPlayerNotReady];                  // This is not a VAST player error, so no external Error event is sent.
                AdCompAdLogDebug(@"VAST - View Controller : Ignoring call to playVideo before the player has sent vastReady.");
                return;
            }
        }
        
        if (isViewOnScreen && !roll) {
            AdCompAdLogDebug(@"VAST - View Controller : Ignoring call to playVideo while playback is already in progress");
            return;
        }
        
        if (![[AdCompReachability reachabilityForInternetConnection] currentReachabilityStatus]) {
            AdCompAdLogDebug(@"VAST - View Controller : No network available - VASTViewcontroller will not be presented");
            if ([self.delegate respondsToSelector:@selector(vastError:error:)]) {
                [self.delegate vastError:self error:VASTErrorNoInternetConnection];   // There is network so no requests can be sent, we don't queue errors, so no external Error event is sent.
            }
            return;
        }
        
        // Now we are ready to launch the player and start buffering the content
        // It will throw error if the url is invalid for any reason. In this case, we don't even need to open ViewController.
        AdCompAdLogDebug(@"VAST - View Controller : initializing player");
        
        @try {
            // Create and prepare the player to confirm the video is playable (or not) as early as possible
            [self prepareToLoadVideoData];
        }
        @catch (NSException *e) {
            AdCompAdLogDebug(@"VAST - View Controller : Exception - moviePlayer.prepareToPlay: %@", e);
            [self failedPlayToEnd:nil];
            if (vastErrors) {
                AdCompAdLogDebug(@"VAST - View Controller : Sending Error requests");
                [self.eventProcessor sendVASTUrlsWithId:vastErrors];
            }
            return;
        }
    }
}

- (void)pause
{
    AdCompAdLogDebug(@"VAST - View Controller : pause");
    [self handlePauseState];
}

- (void)resume
{
    AdCompAdLogDebug(@"VAST - View Controller : resume");
    [self handleResumeState];
}

- (void)info
{
    if (clickTracking) {
        AdCompAdLogDebug(@"VAST - View Controller : Sending clickTracking requests");
        [self.eventProcessor sendVASTUrlsWithId:clickTracking];
    }
    if ([self.delegate respondsToSelector:@selector(vastOpenBrowseWithUrl:)]) {
        [self.delegate vastOpenBrowseWithUrl:self.clickThrough];
    }
}

- (void)close
{
    @synchronized (self) {
        [self removeObserver];
        [self killTimers];
        
        if (isViewOnScreen) {
            // send close any time the player has been dismissed
            [self.eventProcessor trackEvent:VASTEventTrackCloseLinear];
            AdCompAdLogDebug(@"VAST - View Controller : Dismissing VASTViewController");
        }
        
        [self dismissViewControllerAnimated:NO completion:nil];
        
        if ([self.delegate respondsToSelector:@selector(vastDidDismissFullScreen:)]) {
            [self.delegate vastDidDismissFullScreen:self];
        }
        
        self.adModel = nil;
        self.currentMediaFile = nil;
        self.loader = nil;
        nonVideoViewArr = nil;
        [timeButton removeFromSuperview];
        timeButton = nil;
        isPlaying = NO;
        isViewOnScreen = NO;
        hasPlayerStarted = NO;
        vastReady = NO;
        isLoadCalled = NO;
    }
}

- (void)skipVideo {
    [self.player pause];
//    CMTime time = [self.playerItem currentTime];
//    [self.playerItem seekToTime:CMTimeMake((durationTime.value + time.value)/durationTime.timescale, 1.0)];
    didSkipped = YES;
    AdCompAdLogDebug(@"VAST - View Controller : skip");
    [self.eventProcessor trackEvent:VASTEventTrackSkip];
    [self playbackFinished:nil];
}

- (void)handlePauseState
{
    @synchronized (self) {
        if (isPlaying) {
            AdCompAdLogDebug(@"VAST - View Controller : handle pausing player");
            isPaused = YES;
            [self.player pause];
            isPlaying = NO;
            [self.eventProcessor trackEvent:VASTEventTrackPause];
        }
        [self stopPlaybackTimer];
    }
}

- (void)handleResumeState
{
    // 如果点击跳过以后，就不再继续播放
    if (didSkipped) {
        return;
    }
    @synchronized (self) {
        if (hasPlayerStarted) {
            AdCompAdLogDebug(@"VAST - View Controller : handleResumeState, resuming player");
            isPaused = NO;
            self.playerLayer.player = self.player;
            [self.player play];
            isPlaying = YES;
            [self.eventProcessor trackEvent:VASTEventTrackResume];
            if (!videoIsFinished) {
                [self startPlaybackTimer];
            }
        } else if (self.player) {
            [self showAndPlayVideo];   // Edge case: loadState is playable but not playThroughOK and had resignedActive, so play immediately on resume
        }
    }
}

- (void)showAndPlayVideo
{
    AdCompAdLogDebug(@"VAST - View Controller : adding player to on screen view and starting play sequence");
    
    [self.player play];
    hasPlayerStarted=YES;
    
    if (impressions) {
        AdCompAdLogDebug(@"VAST - View Controller : Sending Impressions requests");
        [self.eventProcessor sendVASTUrlsWithId:impressions];
    }
    [self.eventProcessor trackEvent:VASTEventTrackStart];
}

#pragma mark - 关闭
- (void)addCloseAction {
    if (!self.enableAutoClose) {
        if (timeButton.hidden == NO) {
            timeButton.hidden = YES;
        }
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:@"关闭" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
        CGSize size = [UIScreen mainScreen].bounds.size;
        if (nil == timeButton) {
            CGFloat y = 10;
            if (![UIApplication sharedApplication].statusBarHidden) {
                y += 20;
            }
            button.frame = CGRectMake(size.width - 100, y, 90, 30);
        }else{
            button.frame = CGRectMake(0, 0, 90, 30);
            button.center = timeButton.center;
        }
        button.layer.cornerRadius = 15;
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button setBackgroundColor:[AdCompExtTool hexStringToColor:@"#44404040"]];
        [self.view addSubview:button];
    }else {
        [self close];
    }
}

#pragma mark - Other methods
- (BOOL)isPlaying
{
    return isPlaying;
}

- (CGSize)changeSize:(CGSize)pendingSize withSize:(CGSize)referenceSize {
    CGSize size;
    
    CGFloat xScale = referenceSize.width/pendingSize.width;
    CGFloat yScale = referenceSize.height/pendingSize.height;
    
    CGFloat scale = xScale<yScale?xScale:yScale;
    self.scale = scale;
    size = CGSizeMake(pendingSize.width*scale, pendingSize.height*scale);
    
    return size;
}

#pragma mark - notification and observer (add and remove)
/**
 *  添加观察者 、通知 、监听播放进度
 */
- (void)addObserver {
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil]; // 观察status属性， 一共有三种属性
    [self.playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:@"playbackBufferFull" options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    //    [self monitoringPlayback:self.playerItem]; // 监听播放
    [self addNotification];
}

- (void)removeObserver {
    [self.playerItem removeObserver:self forKeyPath:@"status"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackBufferFull"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    self.playerItem = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemPlaybackStalledNotification object:nil];
}

- (void)addNotification {
    // 播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    // 播放中断通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoPlayStalled) name:AVPlayerItemPlaybackStalledNotification object:nil];
}

- (void)removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}

#pragma mark - notifacation method
- (void)playbackFinished:(NSNotification *)notification {
    AdCompAdLogDebug(@"视频播放完成通知");
    if (videoIsFinished) return;// 处理过一次之后就不在处理
    [self.eventProcessor trackEvent:VASTEventTrackComplete];
    [self updatePlayedSeconds];
    [self stopPlaybackTimer];
    [self removeObserver];
    isPlaying = NO;
    timeButton.hidden = YES;
    [self.videoHangTest removeAllObjects];
    videoIsFinished = YES;
    [self rollOver]; //循环播放下个视频
}

- (void)videoPlayStalled {
    NSLog(@"中断-->%@",self.player.error.description);
    [ADVASTFileHandle clearCacheWithURL:mediaFileURL];
    if (!isBufferEmpty) {
        [self failedPlayToEnd:nil];
    }
}

- (void)failedPlayToEnd:(NSNotification*)notifation {
    AdCompAdLogDebug(@"视频播放失败通知");
    [self stopPlaybackTimer];
    [self removeActivityView];
    [self removeObserver];
    [self.videoHangTest removeAllObjects];
    videoIsFinished = NO;
    timeButton.hidden = YES;
    isPlaying = NO;
    [self rollOver];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    AVPlayerItem *item = (AVPlayerItem *)object;
    if (item == self.playerItem && [keyPath isEqualToString:@"status"]) {
//        AVPlayerStatus status = [[change objectForKey:@"new"] intValue]; // 获取更改后的状态
        if (item.status == AVPlayerStatusReadyToPlay) {
            CMTime duration = item.duration; // 获取视频长度
            //开始播放
            [self setMovieDuration:duration];
            if (!willBackGround){
                [self doSameingBeforePlayVideo];
            }
        } else {
            [self stopVideoLoadTimeoutTimer];  // don't time out if there was a playback error
            if (vastErrors) {
                [self.eventProcessor sendVASTUrlsWithId:vastErrors];
            }
            videoIsFinished = NO;
            [self failedPlayToEnd:nil];
        }
    }else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
        AdCompAdLogDebug(@"playbackBufferEmpty  %@ ,%@",self.player.error.domain, self.playerItem.error.domain);
        //当没有缓冲的时候可以适当等待
        isBufferEmpty = YES;
    }else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        if (self.player.rate > 0 && self.player.error == nil) {
        }else {
            if (!videoIsFinished && !isPaused) {
                isBufferEmpty = NO;
                [self.player play];
            }
        }
        AdCompAdLogDebug(@"playbackLikelyToKeepUp");
    }else if ([keyPath isEqualToString:@"playbackBufferFull"]) {
        AdCompAdLogDebug(@"playbackBufferFull");
    }else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
    }
}

- (void)resignActive:(NSNotification *)notification {
    willBackGround = YES;
    [self pause];
}

- (void)becomeActive:(NSNotification *)notification {
    [self resume];
}

#pragma mark - 流量提醒 UIAlertViewDelegate && ShowAlertMethod

// 非WIFI下观看流量提醒
- (void)addAlertView {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"流量提醒" message:@"当前处于非WIFI环境下，继续观看将会消耗流量" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    [alertView show];
}

- (void)showFaildInfomation:(NSString*)failStr {// 展示失败界面
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"失败信息" message:failStr delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) { //cancel button
        [self close];
    }else {
        // 继续观看
        [self playIsRollOver:NO];
        if (self.delegate && [self.delegate respondsToSelector:@selector(vastVideoPlayStatus:)]) {
            [self.delegate vastVideoPlayStatus:VASTVideoPlayStart];
        }
    }
}

#pragma mark - Reachability

- (NSString*)checkNetworkType {
    AdCompViewNetworkStatus netStatus = [[AdCompReachability reachabilityForInternetConnection] currentReachabilityStatus];
    
    NSString *str;
    
    switch (netStatus) {
        case AdCompViewNotReachable:
            str = @"other";
            break;
        case AdCompReachableViaWiFi:
            str = @"WiFi";
            break;
        case AdCompReachableViaWWAN:
            str = @"2G/3G";
            break;
        case kAdCompReachableVia2G:
            str = @"2G";
            break;
        case kAdCompReachableVia3G:
            str = @"3G";
            break;
        case kAdCompReachableVia4G:
            str = @"4G";
            break;
        default:
            break;
    }
    return str;
}

- (void)setupReachability
{
    reachabilityForVAST = [AdCompReachability reachabilityForInternetConnection];
    
    [reachabilityForVAST startNotifier];
    
    AdCompAdLogDebug(@"VAST - View Controller : Network is reachable %@", [self checkNetworkType]);
}

#pragma mark - ADVASTVideoDownloadManagerDelegate
- (void)cacheTaskFailedWithError:(NSError *)error {
    AdCompAdLogDebug(@"VAST - View Controller : cache failed!");
    self.adModel.currentIndex ++;
    // 所有视频都缓存失败了
    if (self.adModel.currentIndex >= self.adModel.adsArray.count) {
        if ([self.delegate respondsToSelector:@selector(vastError:error:)]) {
            [self removeActivityView];
            ADVASTError type = VASTErrorNone;
            if ([error.domain isEqualToString:@"文件过大"]) {
                type = VASTErrorVideoFileTooBig;
            }
            // 没有缓存到广告
            [self.delegate vastError:self error:type];
            self.manager = nil;
            return;
        }
    }
    
    // 如果是多个视频一组的缓存失败，则找到第一个不是组里视频位置 （多个视频一组的只有一组的情况，如果超出一组还需从新做处理）
    if (self.manager.isMoreTask) {
        for (NSDictionary *dict in self.adModel.adsArray) {
            if ([[dict objectForKey:@"sequence"] intValue] == 999) {
                self.adModel.currentIndex = [self.adModel.adsArray indexOfObject:dict];
                break;
            }
        }
    }
    
    NSDictionary *dict = [self.adModel getCurrentAd];
    NSURL *url = [ADVASTMediaFilePicker pick:[dict objectForKey:@"mediaFiles"]].url;
    [self.manager addNewTaskWithUrl:url];
    
}

- (void)cacheTaskFinished {
    // 缓存成功后设置初始信息
    [self setVideoInfoWithModel];
    // wifi情况下，缓存下载完，回调ready
    [self.delegate vastReady:self];
    self.manager = nil;
}

#pragma mark - ADVASTNonVideoViewDelegate
- (void)clickActionWithUrlString:(NSString *)urlString {
    if (self.delegate && [self.delegate respondsToSelector:@selector(responsClickActionWithUrlString:)]) {
        [self pause];
        [self.delegate responsClickActionWithUrlString:urlString];
    }
}

#pragma mark - touch methods
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint currentPoint = [touch locationInView:self.view];
    
    CGRect rect = self.playerLayer.frame;
    
    if (CGRectContainsPoint(rect, currentPoint)) {
        NSMutableDictionary *rDict = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *aDict = [[NSMutableDictionary alloc] init];

        CGFloat pointX = currentPoint.x - rect.origin.x;
        CGFloat pointY = currentPoint.y - rect.origin.y;
        [aDict setObject:[NSString stringWithFormat:@"%d", (int)pointX*scale] forKey:@"down_x"];
        [aDict setObject:[NSString stringWithFormat:@"%d", (int)pointY*scale] forKey:@"down_Y"];
        
        pointX = pointX*1000/rect.size.width;
        pointY = pointY*1000/rect.size.height;
        
        [rDict setObject:[NSString stringWithFormat:@"%d", (int)pointX] forKey:@"down_x"];
        [rDict setObject:[NSString stringWithFormat:@"%d", (int)pointY] forKey:@"down_Y"];
        
        [[AdCompExtTool sharedTool] storeObject:aDict forKey:@"{ABSOLUTE_COORD}"];
        [[AdCompExtTool sharedTool] storeObject:aDict forKey:@"{RELATIVE_COORD}"];
    }
    
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {}
- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];
    
    CGRect rect = self.playerLayer.frame;

    if (CGRectContainsPoint(rect, point)) {
        
        NSMutableDictionary *rDict = (NSMutableDictionary*)[[AdCompExtTool sharedTool] objectStoredForKey:@"{RELATIVE_COORD}"];
        NSMutableDictionary *aDict = (NSMutableDictionary*)[[AdCompExtTool sharedTool] objectStoredForKey:@"{ABSOLUTE_COORD}"];
        
        if (nil == rDict) {
            rDict = [[NSMutableDictionary alloc] init];
            [rDict setObject:@"-1" forKey:@"down_x"];
            [rDict setObject:@"-1" forKey:@"down_y"];
        }
        
        if (nil == aDict) {
            aDict = [[NSMutableDictionary alloc] init];
            [aDict setObject:@"-1" forKey:@"down_x"];
            [aDict setObject:@"-1" forKey:@"down_y"];
        }
        
        CGFloat pointX = point.x - rect.origin.x;
        CGFloat pointY = point.y - rect.origin.y;
        [aDict setObject:[NSString stringWithFormat:@"%d", (int)pointX*scale]  forKey:@"up_x"];
        [aDict setObject:[NSString stringWithFormat:@"%d", (int)pointY*scale]forKey:@"up_Y"];
        
        pointX = pointX*1000/rect.size.width;
        pointY = pointY*1000/rect.size.height;
        
        [rDict setObject:[NSString stringWithFormat:@"%d", (int)pointX] forKey:@"up_x"];
        [rDict setObject:[NSString stringWithFormat:@"%d", (int)pointY] forKey:@"up_Y"];
        
        [[AdCompExtTool sharedTool] storeObject:aDict forKey:@"{ABSOLUTE_COORD}"];
        [[AdCompExtTool sharedTool] storeObject:aDict forKey:@"{RELATIVE_COORD}"];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(responsClickActionWithUrlString:)]) {
            [self pause];
            [self.delegate responsClickActionWithUrlString:self.clickThrough.absoluteString];
            if (clickTracking) {
                [self.eventProcessor sendVASTUrlsWithId:clickTracking];
            }
        }
    }
}

@end

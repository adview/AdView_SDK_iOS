//
//  AdViewVideoViewController.m
//  KOpenAPIAdView
//
//  Created by AdView on 2018/4/26.
//

#import "AdViewVideoViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "AdViewExtTool.h"
#import "AdViewVastModel.h"
#import "AdViewVastAdModel.h"
#import "AdViewVastCreative.h"
#import "ADVGVastExtensionModel.h"
#import "AdViewVast2Parser.h"
#import "AdViewReachability.h"
#import "AdViewVastNonVideoView.h"
#import "AdViewVastVideoDownloadManager.h"
#import "AdViewVideoGeneralView.h"
#import "AdViewSkipVideoButton.h"
#import "AdViewSoundView.h"
#import "AdViewCountDownView.h"
#import "UIImage+AdviewBundle.h"
#import "ADVASTCompanionModel.h"
#import "AdViewOMAdVideoManager.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

@interface AdViewVideoViewController ()<AdViewVastNonVideoViewDelegate,UIAlertViewDelegate,AdViewVastVideoDownloadManagerDelegate,AdViewVideoGeneralViewDelegate>
{
    //✅参数为原本Nexage SDK所带有
    BOOL _isPlaying;        //✅
    BOOL _isViewOnScreen;   //✅
    BOOL _isLoadCalled;     //✅ 另外一个视频正在加载
    BOOL _vastReady;        //✅
    
    BOOL _isMute;           //是否静音
    BOOL _didSkipped;       // 是否已经跳过
    
    UIActivityIndicatorView * loadingIndicator; //视频加载菊花
    AdViewReachability * reachabilityForVAST;   //又一个多余的reachability...以后要归并所有的Reachability到一个单例
    
    float scale;
    BOOL _videoIsFinished;  // 记录当前播放的视频是否播放完成
    BOOL _nextVideoReady;   // 下条要播放的视频是准备完毕
    BOOL _allVideoFinished; // 所有资源处理完毕  没有可分配的任务 为 assignTaskAfterParseData 方法服务
    BOOL _inPlayProcess;    // 是否在播放流程中 从play/playInRoll方法开始 到 videoEndPlay/videoPlayError方法结束
    BOOL _isReplay;         // 是否为重播
    
    CGFloat kButtonWidth;
    CGFloat kButtonSpace;
    BOOL _isPaused;
    BOOL _haveSuccess;                  // 是否有成功的，如果有一个则认为成功
}

@property (nonatomic, strong) AdViewOMAdVideoManager * omsdkManager;
@property (nonatomic, strong) AdViewVideoGeneralView * contentView;                 //需要播放的对象/视频/图片/html
@property (nonatomic, strong) AdViewVastModel * vastModel;                          //总体VAST标签
@property (nonatomic, strong) AdViewVastAdModel * currentAdModel;                   //当前VAST广告
@property (nonatomic, strong) AdViewVastVideoDownloadManager *videoDonloadManager;  //视频下载管理器

@property (nonatomic, strong) UIImageView * videoThumbnailView;                     //视频缩略图
@property (nonatomic, strong) UIButton * startPlayButton;                           //开始播放按钮
@property (nonatomic, strong) AdViewSkipVideoButton * skipButton;                   //跳过按钮
@property (nonatomic, strong) AdViewSoundView       * soundView;                    //声音
@property (nonatomic, strong) AdViewCountDownView   * countDownView;                //倒计时
@property (nonatomic, strong) UIButton        * closeButton;                        //关闭
@property (nonatomic, strong) UIButton        * replayButton;                       //重播
@property (nonatomic, assign) BOOL networkCurrentlyReachable;
@property (nonatomic, assign) float scale;
@property (nonatomic, assign) BOOL isFirstHandle;                                           // 是否为第一次处理mediaFile
@property (nonatomic, strong) NSMutableArray <AdViewVastNonVideoView *>* companionViewArr;  // 伴随 View数组
@property (nonatomic, strong) NSMutableArray <AdViewVastNonVideoView *>* iconViewArr;       // ICON View数组
@property (nonatomic, strong) NSMutableArray <AdViewVastNonVideoView *>* endCardArray;      // endCard数组
@end

@implementation AdViewVideoViewController
@synthesize leftGap;
@synthesize topGap;
@synthesize scale;
@synthesize enableAutoClose;

- (instancetype)init {
    return [self initWithDelegate:nil adverType:AdViewBanner];
}

- (id)initWithDelegate:(id<AdViewVideoViewControllerDelegate>)delegate adverType:(AdvertType)adverType {
    if (self = [super init]) {
        self.delegate = delegate;
        self.adverType = adverType;

        //监听网络
        [self setupReachability];
        
        CGSize size = [UIScreen mainScreen].bounds.size;
        kButtonWidth = size.width<size.height?size.width/12:size.height/12;
        kButtonSpace = 4;
        _isReplay = NO;
        
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

- (ADVASTMediaFileType)mediaFileType {
    return _contentView.mediaFileType;
}

//OMSDK视频监测设置
- (void)omsdkManagerInitWithCreativeModel:(AdViewVastCreative *)creativeModel extensionModel:(ADVGVastExtensionModel *)extensionModel {
    if (!_omsdkManager) {
        self.omsdkManager = [[AdViewOMAdVideoManager alloc] initWithVendorKey:extensionModel.vendor
                                                       verificationParameters:extensionModel.verificationParameters
                                                  verificationScriptURLString:extensionModel.VerificationScriptURLString];
        
        [_omsdkManager setDuration:[creativeModel.duration floatValue]];
        [_omsdkManager setPosition:OMIDPositionStandalone];
        [_omsdkManager setVolume:1.0f];
        [_omsdkManager setAutoPlay:YES];
        [_omsdkManager setSkipOffset:[creativeModel.skipoffset floatValue]];
        
        [_omsdkManager setMainAdview:_contentView];
        [_omsdkManager setFriendlyObstruction:self.countDownView];
        [_omsdkManager setFriendlyObstruction:self.skipButton];
        [_omsdkManager setFriendlyObstruction:self.closeButton];
        [_omsdkManager setFriendlyObstruction:self.soundView];
    }
}

- (void)omsdkReportQuartile:(CurrentVASTQuartile)quartile {
    switch (quartile) {
        case VASTSecondQuartile:
            [_omsdkManager reportQuartileChange:AdViewOMSDKVideoQuartile_FirstQuartile];
            break;
        case VASTThirdQuartile:
            [_omsdkManager reportQuartileChange:AdViewOMSDKVideoQuartile_Midpoint];
            break;
        case VASTFourtQuartile:
            [_omsdkManager reportQuartileChange:AdViewOMSDKVideoQuartile_ThirdQuartile];
            break;
        default:
            break;
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{}
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{}
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{}
- (void)touchesEstimatedPropertiesUpdated:(NSSet<UITouch *> *)touches{}

- (void)dealloc {
    [_omsdkManager finishMeasurement];
    self.omsdkManager = nil;

    [reachabilityForVAST stopNotifier];
    [self removeObservers];
    
    self.vastModel = nil;
    self.videoDonloadManager = nil;
    self.currentAdModel = nil;
    
    self.countDownView = nil;
    self.closeButton = nil;
    self.skipButton = nil;
    self.soundView = nil;
    self.contentView = nil;
    
    AdViewLogDebug(@"%s",__FUNCTION__);
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _isViewOnScreen = YES;
}

//现实缩略图
- (void)showvideoThumbnailView {
    AdViewVastCreative * creativeModel = [self.currentAdModel.creativeArray objectAtIndex:self.currentAdModel.currentIndex];
    UIImage * preViewImage = [UIImage thumbnailImageForVideo:creativeModel.mediaFile.url atTime:0];
    self.videoThumbnailView.image = preViewImage;
    self.startPlayButton.hidden = NO;
}

#pragma mark - Load methods
- (void)loadVideoWithURL:(NSURL *)url {
    [self loadVideoUsingSource:url];
}

- (void)loadVideoWithData:(NSData *)xmlContent {
    [self loadVideoUsingSource:xmlContent];
}

//从URL或者Data加载视频
- (void)loadVideoUsingSource:(id)source {
    if (_isLoadCalled) {
        AdViewLogDebug(@"VAST - View Controller : Ignoring loadVideo because a load is in progress.");
        return;
    }
    _isLoadCalled = YES;
    _isFirstHandle = YES;
    _allVideoFinished = NO;
    
    AdViewVast2Parser * parser = [[AdViewVast2Parser alloc] init];   //VAST解析器
    if ([source isKindOfClass:[NSURL class]]) {
        //如果是URL加载 判断是否连接网络
        if (!self.networkCurrentlyReachable) {
            AdViewLogDebug(@"VAST - View Controller : No network available - VASTViewcontroller will not be presented");
            if ([self.delegate respondsToSelector:@selector(vastError:error:)]) {
                [self.delegate vastError:self error:VASTErrorNoInternetConnection];
            }
            return;
        }
        //通过URL加载并解析VAST文档.多线程异步执行.block返回主线程
        [parser parseWithUrl:(NSURL *)source completion:[self parserCompletionBlock]];
    } else {
        //⚠️ 第一次 - 判断外层是否有wrapper,有则循环请求,无则直接开始第二步解析
        //通过data解析VAST文档,⚠️ 目前只走这里,多线程异步.block返回主线程
        [parser parseWithData:(NSData *)source completion:[self parserCompletionBlock]];
    }
}

//解析完毕
- (void (^)(AdViewVastModel *vastModel, AdViewVastError vastError))parserCompletionBlock
{
    return [^(AdViewVastModel *vastModel, AdViewVastError vastError) {
        AdViewLogDebug(@"VAST - View Controller : back from block in loadVideoFromData.");
        if (!vastModel) {
            AdViewLogDebug(@"VAST - View Controller : parser error");
            if ([self.delegate respondsToSelector:@selector(vastError:error:)]) {
                [self.delegate vastError:self error:vastError];
            }
            return;
        }
        
        //⚠️ 第二次遍历解析-解析广告
        self.vastModel = [vastModel getInLineAvailableAd];
        self.currentAdModel = [self.vastModel getCurrentAd];

        if ([self checkNetworkType] != AdViewReachableViaWiFi && self.allowAlertView) {
            [self addAlertView];
        } else {
            [self assignTaskAfterParseData];
        }
    } copy];
}

#pragma mark - 视频播放前置操作
// 分配任务，wifi情况下下载视频，非wifi情况准备直接播放 并且返回vastReady
- (void)assignTaskAfterParseData {
    if (self.vastModel.currentIndex >= self.vastModel.adsArray.count) {
        _allVideoFinished = YES;
        [self notifationTheResultForAllVideoPlayEnded];
        return;
    }
    
    _nextVideoReady = NO;
    if ([self checkNetworkType] == AdViewReachableViaWiFi)
    {
        AdViewVastMediaFile *mediaFile = [self.vastModel getCurrentMediaFile];
        if (mediaFile.fileType == ADVASTMediaFileType_Image || mediaFile.fileType == ADVASTMediaFileType_Video) {
            [self.videoDonloadManager addNewTastWithMediaFile:mediaFile];
        }else {
            [self setVideoInfoWithModel];
        }
    } else {
        [self setVideoInfoWithModel];
    }
}

// 初始化即将展示视频广告的相关信息,成功返回Yes
- (BOOL)setVideoInfoWithModel {
    // 媒体文件ok的情况下回调ready
    _vastReady = YES;
    _nextVideoReady = YES;
    
    // VAST document parsing OK, player ready to attempt play, so send vastReady
    AdViewLogDebug(@"VAST - View Controller : Sending vastReady: callback");
    if (_isFirstHandle && self.delegate && [self.delegate respondsToSelector:@selector(vastReady:)]) {
        _isFirstHandle = NO;
        [self.delegate vastReady:self];
    }
    return YES;
}

- (void)notifationTheResultForAllVideoPlayEnded {
    if (!self->_inPlayProcess && self->_allVideoFinished) {
        [self addCloseButton];
        if (!self.endCardArray.count) {
            [self addReplayButton];
        }
        if (self->_haveSuccess) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(vastVideoAllPlayEnd:)]) {
                [self.delegate vastVideoAllPlayEnd:self];
            }
        } else {
            if (self.delegate && [self.delegate respondsToSelector:@selector(vastError:error:)]) {
                [self.delegate vastError:self error:VASTErrorPlayerFailed];
            }
        }
    }
}

#pragma mark - 播放相关操作
- (void)play {
    if (!_vastReady) {
        if ([self.delegate respondsToSelector:@selector(vastError:error:)]) {
            [self.delegate vastError:self error:VASTErrorPlayerNotReady];                  // This is not a VAST player error, so no external Error event is sent.
            AdViewLogDebug(@"VAST - View Controller : Ignoring call to playVideo before the player has sent vastReady.");
            return;
        }
    }
    
    if (![[AdViewReachability reachabilityForInternetConnection] currentReachabilityStatus]) {
        AdViewLogDebug(@"VAST - View Controller : No network available - VASTViewcontroller will not be presented");
        if ([self.delegate respondsToSelector:@selector(vastError:error:)]) {
            [self.delegate vastError:self error:VASTErrorNoInternetConnection];   // There is network so no requests can be sent, we don't queue errors, so no external Error event is sent.
        }
        return;
    }
    
    AdViewExtTool *tool = [AdViewExtTool sharedTool];
    if (UIInterfaceOrientationIsPortrait(self.orientation)) {
        [tool storeObject:@"2" forKey:@"__SCENE__"];
    } else if(UIInterfaceOrientationIsLandscape(self.orientation)) {
        [tool storeObject:@"4" forKey:@"__SCENE__"];
    } else {
        [tool storeObject:@"0" forKey:@"__SCENE__"];
    }
    [tool storeObject:@"1" forKey:@"__BEHAVIOR__"];
    [tool storeObject:@"1" forKey:@"__TYPE__"];
    
    _inPlayProcess = YES;
    self.startPlayButton.hidden = YES;

    [self addActivityView];
    
    //加载视频
    AdViewVastCreative * creativeModel = [self.currentAdModel.creativeArray objectAtIndex:self.currentAdModel.currentIndex];
    [self.contentView loadGeneralViewWithFileModel:creativeModel delegate:self];
    
    //加载omsdk监测
    NSArray * extensionFilteredArray = [self.currentAdModel.extesionArray filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(ADVGVastExtensionModel * object, NSDictionary *bindings) {
        if ([object.typeString isEqualToString:@"AdVerifications"]) {
            return YES;
        }
        return NO;
    }]];
    ADVGVastExtensionModel * extensionModel = [extensionFilteredArray firstObject];
    [self omsdkManagerInitWithCreativeModel:creativeModel extensionModel:extensionModel];
    
    if (!self.contentView.superview) {
        [self.view addSubview:self.contentView];
    }
    
    [self.vastModel adjustCurrentIndex];
    [self assignTaskAfterParseData];
}

- (void)waitUserAllowPlay {
    if (self.contentView.mediaFileType == ADVASTMediaFileType_Video && self.adverType == AdViewRewardVideo) {
        //如果是普通VAST,粘贴缩略图,现实点击播放
        [self showvideoThumbnailView];
    } else {
        //其他类型直接播放
        [self play];
    }
}

#pragma mark - 播放下一条
- (void)playInRoll {
    if (_allVideoFinished)
        return;
    
    if (![[AdViewReachability reachabilityForInternetConnection] currentReachabilityStatus]) {
        AdViewLogDebug(@"VAST - View Controller : No network available - VASTViewcontroller will not be presented");
        if ([self.delegate respondsToSelector:@selector(vastError:error:)]) {
            //没网,不会发送vast错误
            [self.delegate vastError:self error:VASTErrorNoInternetConnection];
        }
        return;
    }
    
    if (_isReplay) {
        // 宏替换存储数据 1、3代表?
        [[AdViewExtTool sharedTool] storeObject:@"3" forKey:@"__TYPE__"];
    } else {
        [[AdViewExtTool sharedTool] storeObject:@"1" forKey:@"__TYPE__"];
    }
    
    _inPlayProcess = YES;
    self.currentAdModel = [self.vastModel getCurrentAd];
    self.contentView.cancelCountdown = [self.vastModel isLastCreative];

    AdViewVastCreative *creativeModel = [self.currentAdModel.creativeArray objectAtIndex:self.currentAdModel.currentIndex];
    [self.contentView replaceFileModel:creativeModel];
    
    [self omsdkManagerInitWithCreativeModel:creativeModel extensionModel:self.currentAdModel.extesionArray.firstObject];

    [self.vastModel adjustCurrentIndex];
    [self assignTaskAfterParseData];
}

- (void)pause {
    _isPaused = YES;
    _isPlaying = NO;
    if (!_videoIsFinished) {
        [self.contentView videoPause];
        self.startPlayButton.hidden = NO;
    }
    AdViewLogDebug(@"VAST - View Controller : pause");
}

- (void)resume {
    if (_isPaused && !_videoIsFinished) {
        [self.contentView videoResume];
        self.startPlayButton.hidden = YES;
    }
    _isPaused = NO;
    [[AdViewExtTool sharedTool] storeObject:@2 forKey:@"__TYPE__"];
    AdViewLogDebug(@"VAST - View Controller : resume");
}

//- (void)info
//{
//    if (clickTracking) {
//        [self.eventProcessor sendVASTUrlsWithId:clickTracking];
//    }
//    if ([self.delegate respondsToSelector:@selector(vastOpenBrowseWithUrl:)]) {
//        [self.delegate vastOpenBrowseWithUrl:self.clickThrough];
//    }
//}

- (BOOL)isPlaying {
    return _isPlaying;
}

//button事件
- (void)skipVideo {
    _didSkipped = YES;
    AdViewLogDebug(@"VAST - View Controller : skip");
    [self.contentView skipVideo];
}

- (void)close {
    @synchronized (self) {
        [_omsdkManager finishMeasurement];
        self.omsdkManager = nil;
        
        [self removeObservers];
        [self.contentView closeCreative];
        [self.contentView stopLoading];
        [self.contentView stopVideo];
        
        [self dismissViewControllerAnimated:NO completion:^{
            if ([self.delegate respondsToSelector:@selector(vastDidDismissFullScreen:)]) {
                [self.delegate vastDidDismissFullScreen:self];
            }
        }];

        self.vastModel = nil;
        self.iconViewArr = nil;
        self.companionViewArr = nil;
        
        _isPlaying = NO;
        _isViewOnScreen = NO;
        _vastReady = NO;
        _isLoadCalled = NO;
    }
}

- (void)replayButtonClick:(UIButton *)sender {
    _isReplay = YES;
    _allVideoFinished = NO;
    [self addActivityView];
    [self.vastModel resetCurrentIndex];
    [self playInRoll];
}

#pragma mrak - helpper method
- (CGSize)changeSize:(CGSize)pendingSize withSize:(CGSize)referenceSize {
    CGSize size;
    
    CGFloat xScale = referenceSize.width/pendingSize.width;
    CGFloat yScale = referenceSize.height/pendingSize.height;
    
    CGFloat scale = xScale<yScale?xScale:yScale;
    self.scale = scale;
    size = CGSizeMake(pendingSize.width*scale, pendingSize.height*scale);
    
    return size;
}

#pragma mark - 关闭按钮 & 重播按钮 method
- (void)addCloseButton {
    [self.view addSubview:self.closeButton];
}

- (void)addReplayButton {
    [self.view addSubview:self.replayButton];
}

#pragma mark - timeButton method
- (void)addSkipButton {
    [self.view addSubview:self.skipButton];
}

- (void)removeSkipButton {
    if (_skipButton) {
        [self.skipButton removeFromSuperview];
        self.skipButton = nil;
    }
}

//添加结束背景
- (void)creatEndCard {
    [self creatCompationViewsInArray:&self->_endCardArray];
}

#pragma mark - icon & companion 伴随
- (void)creatCompationViewsInArray:(NSMutableArray * __strong*)compationViewsArray {
    if (self.contentView.mediaFileType != ADVASTMediaFileType_Video) return;
    
    //清理上个video的伴随
    for (AdViewVastNonVideoView *view in *compationViewsArray) {
        view.delegate = nil;
        [view removeFromSuperview];
    }
    [*compationViewsArray removeAllObjects];
    
    if (nil == *compationViewsArray) {
        *compationViewsArray = [[NSMutableArray alloc] init];
    }
    
    //创建伴随
    NSArray * companionArr = [self.currentAdModel getAvailableCompaionsWithSize:self.contentView.frame.size];
    for (ADVASTCompanionModel * companionModel in companionArr) {
        AdViewVastNonVideoView *companion = [[AdViewVastNonVideoView alloc] initWithObject:companionModel
                                                                                      type:ADVASTNonVideoViewTypeCompanion
                                                                                     scale:self.scale
                                                                                      size:self.contentView.frame.size];
        [companion createView];
        CGRect rect = companion.frame;
        rect.origin.x += self.contentView.frame.origin.x;
        rect.origin.y += self.contentView.frame.origin.y;
        
        companion.frame = rect;
        companion.delegate = self;
        [self.view addSubview:companion];
        [companion reportImpressionTracking];
        [*compationViewsArray addObject:companion];
    }
}

- (void)createIcon {
    //清理上个video的icon
    for (AdViewVastNonVideoView *view in _iconViewArr) {
        view.delegate = nil;
        [view removeFromSuperview];
    }
    [_iconViewArr removeAllObjects];
    
    if (nil == _iconViewArr) {
        _iconViewArr = [[NSMutableArray alloc] init];
    }
    
    // 创建icon
    for (ADVASTIconModel *iconModel in self.contentView.mediaFileModel.iconArray) {
        AdViewVastNonVideoView *icon = [[AdViewVastNonVideoView alloc] initWithObject:iconModel
                                                                                 type:ADVASTNonVideoViewTypeIcon
                                                                                scale:1
                                                                                 size:self.contentView.frame.size];
        [icon createView];
        icon.delegate = self;
        CGRect rect = icon.frame;
        rect.origin.x += self.contentView.frame.origin.x;
        rect.origin.y += self.contentView.frame.origin.y;
        icon.frame = rect;
        icon.hidden = YES;
        if (![icon.showTimeStr isEqualToString:@"-1"]) {
            icon.hidden = YES;
        }
        [self.view addSubview:icon];
        [icon reportImpressionTracking];
        [_iconViewArr addObject:icon];
    }
}

- (void)checkIconCanBeDisplayedOrRemovedWithTime:(NSString*)timeString {
    for (int i = 0; i < _iconViewArr.count; i++) {
        AdViewVastNonVideoView *view  = [_iconViewArr objectAtIndex:i];
        float nowTime = [timeString floatValue];
        float displayTime = [view.showTimeStr floatValue];
        float durationTime = [view.durationTimeStr floatValue];
        if ((self.countDownView.length - nowTime) >= displayTime) {
            view.hidden = NO;
        }
        if ((self.countDownView.length - nowTime - displayTime) > durationTime) {
            view.delegate = nil;
            [view removeFromSuperview];
            [_iconViewArr removeObject:view];
        }
    }
}

- (void)removeIconAndCompanion {
    if (_iconViewArr) {
        for (AdViewVastNonVideoView *view in _iconViewArr) {
            view.delegate = nil;
            [view removeFromSuperview];
        }
        [_iconViewArr removeAllObjects];
    }
    
    if (_companionViewArr) {
        for (AdViewVastNonVideoView *view in _companionViewArr) {
            view.delegate = nil;
            [view removeFromSuperview];
        }
        [_companionViewArr removeAllObjects];
    }
}

- (void)removeEndCard {
    for (AdViewVastNonVideoView * view in _endCardArray) {
        view.delegate = nil;
        [view removeFromSuperview];
    }
    [_endCardArray removeAllObjects];
}

#pragma mark - 调整方向方法
// force to always play in Landscape
- (BOOL)shouldAutorotate{
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    if (self.orientation == UIInterfaceOrientationUnknown) {
        self.orientation = [[UIApplication sharedApplication] statusBarOrientation];
    }
    return self.orientation;
}

#pragma mark - countdown view
- (void)addCountDownView {
    self.countDownView.length = [[self.contentView getVideoTotalTime] floatValue];
    [self.view addSubview:self.countDownView];
}

- (void)removeCountDownView {
    if (_countDownView) {
        [self.countDownView removeFromSuperview];
    }
}

#pragma mark - sound control
- (void)addSoundView {
    [self videoMute:[_contentView getVideoMute]];
    [self.view addSubview:self.soundView];
}

- (void)removeSoundView {
    if (_soundView) {
        [_soundView removeFromSuperview];
    }
}

#pragma mark - 加载菊花添加&移除
- (void)addActivityView
{
    if (_allVideoFinished)
    {
        return; // 所有资源处理完毕之后就不在添加
    }
    
    [[AdViewExtTool sharedTool] storeObject:@"1" forKey:@"__STATUS__"];
    loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0") ) {
        loadingIndicator.frame = CGRectMake( (self.view.frame.size.width/2)-25.0, (self.view.frame.size.height/2)-25.0,50,50);
    }
    else
    {
        loadingIndicator.frame = CGRectMake( (self.view.frame.size.height/2)-25.0, (self.view.frame.size.width/2)-25.0,50,50);
    }
    [loadingIndicator startAnimating];
    [self.view addSubview:loadingIndicator];
}

- (void)removeActivityView {
    if (loadingIndicator) {
        [[AdViewExtTool sharedTool] storeObject:@"0" forKey:@"__STATUS__"];
        [loadingIndicator stopAnimating];
        [loadingIndicator removeFromSuperview];
        loadingIndicator = nil;
    }
}

- (void)removeThumbnailView {
    [self.videoThumbnailView removeFromSuperview];
    self.videoThumbnailView = nil;
}

#pragma mark - 流量提醒 UIAlertViewDelegate && ShowAlertMethod
// 非WIFI下观看流量提醒
- (void)addAlertView
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"流量提醒" message:@"当前处于非WIFI环境下，继续观看将会消耗流量" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"继续" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self assignTaskAfterParseData];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self close];
    }];
    [alertController addAction:okAction];
    [alertController addAction:cancelAction];

    //查找正在当前显示的viewController
    UIViewController * presentViewController = nil;
    UIViewController * rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    if (rootViewController.isViewLoaded && rootViewController.view.window)
    {
        presentViewController = rootViewController;
    }
    else
    {
        presentViewController = [rootViewController presentedViewController];
    }
    [presentViewController presentViewController:alertController animated:YES completion:nil];
}

// 展示失败界面
- (void)showFaildInfomation:(NSString*)failStr
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"失败信息" message:failStr delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)   //cancel button
    {
        [self close];
    }
    else    // 分配任务进行缓存或者直接播放
    {
        [self assignTaskAfterParseData];
    }
}

#pragma mark - play status method
//播放开始,更新UI
- (void)changUIBeforePlayVideo {
    [self removeIconAndCompanion];
    [self removeEndCard];
    [self removeActivityView];
    [self removeThumbnailView];
    
    [self addSoundView];
    [self addCountDownView];
    
//    if (!self.contentView.cancelCountdown) {
//        [self createIcon];
//        [self creatCompationViewsInArray:&self->companionViewArr];
//    }
}

//播放结束.更新UI
- (void)changUIAfterPlayVideo {
    [self removeSoundView];
    [self removeCountDownView];
    [self removeIconAndCompanion];
    [self removeSkipButton];
    [self removeActivityView];
    
    //播放结束就加endCard
    [self creatEndCard];
}

//本次播放是否成功
- (void)playFinishedIsSuccess:(BOOL)isSuccess {
    _haveSuccess = _haveSuccess || isSuccess;
    _videoIsFinished = YES;
    _isPlaying = NO;
    _inPlayProcess = NO;
    [self changUIAfterPlayVideo];

    if (isSuccess) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(vastVideoPlayStatus:)]) {
            [self.delegate vastVideoPlayStatus:AdViewVideoPlayEnd];
        }
    } else {
        [[AdViewExtTool sharedTool] storeObject:@"2" forKey:@"__STATUS__"];
    }
    
    if (_allVideoFinished) {
        [self notifationTheResultForAllVideoPlayEnded];
    } else {
        [self addActivityView];
        if (_nextVideoReady) {
            [self playInRoll];
        }
    }
}


#pragma mark - AdViewVideoGeneralViewDelegate
- (void)videoStartPlay {
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_isPlaying = YES;
        self->_videoIsFinished = NO;
        
        [self changUIBeforePlayVideo];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(vastVideoPlayStatus:)]) {
            [self.delegate vastVideoPlayStatus:AdViewVideoPlayStart];
        }
        
        //开始监测
        [self.omsdkManager startMeasurement];
        [self.omsdkManager videoOrientation:self.orientation];
        [self.omsdkManager reportQuartileChange:AdViewOMSDKVideoQuartile_Start];
    });
}

- (void)videotEndPlay {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.omsdkManager reportQuartileChange:AdViewOMSDKVideoQuartile_Complete];
        [self playFinishedIsSuccess:YES];
    });
}

- (void)videoSkipped {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.omsdkManager skipped];
        if ([self.delegate respondsToSelector:@selector(vastVideoSkipped)]) {
            [self.delegate vastVideoSkipped];
        }
        [self changUIAfterPlayVideo];
        
        [self addCloseButton];
        if (!self.endCardArray.count) {
            [self addReplayButton];
        }
    });
}

- (void)videoPaused {
    [_omsdkManager pause];
}

- (void)videoResumed {
    [_omsdkManager resume];
}

- (void)videoPlayError {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self playFinishedIsSuccess:NO];
    });
}

- (void)videoMute:(BOOL)tmpIsMute {
    _isMute = tmpIsMute;
    [self.soundView setSelected:_isMute];
    [_omsdkManager volumeChangeTo:_isMute ? 0 : 1];
}

- (void)showSkipView {
    //如果是重播 则不再显示跳过广告
    if (!_isReplay) {
        [self addSkipButton];
    }
}

//时间回调
- (void)videoUpdatePlayTime:(NSString*)timeString {
    [self.countDownView updateCountDownLabelTextWithString:timeString];
    [self checkIconCanBeDisplayedOrRemovedWithTime:timeString];
}

//更新播放进度
- (void)videoUpdateCurrentVASTQuartile:(CurrentVASTQuartile)currentVastQuartile {
    [self omsdkReportQuartile:currentVastQuartile];
}

//点击
- (void)contentViewClickedWithUrl:(NSURL *)url {
    if ([self.delegate respondsToSelector:@selector(responsClickActionWithUrlString:)]) {
        [self pause];
        [self.delegate responsClickActionWithUrlString:url.absoluteString];
        [self OMSDKClickReportWithURL:url.absoluteString];
    }
}

#pragma mark - AdViewVastNonVideoViewDelegate
- (void)clickActionWithUrlString:(NSString *)urlString {
    if (self.delegate && [self.delegate respondsToSelector:@selector(responsClickActionWithUrlString:)]) {
        [self pause];
        [self.delegate responsClickActionWithUrlString:urlString];
        [self OMSDKClickReportWithURL:urlString];
    }
}

//OMSDK发送点击
- (void)OMSDKClickReportWithURL:(NSString *)clickURL {
    BOOL bHttp = ([clickURL rangeOfString:@"http://"].location == 0);
    BOOL bHttps = ([clickURL rangeOfString:@"https://"].location == 0);
    if (bHttp || bHttps) {
        [_omsdkManager adUserInteractionWithType:OMIDInteractionTypeClick];
    } else {
        [_omsdkManager adUserInteractionWithType:OMIDInteractionTypeAcceptInvitation];
    }
}

#pragma mark - AdViewVastVideoDownloadManagerDelegate
- (void)cacheTaskFailedWithError:(NSError *)error {
    AdViewLogDebug(@"VAST - View Controller : cache failed with error:%@",error.domain);
    _haveSuccess = _haveSuccess || NO;
    
    [[self.vastModel getCurrentAd] reportErrorsTracking];
    [[AdViewExtTool sharedTool] storeObject:@"2" forKey:@"__STATUS__"];
    
    self.videoDonloadManager = nil;
    [self.vastModel adjustCurrentIndex];
    [self assignTaskAfterParseData];
}

- (void)cacheTaskFinished {
    self.videoDonloadManager = nil;
    _nextVideoReady = YES;
    if (!_isFirstHandle) {
        if (!_inPlayProcess) {
            [self playInRoll];
        }
    } else {
        [self setVideoInfoWithModel];
    }
}

#pragma mark - notifation methods
- (void)resignActive:(NSNotification *)notification {
    //进入后台时先暂停播放
    if (_isPlaying) {
        [self pause];
    }
}

- (void)becomeActive:(NSNotification *)notification {
    //如果没播放完毕且暂停了,则播放
    if (!_videoIsFinished && _isPaused) {
        [self.contentView videoResume];
    }
}

- (void)removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}

//开始监听网络状态
- (void)setupReachability
{
    reachabilityForVAST = [AdViewReachability reachabilityForInternetConnection];
    [reachabilityForVAST startNotifier];
}

#pragma mark - Reachability
- (AdViewViewNetworkStatus)checkNetworkType {
    self.networkCurrentlyReachable = YES;
    AdViewViewNetworkStatus netStatus = [[AdViewReachability reachabilityForInternetConnection] currentReachabilityStatus];
    NSString * str;
    switch (netStatus)
    {
        case AdViewViewNotReachable:
            str = @"Not reachable";
            self.networkCurrentlyReachable = NO;
            break;
        case AdViewReachableViaWiFi:
            str = @"WiFi";
            break;
        case AdViewReachableViaWWAN:
            str = @"2G/3G";
            break;
        case kAdViewReachableVia2G:
            str = @"2G";
            break;
        case kAdViewReachableVia3G:
            str = @"3G";
            break;
        case kAdViewReachableVia4G:
            str = @"4G";
            break;
        default:
            break;
    }
    AdViewLogDebug(@"Newwork is now in %@",str);
    return netStatus;
}

#pragma DownloadManager
//视频下载管理器
- (AdViewVastVideoDownloadManager *)videoDonloadManager {
    if (!_videoDonloadManager) {
        _videoDonloadManager = [[AdViewVastVideoDownloadManager alloc] init];
        _videoDonloadManager.delegate = self;
    }
    return _videoDonloadManager;
}

#pragma mark - UIView Init
//倒计时
- (AdViewCountDownView *)countDownView {
    if (!_countDownView) {
        CGRect rect = self.contentView.frame;
        _countDownView = [[AdViewCountDownView alloc] initWithFrame:CGRectMake(rect.origin.x + kButtonSpace,
                                                                         rect.origin.y + rect.size.height - kButtonSpace - kButtonWidth,
                                                                         kButtonWidth,
                                                                         kButtonWidth)
                                                    lineWidth:0];
        _countDownView.textColor = [UIColor whiteColor];
        _countDownView.backStrokeColor = [AdViewExtTool hexStringToColor:@"#3FA0A0A0"];
        _countDownView.fillColor = [AdViewExtTool hexStringToColor:@"#3FA0A0A0"];
    }
    return _countDownView;
}

//声音
- (AdViewSoundView *)soundView
{
    if (!_soundView)
    {
        _soundView = [[AdViewSoundView alloc] init];
        [_soundView addTarget:self action:@selector(changeSoundStatus) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_soundView];
    }
    return _soundView;
}

- (void)changeSoundStatus {
    [self.contentView setVideoMute:!_isMute];   //这里设置给videoGeneralView,他会发送JS,之后会有回调回来
}

//视频view
- (AdViewVideoGeneralView *)contentView
{
    if (!_contentView)
    {
        _contentView = [[AdViewVideoGeneralView alloc] init];
        _contentView.adverType = _adverType;
        _contentView.vastModel = _currentAdModel;
    }
    return _contentView;
}

//开始按钮
- (UIButton *)startPlayButton {
    if (!_startPlayButton) {
        _startPlayButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_startPlayButton setImage:[UIImage imagesNamedFromCustomBundle:@"icon_video.png"] forState:UIControlStateNormal];
        [_startPlayButton addTarget:self action:@selector(play) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_startPlayButton];
    }
    return _startPlayButton;
}

- (UIImageView *)videoThumbnailView {
    if (!_videoThumbnailView) {
        _videoThumbnailView = [[UIImageView alloc] init];
        [self.view addSubview:_videoThumbnailView];
    }
    return _videoThumbnailView;
}

//跳过按钮
- (AdViewSkipVideoButton *)skipButton {
    if (!_skipButton) {
        _skipButton = [[AdViewSkipVideoButton alloc] init];
        [_skipButton addTarget:self action:@selector(skipVideo) forControlEvents:UIControlEventTouchUpInside];
    }
    return _skipButton;
}

//关闭按钮
- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _closeButton.layer.cornerRadius = kButtonWidth/2;
        _closeButton.layer.masksToBounds = YES;
        [_closeButton addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
        [_closeButton setImage:[UIImage imagesNamedFromCustomBundle:@"adview_video_close.png"] forState:UIControlStateNormal];
        [_closeButton setBackgroundColor:[AdViewExtTool hexStringToColor:@"#3FA0A0A0"]];
    }
    return _closeButton;
}

//重播按钮
- (UIButton *)replayButton {
    if (!_replayButton) {
        _replayButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _replayButton.layer.cornerRadius = kButtonWidth / 2;
        _replayButton.layer.masksToBounds = YES;
        [_replayButton addTarget:self action:@selector(replayButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [_replayButton setImage:[UIImage imagesNamedFromCustomBundle:@"adview_video_replay.png"] forState:UIControlStateNormal];
        [_replayButton setBackgroundColor:[AdViewExtTool hexStringToColor:@"#3FA0A0A0"]];
    }
    return _replayButton;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if (_adverType == AdViewRewardVideo) {
        self.contentView.center = self.view.center;
        UIEdgeInsets safeAreaInsets = AdViewSafeAreaInset(self.view);
        CGRect rect = self.contentView.frame;
        
        //如果contentview.frame超过了安全区域 则按钮要在安全区域内
        if (rect.origin.y < safeAreaInsets.top) {
            rect.origin.y = safeAreaInsets.top;
        }
        if (rect.origin.y + rect.size.height > self.view.frame.size.height - safeAreaInsets.bottom) {
            rect.size.height = self.view.frame.size.height - rect.origin.y - safeAreaInsets.bottom;
        }
        
        _startPlayButton.bounds = CGRectMake(0, 0, kButtonWidth * 2, kButtonWidth * 2);
        _startPlayButton.center = self.contentView.center;
        
        if (_videoThumbnailView) {
            CGSize videoPlayerSize = [self.contentView getViewSizeWith:[self.vastModel getCurrentMediaFile]];
            _videoThumbnailView.bounds = CGRectMake(0,
                                                    0,
                                                    videoPlayerSize.width,
                                                    videoPlayerSize.height);
            _videoThumbnailView.center = self.contentView.center;
        }

        _closeButton.frame = CGRectMake(rect.origin.x + rect.size.width - kButtonSpace - kButtonWidth,
                                        rect.origin.y + kButtonSpace,
                                        kButtonWidth,
                                        kButtonWidth);
        
        _replayButton.frame = CGRectMake(rect.origin.x + kButtonSpace,
                                         rect.origin.y + kButtonSpace,
                                         kButtonWidth,
                                         kButtonWidth);
        
        CGFloat space = 10;
        _skipButton.frame = CGRectMake(rect.origin.x + rect.size.width - space - 90,
                                       rect.origin.y + space,
                                       90,
                                       30);

        _soundView.frame = CGRectMake(rect.origin.x + rect.size.width - kButtonSpace - kButtonWidth,
                                      rect.origin.y + rect.size.height - kButtonSpace - kButtonWidth,
                                      kButtonWidth,
                                      kButtonWidth);
        
        _countDownView.frame = CGRectMake(rect.origin.x + kButtonSpace,
                                          rect.origin.y + rect.size.height - kButtonSpace - kButtonWidth,
                                          kButtonWidth,
                                          kButtonWidth);
    }
}

@end

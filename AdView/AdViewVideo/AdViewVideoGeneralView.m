//
//  AdViewVideoGeneralView.m
//  KOpenAPIAdView
//
//  Created by AdView on 2018/4/26.
//

#import "AdViewVideoGeneralView.h"
#import "AdViewVastFileHandle.h"
#import "AdViewVastMediaFile.h"
#import "ADVGVastExtensionModel.h"
#import "AdViewVastMediaFilePicker.h"
#import "AdViewExtTool.h"
#import "AdViewVastSettings.h"
#import <AVFoundation/AVFoundation.h>
#import "AdViewDefines.h"

@interface AdViewVideoGeneralView ()<UIWebViewDelegate, UIGestureRecognizerDelegate, AdViewVpaidProtocol>
@property (assign, nonatomic) CurrentVASTQuartile currentQuartile;
@property (assign, nonatomic) float currentTime;                //当前播放时间
@property (assign, nonatomic) float totalTime;                  //视频总时长
@property (assign, nonatomic) float unvideoTime;                // 记录非视频素材播放的时间
@property (strong, nonatomic) NSMutableArray *videoHangArr;     // 保存当前播放时间点,如果出现时间点重复超过10次,则判断为卡死->关闭视频
@property (strong, nonatomic) NSTimer *hangTestTimer;           // 卡死检测timer
@property (strong, nonatomic) NSTimer *videoLoadTimeoutTimer;   // 视频加载超时timer
@property (strong, nonatomic) NSTimer *unvideoTimer;            // 非视频资源时，倒计时读秒
@property (assign, nonatomic) BOOL didSkipped;                  // 屏蔽多次跳过回调
@property (nonatomic, assign) BOOL allowShowSkipButton;         // 是否允许显示skipButton
@property (assign, nonatomic) BOOL didNotifationShowSkipButton; // 已经通知显示跳过按钮，防止多次通知
@property (assign, nonatomic) BOOL didTouched;                  // 是否触摸

@property (nonatomic, strong) AdViewVPAIDClient * vpaidClient;  //vpaid处理
@property (nonatomic, assign) BOOL vpaidClientInjected;         // VPAID Client 创建完毕 bridge连接成功
@end

@implementation AdViewVideoGeneralView
- (instancetype)init {
    if (self = [super init]) {
        self.scrollView.bounces = NO;
        self.scrollView.scrollEnabled = NO;
        self.allowsInlineMediaPlayback = YES;       //在网页内部播放视频
        self.mediaPlaybackRequiresUserAction = NO;  //自动播放
        self.mediaPlaybackAllowsAirPlay = NO;
        self.userInteractionEnabled = YES;
        self.scalesPageToFit = NO;
        self.opaque = NO;
        self.backgroundColor = _adverType == AdViewBanner ? [UIColor blackColor] : [UIColor clearColor];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(setClickStatus)];
        tap.delegate = self;
        [self addGestureRecognizer:tap];
    }
    return self;
}

- (void)loadGeneralViewWithFileModel:(AdViewVastCreative *)creative delegate:(id<AdViewVideoGeneralViewDelegate>)delegate {
    self.delegate = self;
    self.eventDelegate = delegate;
    [self replaceFileModel:creative];
    
    if (_adverType == AdViewRewardVideo) {
        //只有video支持改变尺寸
        CGFloat y = [UIApplication sharedApplication].isStatusBarHidden ? 0 : 20;
        CGSize playerSize = [self getViewSizeWith:creative.mediaFile];
        self.frame = CGRectMake(0, y, playerSize.width, playerSize.height);
    }
}

- (void)replaceFileModel:(AdViewVastCreative *)model {
    self.mediaFileModel = model;
    self.currentQuartile = VASTFirstQuartile;
    self.totalTime = 0;
    self.unvideoTime = 0;
    self.didSkipped = NO;
    self.didNotifationShowSkipButton = NO;
    self.didTouched = NO;
    
    AdViewVastMediaFile *currentFile = self.mediaFileModel.mediaFile;
    [self setUpGeneralViewTypeWith:currentFile];
    
    NSString *urlString = [self getMediaFileURLWith:currentFile];
    NSString * kAdViewBaseURL = nil;
    // 加载vast、vpaid html模板
    if (self.mediaFileType != ADVASTMediaFileType_Html) {
        // 根据类型找出模板
        NSString *templet;
        if (self.mediaFileType == ADVASTMediaFileType_Image) {
            templet = [NSString stringWithContentsOfFile:[self pathForFrameworkResource:@"AdViewImageTemplet" ofType:@"js"]
                                                encoding:NSUTF8StringEncoding error:nil];
        } else if (self.mediaFileType == ADVASTMediaFileType_Video) {
            //VAST Video
            templet = [NSString stringWithContentsOfFile:[self pathForFrameworkResource:@"AdViewVASTVideoTemplet" ofType:@"js"]
                                                encoding:NSUTF8StringEncoding error:nil];
            CGFloat phoneVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
            NSString *playsInline = @"webkit-playsinline";
            if (phoneVersion >= 10.0) playsInline = @"playsinline";
            templet = [templet stringByReplacingOccurrencesOfString:@"PLAYSINLINE" withString:playsInline];
            
            //使用本地缓存视频文件还是播放URL
            templet = [templet stringByReplacingOccurrencesOfString:@"VIDEO_FILE" withString:urlString];
//            templet = [templet stringByReplacingOccurrencesOfString:@"VIDEO_FILE" withString:model.mediaFile.url.absoluteString];
        } else if (self.mediaFileType == ADVASTMediaFileType_JavaScript) {
            //VPAID
            //HTML模版
            NSString * htmlString = htmlString = [NSString stringWithContentsOfFile:[self pathForFrameworkResource:@"AdViewVPAIDTemplet"
                                                                                                            ofType:@"html"]
                                                                           encoding:NSUTF8StringEncoding error:nil];
            //JSBridge
            NSString * JSBridgeString = [NSString stringWithContentsOfFile:[self pathForFrameworkResource:@"AdViewVPAIDBridge"
                                                                                                   ofType:@"js"]
                                                                  encoding:NSUTF8StringEncoding error:nil];
            templet = [NSString stringWithFormat:htmlString, JSBridgeString, urlString];
            kAdViewBaseURL = [[NSBundle mainBundle] pathForResource:@"VPAID" ofType:@"html"];
        }
        [self loadHTMLString:templet baseURL:[NSURL URLWithString:kAdViewBaseURL]];
    } else {
        if ([urlString hasPrefix:@"http"]) {
            [self loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
        } else {
            [self loadHTMLString:urlString baseURL:nil];
        }
    }
    //开始计算超时
    [self startVideoLoadTimeoutTimer];
    AdViewLogDebug(@"request url string : %@",urlString);
}

//获取mediaFile里的视频URL或视频缓存路径
- (NSString *)getMediaFileURLWith:(AdViewVastMediaFile*)mediaFile
{
    NSString *cacheFilePath = [AdViewVastFileHandle cacheFileExistsWithURL:mediaFile.url];
    if (nil != cacheFilePath && cacheFilePath.length)
    {
        NSURL *url = [NSURL fileURLWithPath:cacheFilePath];
        return url.absoluteString;
    }
    else
    {
        return mediaFile.url.absoluteString;
    }
}

//从mediafile里面提取广告类型
- (void)setUpGeneralViewTypeWith:(AdViewVastMediaFile*)mediaFile
{
    if (self.mediaFileModel.mediaFile.fileType != ADVASTMediaFileType_Unknown)
    {
        self.mediaFileType = self.mediaFileModel.mediaFile.fileType;
    }
    else
    {
        self.mediaFileType = ADVASTMediaFileType_Html;
    }
}

- (CGSize)getViewSizeWith:(AdViewVastMediaFile*)mediaFile
{
    CGSize screenSize = [self getScreenSize];
    CGSize size = CGSizeZero;
    if (mediaFile.width != 0 && mediaFile.height != 0)
    {
        size = CGSizeMake(mediaFile.width, mediaFile.height);
    }
    else
    {
        // 设置一个默认尺寸
        NSString *urlString = [self getMediaFileURLWith:mediaFile];
        size = screenSize;
        if (self.mediaFileType == ADVASTMediaFileType_Image)
        {
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]]];
            size = image.size;
        }
        else if (self.mediaFileType == ADVASTMediaFileType_Video)
        {
            AVAsset *asset = [AVAsset assetWithURL:[NSURL URLWithString:urlString]];
            NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
            if (tracks && tracks.count)
            {
                AVAssetTrack *videoTrack = tracks.firstObject;
                size = videoTrack.naturalSize;
            }
        }
    }
    
    return [self changeSize:size];
}

- (CGSize)changeSize:(CGSize)bSize
{
    CGFloat scale = 1;
    CGSize screenSize = [self getScreenSize];
    CGFloat scaleX = bSize.width / screenSize.width;
    CGFloat scaleY = bSize.height / screenSize.height;
    scale = scaleX > scaleY ? scaleX : scaleY;
    
    bSize.width = bSize.width/scale;
    bSize.height = bSize.height/scale;
    return bSize;
}

//字符串编码base64
- (NSString *)encodeUseBase64:(NSString *)string
{
    NSData * data = [string dataUsingEncoding:NSUTF8StringEncoding];
    NSString * encodedStr = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    return encodedStr;
}

// 模板base64解码
- (NSString*)templetDecodeUseBase64:(NSString*)tmplet {
    NSData *data = [[NSData alloc] initWithBase64EncodedString:tmplet options:NSDataBase64DecodingIgnoreUnknownCharacters];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

#pragma mark - help method
- (CGSize)getScreenSize {
    BOOL statusBarHidden = [[UIApplication sharedApplication] isStatusBarHidden];
    CGSize size = [UIScreen mainScreen].bounds.size;
    if (!statusBarHidden) {
        size.height -= 20;
    }
    
    return size;
}

- (void)catchJsLog
{
    JSContext *ctx = [self valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    ctx[@"console"][@"log"] = ^(JSValue * msg) {
        NSLog(@"H5  log : %@", msg);
    };
    ctx[@"console"][@"warn"] = ^(JSValue * msg) {
        NSLog(@"H5  warn : %@", msg);
    };
    ctx[@"console"][@"error"] = ^(JSValue * msg) {
        NSLog(@"H5  error : %@", msg);
    };
}

#pragma mark - control method
- (void)videoPause
{
    if (self.mediaFileType == ADVASTMediaFileType_Video) {
        [self stringByEvaluatingJavaScriptFromString:@"pauseVideo()"];
    } else if (self.mediaFileType == ADVASTMediaFileType_JavaScript) {
        [_vpaidClient pauseAd];
    } else {
        [self stopUnvideoTimer];
    }
    [self stopVideoHangTimer];
    [self.mediaFileModel trackEvent:ADVideoEventTrackPause];
    if (self.eventDelegate && [self.eventDelegate respondsToSelector:@selector(videoPaused)]) {
        [self.eventDelegate videoPaused];
    }
}

- (void)videoResume {
    if (self.mediaFileType == ADVASTMediaFileType_Video) {
        [self stringByEvaluatingJavaScriptFromString:@"playVideo()"];
    } else if (self.mediaFileType == ADVASTMediaFileType_JavaScript) {
        [_vpaidClient resumeAd];
    } else {
        [self startUnvideoTimer];
    }
    [self.mediaFileModel trackEvent:ADVideoEventTrackResume];
    
    if (self.mediaFileType == ADVASTMediaFileType_Video || _mediaFileType == ADVASTMediaFileType_JavaScript) {
        [self startVideoHangTimer];
    }
    
    if ([self.eventDelegate respondsToSelector:@selector(videoResumed)]) {
        [self.eventDelegate videoResumed];
    }
}

// 如果未播放完毕就尝试停止 -> 调用skip, 如果播放完毕再尝试停止 -> 调用stop
- (void)stopVideo {
    if (self.mediaFileType == ADVASTMediaFileType_Video) {
        if (_currentTime < _totalTime) {
            [self skipVideo];
        } else {
            [self stringByEvaluatingJavaScriptFromString:@"pauseVideo()"];
        }
    } else if (self.mediaFileType == ADVASTMediaFileType_JavaScript) {
        NSInteger remainingTime = [self.vpaidClient getAdRemainingTime];
        if (remainingTime) {
            [self skipVideo];
        } else {
            [self.vpaidClient stopAd];
        }
    }
}

//用户点击跳过
- (void)skipVideo {
    switch (self.mediaFileType)
    {
        case ADVASTMediaFileType_Video:
            [self stringByEvaluatingJavaScriptFromString:@"skipVideo()"];
            break;
        case ADVASTMediaFileType_JavaScript:
            [self.vpaidClient skipAd];
            break;
        case ADVASTMediaFileType_Image:
        case ADVASTMediaFileType_Html:
        case ADVASTMediaFileType_Unknown:
            [self stopUnvideoTimer];
            break;
        default:
            break;
    }
    [self.mediaFileModel trackEvent:ADVideoEventTrackSkip];
    [self stopVideoHangTimer];
}

- (NSString*)getVideoTotalTime {
    NSString *timeString = self.mediaFileModel.duration;
    if (self.mediaFileType == ADVASTMediaFileType_Video) {
        timeString = [self stringByEvaluatingJavaScriptFromString:@"getTotalTime()"];
    } else if (self.mediaFileType == ADVASTMediaFileType_JavaScript) {
        timeString = [NSString stringWithFormat:@"%zd",[_vpaidClient getAdDuration]];
    }
    if (!timeString && timeString.length == 0) timeString = @"0";
    [[AdViewExtTool sharedTool] storeObject:timeString forKey:@"__DURATION__"];
    return timeString;
}

- (void)closeCreative
{
    [self.mediaFileModel trackEvent:ADVideoEventTrackCloseLinear];
    AdViewLogDebug(@"close linear");
    [self stopVideoLoadTimeoutTimer];
    [self stopVideoHangTimer];
}

- (void)stopLoadingVideo
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self stopVideo];
        [self stopLoading];
    });
}

- (BOOL)getVideoMute
{
    if (_mediaFileType == ADVASTMediaFileType_Video)
    {
        return NO;
    }
    else if (_mediaFileType == ADVASTMediaFileType_JavaScript)
    {
        return [_vpaidClient getAdVolume] > 0 ? NO : YES;
    }
    return NO;
}

- (void)setVideoMute:(BOOL)isMute
{
    if (_mediaFileType == ADVASTMediaFileType_Video )
    {
        [self stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"isMute(%@);",(isMute ? @"true" : @"false")]];
    }
    else if (_mediaFileType == ADVASTMediaFileType_JavaScript)
    {
        [_vpaidClient setAdVolume:isMute ? 0 : 100];
    }
    [self.mediaFileModel trackEvent:isMute ? ADVideoEventTrackMute : ADVideoEventTrackUnMute];
}

#pragma mark - VAST command method
- (void)size:(id)object {
    if (_adverType != AdViewRewardVideo) return;    //只有纯的vieo,才支持改变尺寸
    CGSize newSize;
    if (object) {
        CGFloat w = [[object objectForKey:@"w"] floatValue];
        CGFloat h = [[object objectForKey:@"h"] floatValue];
        newSize = [self changeSize:CGSizeMake(w, h)];
        if (isnan(newSize.width) || isnan(newSize.height)) {
            newSize = [self getViewSizeWith:self.mediaFileModel.mediaFile];
        }
    } else {
        newSize = [self getViewSizeWith:self.mediaFileModel.mediaFile];
    }

    if (self.frame.size.width != newSize.width || self.frame.size.height != newSize.height) {
        CGSize size = [self getScreenSize];
        CGFloat y = [UIApplication sharedApplication].isStatusBarHidden?0:20;
        self.frame = CGRectMake((size.width - newSize.width)/2, (size.height - newSize.height)/2 + y, newSize.width, newSize.height);
        [self stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"fixSize(%f,%f)",newSize.width,newSize.height]];
    }
    
    if (self.mediaFileType != ADVASTMediaFileType_Video) {
        [self play];
        if (self.cancelCountdown) {
            [self ended];
        } else {
            if  (self.totalTime > 0) {
                [self startUnvideoTimer];
            }
        }
    }
}

- (void)play {
    AdViewExtTool *tool = [AdViewExtTool sharedTool];
    [tool storeObject:@"0" forKey:@"__BEGINTIME__"];
    [tool storeObject:@"1" forKey:@"__FIRST_FRAME__"];
    self.totalTime = [[self getVideoTotalTime] floatValue];
    [self stopVideoLoadTimeoutTimer];
    [_mediaFileModel trackEvent:ADVideoEventTrackStart];

    if (self.eventDelegate && [self.eventDelegate respondsToSelector:@selector(videoStartPlay)]) {
        [self.eventDelegate videoStartPlay];
    }
    
    //视频卡死监测
    if (_mediaFileType == ADVASTMediaFileType_Video) {
        [_vastModel reportImpressionTracking];
        [self startVideoHangTimer];

    } else if (_mediaFileType == ADVASTMediaFileType_JavaScript) {
        [self startVideoHangTimer];
    }
}

//JS返回跳过成功
- (void)skipped {
    if (self.eventDelegate && [self.eventDelegate respondsToSelector:@selector(videoSkipped)]) {
        [self.eventDelegate videoSkipped];
    }
    [self stopVideoHangTimer];
    _didSkipped = YES;
}

//是否静音 VAST的js会调用
- (void)isMute:(NSString *)isMute {
    if ([self.eventDelegate respondsToSelector:@selector(videoMute:)]) {
        [self.eventDelegate videoMute:[isMute isEqualToString:@"true"] ? YES : NO];
    }
}

- (void)ended {
    AdViewExtTool *tool = [AdViewExtTool sharedTool];
    [tool storeObject:[NSString stringWithFormat:@"%d", (int)self.totalTime] forKey:@"__ENDTIME__"];
    [tool storeObject:@"1" forKey:@"__LAST_FRAME__"];
    [self.mediaFileModel trackEvent:ADVideoEventTrackComplete];
    if (self.eventDelegate && [self.eventDelegate respondsToSelector:@selector(videotEndPlay)]) {
        [self.eventDelegate videotEndPlay];
    }
    [self stopVideoHangTimer];
}

- (void)error {
    if (self.eventDelegate && [self.eventDelegate respondsToSelector:@selector(videoPlayError)]) {
        [self.eventDelegate videoPlayError];
    }
    [self stopVideoHangTimer];
    
    //上报错误
    [_vastModel reportErrorsTracking];
}

//汇报OMSDK错误
- (void)verificationNotExecuted {
    [(ADVGVastExtensionModel *)[self.vastModel.extesionArray firstObject] reportVerificationNotExecuted];
}

- (void)time:(NSString*)timeString {
    if (_didSkipped) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.currentTime = [timeString floatValue];
        if (self.eventDelegate && [self.eventDelegate respondsToSelector:@selector(videoUpdatePlayTime:)])
        {
            float time = self.totalTime - [timeString floatValue];
            [self.eventDelegate videoUpdatePlayTime:[NSString stringWithFormat:@"%f",time]];
        }
        if (self.mediaFileType == ADVASTMediaFileType_Video)
        {
            [self reportQuartileUrlWithTime:timeString];
        }
        
        if (self.allowShowSkipButton)
        {
            float time = [self.mediaFileModel.skipoffset floatValue];
            if (timeString.floatValue > time && !self.didNotifationShowSkipButton)
            {
                if (self.eventDelegate && [self.eventDelegate respondsToSelector:@selector(showSkipView)])
                {
                    [self.eventDelegate showSkipView];
                    self.didNotifationShowSkipButton = YES;
                }
            }
        }
    });
}

- (void)reportQuartileUrlWithTime:(NSString*)cTime {
    float currentPlayedPercentage = (float)([cTime floatValue]/self.totalTime);
    switch (self.currentQuartile) {
        case VASTFirstQuartile:
            if (currentPlayedPercentage > 0.25) {
                [self.mediaFileModel trackEvent:ADVideoEventTrackFirstQuartile];
                self.currentQuartile = VASTSecondQuartile;
            }
            break;
        case VASTSecondQuartile:
            if (currentPlayedPercentage > 0.50) {
                [self.mediaFileModel trackEvent:ADVideoEventTrackMidpoint];
                self.currentQuartile = VASTThirdQuartile;
            }
            break;
        case VASTThirdQuartile:
            if (currentPlayedPercentage > 0.75) {
                [self.mediaFileModel trackEvent:ADVideoEventTrackThirdQuartile];
                self.currentQuartile = VASTFourtQuartile;
            }
            break;
        default:
            break;
    }
}

- (void)setCurrentQuartile:(CurrentVASTQuartile)currentQuartile {
    _currentQuartile = currentQuartile;
    if ([self.eventDelegate respondsToSelector:@selector(videoUpdateCurrentVASTQuartile:)]) {
        [self.eventDelegate videoUpdateCurrentVASTQuartile:_currentQuartile];
    }
}

- (void)click:(id)object {
    [self.mediaFileModel reportClickTrackings];      //上报点击
    if (!self.mediaFileModel.clickThrough.url)
        return;
    
    if (self.eventDelegate && [self.eventDelegate respondsToSelector:@selector(contentViewClickedWithUrl:)]) {
        [self.eventDelegate contentViewClickedWithUrl:self.mediaFileModel.clickThrough.url];
    }
}

#pragma mark - 解析命令 js-native互调
- (void)parseCommandString:(NSString*)commandStr {
    if (_didSkipped) return; // 点击跳过之后不再解析命令，不再执行方法
    
    NSArray *commadArr = [commandStr componentsSeparatedByString:@"vast://"];
    if (commadArr.count >= 2) {
        NSString *methodStr = commadArr.lastObject;
        id paramObj;
        if ([methodStr containsString:@"?"]) {
            NSArray *resultArr = [methodStr componentsSeparatedByString:@"?"];
            if (resultArr && resultArr.count) {
                methodStr = [resultArr.firstObject stringByAppendingString:@":"];
                if ([resultArr.lastObject containsString:@"&"]) {
                    NSArray *paramArray = [resultArr.lastObject componentsSeparatedByString:@"&"];
                    if (paramArray && paramArray.count) {
                        for (NSString *paramstr in paramArray) {
                            if ([paramstr containsString:@"="]) {
                                NSArray *param = [paramstr componentsSeparatedByString:@"="];
                                if (param && param.count >= 2) {
                                    if (!paramObj) {
                                        paramObj = [NSMutableDictionary dictionary];
                                    }
                                    [paramObj setValue:param.lastObject forKey:param.firstObject];
                                }
                            }
                        }
                    }
                }else {
                    paramObj = resultArr.lastObject;
                }
            }
        }
        SEL selector = NSSelectorFromString(methodStr);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector:selector withObject:paramObj];
#pragma clang diagnostic pop
    }
}

#pragma mark - timer
// 启动检测卡死计时器
- (void)startVideoHangTimer
{
    [self stopVideoHangTimer];
    self.hangTestTimer = [NSTimer scheduledWeakTimerWithTimeInterval:1
                                                              target:self
                                                            selector:@selector(addDataToHangArrayAndCheck)
                                                            userInfo:nil
                                                             repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.hangTestTimer forMode:NSRunLoopCommonModes];
}

- (void)stopVideoHangTimer {
    if (self.hangTestTimer) {
        [self.videoHangArr removeAllObjects];
        [self.hangTestTimer invalidate];
        self.hangTestTimer = nil;
    }
}

- (void)addDataToHangArrayAndCheck
{
    [self.videoHangArr addObject:[NSNumber numberWithInt:self.currentTime]];
    if (self.videoHangArr.count > 10)
    {
        if ([self.videoHangArr.firstObject intValue] == [self.videoHangArr.lastObject intValue])
        {
            AdViewLogDebug(@"%s - 视频卡死",__FUNCTION__);
            [self stopLoadingVideo];
            [self error];
        }
        else
        {
            [self.videoHangArr removeObjectAtIndex:0];
        }
    }
}

- (void)startVideoLoadTimeoutTimer
{
    AdViewLogDebug(@"VAST - View Controller : Start Video Load Timer");
    [self stopVideoLoadTimeoutTimer];
    self.videoLoadTimeoutTimer = [NSTimer scheduledWeakTimerWithTimeInterval:[AdViewVastSettings vastVideoLoadTimeout]
                                                                      target:self
                                                                    selector:@selector(videoLoadTimerFired)
                                                                    userInfo:nil
                                                                     repeats:NO];
}

- (void)stopVideoLoadTimeoutTimer
{
    if (self.videoLoadTimeoutTimer)
    {
        [self.videoLoadTimeoutTimer invalidate];
        self.videoLoadTimeoutTimer = nil;
    }
    AdViewLogDebug(@"VAST - View Controller : Stop Video Load Timer");
}

- (void)videoLoadTimerFired
{
    AdViewLogDebug(@"video file load time out!");
    [self stopLoadingVideo];
    [self error];
}

//非视频类广告展示倒计时
- (void)startUnvideoTimer {
    [self stopUnvideoTimer];
    self.unvideoTimer = [NSTimer scheduledWeakTimerWithTimeInterval:0.25
                                                             target:self
                                                           selector:@selector(countDownDurations)
                                                           userInfo:nil
                                                            repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.unvideoTimer forMode:NSRunLoopCommonModes];
}

- (void)stopUnvideoTimer
{
    if (self.unvideoTimer)
    {
        [self.unvideoTimer invalidate];
        self.unvideoTimer = nil;
    }
}

//非视频类广告展示倒计时
- (void)countDownDurations {
    self.unvideoTime += 0.25;
    if (self.unvideoTime >= self.totalTime) {
        [self stopUnvideoTimer];
        [self ended];
    } else {
        [self time:[NSString stringWithFormat:@"%f",self.unvideoTime]];
    }
}

#pragma mark - uiwebviewdelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    AdViewLogDebug(@"%s - %@",__FUNCTION__, request.URL);
    if (_mediaFileType == ADVASTMediaFileType_Video)
    {
        NSString *commandStr = request.URL.absoluteString;
        [self parseCommandString:commandStr];
    }
    else if (_mediaFileType == ADVASTMediaFileType_JavaScript && [request.URL.absoluteString hasSuffix:@"VPAID.html"])
    {
        @synchronized (_vpaidClient) {
            _vpaidClientInjected = NO;
        }
    }

    if(navigationType == UIWebViewNavigationTypeLinkClicked || self.didTouched)
    {
        [self click:nil];
        return NO;
    }
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    AdViewLogDebug(@"%s",__FUNCTION__);
}

//根据vast类型不同,处理vpaid与普通vast
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    AdViewLogDebug(@"%s",__FUNCTION__);
    if (_mediaFileType == ADVASTMediaFileType_Video)
    {
        [self catchJsLog];
        [self size:nil];
        _allowShowSkipButton = ![self.mediaFileModel.skipoffset isEqualToString:@"-1"];
    }
    else if (_mediaFileType == ADVASTMediaFileType_JavaScript)
    {
        if (_vpaidClientInjected) return;   //如果已经生成VPAIDClient并且注入则返回
        
        if ([[webView stringByEvaluatingJavaScriptFromString:@"document.readyState"] isEqualToString:@"complete"])
        {
            JSContext * jsContext = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
            JSValue * slot = [jsContext evaluateScript:@"document.getElementById('AdView-slot')"];
            JSValue * videoSlot = [jsContext evaluateScript:@"document.getElementById('AdView-videoslot')"];
            self.vpaidClient = [[AdViewVPAIDClient alloc] initWithDelegate:self jsContext:jsContext];
            
            if ([_vpaidClient handshakeVersion] > 0)
            {
                @synchronized (_vpaidClient) {
                    _vpaidClientInjected = YES;
                }
                CGSize windowSize = [UIApplication sharedApplication].keyWindow.bounds.size;
                NSDictionary * adParametersDict = [self.mediaFileModel.adParametersArray firstObject];
                if (adParametersDict)
                {
                    NSString * codeName = [adParametersDict objectForKey:@"nodeName"];
                    NSString * parameterValue = [[[adParametersDict objectForKey:@"nodeChildArray"] firstObject] objectForKey:@"nodeContent"];
                    if (codeName && parameterValue)
                    {
                        adParametersDict = @{codeName : parameterValue};
                    }
                }
                [_vpaidClient initAdWithWidth:windowSize.width
                                       height:windowSize.height
                                     viewMode:AdViewVPAIDViewMode.fullscreen
                               desiredBitrate:720
                                 creativeData:adParametersDict ? : @{}
                              environmentVars:@{@"slot": slot, @"videoSlot" : videoSlot, @"videoSlotCanAutoPlay" : @(YES)}];
            }
            _allowShowSkipButton = [_vpaidClient getAdSkippableState];
        }
    }
    else
    {
        [self size:nil];
    }
}

#pragma mark - getter method
- (NSMutableArray *)videoHangArr
{
    if (!_videoHangArr)
    {
        _videoHangArr = [NSMutableArray arrayWithCapacity:20];
    }
    return _videoHangArr;
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    CGPoint point = [touch locationInView:self];
    
    // 存储数据用于宏替换
    AdViewExtTool *tool = [AdViewExtTool sharedTool];
    NSMutableDictionary *clickPositionDic = [NSMutableDictionary dictionary];
    [clickPositionDic setObject:[NSString stringWithFormat:@"%d", (int)point.x] forKey:@"down_x"];
    [clickPositionDic setObject:[NSString stringWithFormat:@"%d", (int)point.x] forKey:@"up_x"];
    [clickPositionDic setObject:[NSString stringWithFormat:@"%d", (int)point.y] forKey:@"down_y"];
    [clickPositionDic setObject:[NSString stringWithFormat:@"%d", (int)point.y] forKey:@"up_y"];
    [tool storeObject:[AdViewExtTool jsonStringFromDic:clickPositionDic] forKey:@"{ABSOLUTE_COORD}"];
    
    NSMutableDictionary *rPositionDic = [NSMutableDictionary dictionary];
    NSString *click_x = [NSString stringWithFormat:@"%d", (int)((point.x*1000)/self.frame.size.width)];
    NSString *click_y = [NSString stringWithFormat:@"%d", (int)((point.y*1000)/self.frame.size.height)];
    [rPositionDic setObject:click_x forKey:@"down_x"];
    [rPositionDic setObject:click_y forKey:@"down_y"];
    [rPositionDic setObject:click_x forKey:@"up_x"];
    [rPositionDic setObject:click_y forKey:@"up_y"];
    [tool storeObject:[AdViewExtTool jsonStringFromDic:rPositionDic] forKey:@"{RELATIVE_COORD}"];
    
    [tool storeObject:[NSString stringWithFormat:@"%d", (int)point.x] forKey:@"__DOWN_X__"];
    [tool storeObject:[NSString stringWithFormat:@"%d", (int)point.x] forKey:@"__UP_X__"];
    [tool storeObject:[NSString stringWithFormat:@"%d", (int)point.y] forKey:@"__DOWN_y__"];
    [tool storeObject:[NSString stringWithFormat:@"%d", (int)point.y] forKey:@"__UP_y__"];
    
    return YES;
}

#pragma mark - click response method
- (void)setClickStatus
{
    self.didTouched = YES;
}

#pragma mark - VPAID delegate
- (void)vpaidAdLoaded
{
    AdViewLogDebug(@"%s",__FUNCTION__);
    [self.vpaidClient stopActionTimeOutTimer];
    [self.vpaidClient startAd];
}

- (void)vpaidAdStarted
{
    AdViewLogDebug(@"%s",__FUNCTION__);
    [self.vpaidClient stopActionTimeOutTimer];
    [self play];
}

- (void)vpaidAdPaused {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self videoPause];
    });
}

- (void)vpaidAdPlaying
{
    AdViewLogDebug(@"%s",__FUNCTION__);
}

- (void)vpaidAdExpandedChange
{
    AdViewLogDebug(@"%s",__FUNCTION__);
}

- (void)vpaidAdSkipped {
    AdViewLogDebug(@"%s",__FUNCTION__);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self skipped]; //直接调VAST的
    });
}

//Stop的不走其他逻辑
- (void)vpaidAdStopped {
    AdViewLogDebug(@"%s",__FUNCTION__);
}

- (void)vpaidAdVolumeChanged {
    AdViewLogDebug(@"%s",__FUNCTION__);
    if ([self.eventDelegate respondsToSelector:@selector(videoMute:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            int volume = [self.vpaidClient getAdVolume];
            [self.eventDelegate videoMute:volume && volume <= 100 ? NO : YES];
        });
    }
}

- (void)vpaidAdSkippableStateChange {
    AdViewLogDebug(@"%s",__FUNCTION__);
    self.allowShowSkipButton = [_vpaidClient getAdSkippableState];
}

- (void)vpaidAdLinearChange
{
    AdViewLogDebug(@"%s",__FUNCTION__);
}

- (void)vpaidProgressChanged
{
    NSInteger duration = [_vpaidClient getAdDuration];
    NSInteger remainTime = [_vpaidClient getAdRemainingTime];
    self.totalTime = duration;
    [self time:[NSString stringWithFormat:@"%d",(int)duration - (int)remainTime]];
}

- (void)vpaidAdDurationChange {
    self.totalTime = [self.vpaidClient getAdDuration];
    AdViewLogDebug(@"%s - %zd : %zd",__FUNCTION__,[self.vpaidClient getAdRemainingTime],[self.vpaidClient getAdDuration]);
}

- (void)vpaidAdRemainingTimeChange
{
    AdViewLogDebug(@"%s - %zd : %zd",__FUNCTION__,[self.vpaidClient getAdRemainingTime],[self.vpaidClient getAdDuration]);
}

- (void)vpaidAdImpression
{
    AdViewLogDebug(@"%s",__FUNCTION__);
    [_vastModel reportImpressionTracking];
}

- (void)vpaidAdVideoStart
{
    AdViewLogDebug(@"%s",__FUNCTION__);
}

- (void)vpaidAdVideoFirstQuartile
{
    AdViewLogDebug(@"%s",__FUNCTION__);
    [self.mediaFileModel trackEvent:ADVideoEventTrackFirstQuartile];
    self.currentQuartile = VASTSecondQuartile;
}

- (void)vpaidAdVideoMidpoint
{
    AdViewLogDebug(@"%s",__FUNCTION__);
    [self.mediaFileModel trackEvent:ADVideoEventTrackMidpoint];
    self.currentQuartile = VASTThirdQuartile;
}

- (void)vpaidAdVideoThirdQuartile
{
    AdViewLogDebug(@"%s",__FUNCTION__);
    [self.mediaFileModel trackEvent:ADVideoEventTrackThirdQuartile];
    self.currentQuartile = VASTFourtQuartile;
}

- (void)vpaidAdVideoComplete {
    AdViewLogDebug(@"%s",__FUNCTION__);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self ended];   //直接走VAST的播放完毕
    });
}

- (void)vpaidAdSizeChange
{
    AdViewLogDebug(@"VPAID size change");
}

- (void)vpaidAdClickThru:(NSString *)url id:(NSString *)Id playerHandles:(BOOL)playerHandles
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (url && url.length > 0)
        {
            if (self.eventDelegate && [self.eventDelegate respondsToSelector:@selector(contentViewClickedWithUrl:)])
            {
                [self.eventDelegate contentViewClickedWithUrl:[NSURL URLWithString:url]];
            }
        }
        else
        {
            if (playerHandles)
            {
                if (self.eventDelegate && [self.eventDelegate respondsToSelector:@selector(contentViewClickedWithUrl:)])
                {
                    [self.eventDelegate contentViewClickedWithUrl:[self.mediaFileModel clickThrough].url];
                }
            }
        }
    });
}

- (void)vpaidAdInteraction:(NSString *)eventID
{
    AdViewLogDebug(@"VPAID Ad interaction: %@", eventID);
}

- (void)vpaidAdUserAcceptInvitation {
    AdViewLogDebug(@"VPAID Ad UserAcceptInvitation");
}

- (void)vpaidAdUserMinimize {
    AdViewLogDebug(@"%s",__FUNCTION__);
}

- (void)vpaidAdUserClose {
    AdViewLogDebug(@"%s",__FUNCTION__);
}

- (void)vpaidAdError:(NSString *)error
{
    AdViewLogDebug(@"%s:%@",__FUNCTION__,error);
}

- (void)vpaidAdLog:(NSString *)message
{
    AdViewLogDebug(message);
}

- (void)vpaidJSError:(NSString *)message
{
    AdViewLogDebug(@"%s:%@",__FUNCTION__,message);
}

- (void)dealloc
{
    AdViewLogInfo(@"%s",__FUNCTION__);
    self.delegate = nil;
    self.vpaidClient = nil;
    self.videoLoadTimeoutTimer = nil;
    self.hangTestTimer = nil;
    self.unvideoTimer = nil;
}
@end

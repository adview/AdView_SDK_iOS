//
//  AdViewVideo.m
//  AdViewHello
//
//  Created by AdView on 2018/8/1.
//

#import <AdViewSDK/AdViewVideo.h>
#import "AdViewVideoViewController.h"
#import "ADURLConnection.h"
#import "AdViewWebViewController.h"
#import <MessageUI/MessageUI.h>
#import "AdViewExtTool.h"
#import "AdViewVastFileHandle.h"
#import "AdViewRolloverManager.h"
#import "AdViewOMAdVideoManager.h"

@interface AdViewVideo()<ADURLConnectionDelegate,
AdViewWebViewControllerDelegate,
MFMessageComposeViewControllerDelegate,
AdViewVideoViewControllerDelegate,
AdViewRolloverManagerDelegate>
{
    AdViewVideoViewController * vastController; //真正播放控制器
    ADURLConnection * videoConnection;          //请求
    ADVideoData * adData;
    AdViewVideoType viType;
    NSString * appID;
    NSString * positionId;
    NSString * clickUrl;                        //贴片点击代发网址
    BOOL isReadyToPlay;                         //是否准备好播放
    id<AdViewVideoDelegate> __weak delegate;
    
    /*
     * 保存vastController的设置
     */
    CGFloat lAndRGap;//左右间隙
    CGFloat tAndBGap;//上下间隙
    UIInterfaceOrientation controllerOrientation;   //vastController方向
    UIColor * vastControllerBackgroundColor;        //vastController背景色
    BOOL autoClose; //自动关闭
    BOOL showAlert; //是否展示流量提醒
}

@property (nonatomic, strong) AdViewVideoViewController *vastController;
@property (nonatomic, weak) id<AdViewVideoDelegate> delegate;
@property (strong, nonatomic) NSString *clickUrl;
@property (strong, nonatomic) AdViewRolloverManager *rollOverManager;

///**
// * 设置左右上下间隙
// * @param lrGap:视频view距离左右边缘的间隙（左边和右边间隙相同，所以用一个参数，默认为0）
// * @param tbGap:视频view距离上下边缘的间隙（上边和下边间隙相同，所以用一个参数，默认为0）
// */
//- (void)setLeftAndRightGap:(CGFloat)lrGap topAndBottomGap:(CGFloat)tbGap;
//
///**
// * 视频广告播放完成后是否自动关闭
// * @param enable:是否自动关闭（YES为自动关闭，默认为NO）
// */
//- (void)enableAutoClose:(BOOL)enable;

@end

@implementation AdViewVideo
@synthesize vastController;
@synthesize delegate;
@synthesize clickUrl;
@synthesize enableGPS;

+ (AdViewVideo *)playVideoWithAppId:(NSString*)appId
                         positionId:(NSString*)positionID
                          videoType:(AdViewVideoType)videoType
                           delegate:(id<AdViewVideoDelegate>)videoDelegate
{
    AdViewVideo *video = [[AdViewVideo alloc] initWithAppId:appId
                                                 positionId:positionID
                                                  videoType:videoType
                                                   delegate:videoDelegate];
    [AdViewOMBaseAdUnitManager activateOMIDSDK];  //激活OMSDK
    return video;
}

- (id)initWithAppId:(NSString*)appId
         positionId:(NSString*)positionID
          videoType:(AdViewVideoType)videoType
           delegate:(id<AdViewVideoDelegate>)videoDelegate
{
    if (self = [super init])
    {
        viType = videoType;
        appID = appId;
        positionId = positionID;
        self.enableGPS = NO;
        self.delegate = videoDelegate;
        isReadyToPlay = NO;
        lAndRGap = 0;
        tAndBGap = 0;
        controllerOrientation = UIInterfaceOrientationPortrait;
        vastControllerBackgroundColor = [UIColor blackColor];
        autoClose = NO;
        showAlert = NO;
    }
    return self;
}

- (void)dealloc {
    vastController = nil;
    videoConnection = nil;
    adData = nil;
    clickUrl = nil;
    delegate = nil;
    appID = nil;
    positionId = nil;
    vastControllerBackgroundColor = nil;
    AdViewLogDebug(@"AdViewVideo dealloc");
}

- (void)setLeftAndRightGap:(float)lrGap topAndBottomGap:(float)tbGap
{
    if (viType == AdViewVideoTypePreMovie)
    {
        return;
    }
    
    if (lrGap < 0) lrGap = 0;
    if (tbGap < 0) tbGap = 0;
    lAndRGap = lrGap;
    tAndBGap = tbGap;
}

- (void)setInterfaceOrientations:(UIInterfaceOrientation)orientation {
    if (viType == AdViewVideoTypePreMovie) {
        return;
    }
    controllerOrientation = orientation;
}

- (void)isShowTrafficReminderView:(BOOL)isShow
{
    if (viType == AdViewVideoTypePreMovie) {
        return;
    }
    showAlert = isShow;
}

//请求新广告
- (void)getVideoAD
{
    isReadyToPlay = NO;
    self.rollOverManager = nil;
    [self getAdRequestWithAppId:appID videoType:viType];
}

- (void)enableAutoClose:(BOOL)enable
{
    if (viType == AdViewVideoTypePreMovie)
    {
        return;
    }
    autoClose = enable;
}

- (BOOL)showVideoWithController:(UIViewController *)controller
{
    if (viType == AdViewVideoTypeInstl && (isReadyToPlay == YES))
    {
        [self displayADVideoControllerWithController:controller];
        return YES;
    }
    return NO;
}

- (void)setVideoBackgroundColor:(UIColor*)backgroundColor
{
    if (viType == AdViewVideoTypePreMovie) return;

    vastControllerBackgroundColor = backgroundColor ?: vastControllerBackgroundColor;
}

- (void)displayADVideoControllerWithController:(UIViewController*)controller
{
    if (controller == nil) {
        controller = [UIApplication sharedApplication].keyWindow.rootViewController;
    }
    if (enableGPS) {
        [[AdViewExtTool sharedTool] getLocation];
    }
    
    if (self.rollOverManager) {
        [self.rollOverManager showVideoWithController:controller];
    } else {
        if (!vastController){
            AdViewLogInfo(@"展示失败请重新load");
            return;
        }
        __weak typeof(self) weakSelf = self;
        AdView_PBM PBMType = adData.pbm;
        [controller presentViewController:vastController animated:YES completion:^{
            switch (PBMType) {
                case AdView_PBM_AutoPlay:
                    [weakSelf.vastController play];
                    break;
                case AdView_PBM_UserAllow:
                    [weakSelf.vastController waitUserAllowPlay];
                    break;
                default:
                    [weakSelf.vastController play];
                    break;
            }
        }];
    }
}

- (void)getAdRequestWithAppId:(NSString*)appId videoType:(AdViewVideoType)videoType {
    AVTemporaryData *temporaryData = [[AVTemporaryData alloc] init];
    temporaryData.appID = appId;
    temporaryData.posID = positionId;
    temporaryData.videoType = videoType;    //弹出视频、贴片数据视频
    
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
    
    temporaryData.subjectToGDPR = subjectToGDPR;
    temporaryData.consentString = consentString;
    temporaryData.CMPPresent = CMPPresen;
    temporaryData.parsedPurposeConsents = parsedPurposeConsents;
    temporaryData.parsedVendorConsents = parsedVendorConsents;
    temporaryData.ccpaString = [userDefaults objectForKey:AdView_IABConsent_CCPA];
    
    if (enableGPS)
    {
        [[AdViewExtTool sharedTool] getLocation];
    }
    videoConnection = [[ADURLConnection alloc] initWithConnectionType:ADURLConnectionTypeGetData
                                                    withTemporaryData:temporaryData
                                                             delegate:self];
}

- (void)clearVideoBuffer {
    [AdViewVastFileHandle clearCache];
}

#pragma mark - Mraid action
- (void)sendInAppSMS:(NSString*)addr Body:(NSString*)bodyStr withController:(UIViewController*)actController
{
    MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
    if([MFMessageComposeViewController canSendText])
    {
        controller.body = bodyStr;
        controller.recipients = [NSArray arrayWithObjects:addr, nil];
        controller.messageComposeDelegate = self;
        [actController presentViewController:controller animated:YES completion:nil];
    }
}

-(void) openLink:(NSString*)actionStr withController:(UIViewController*)actionController{
    if (actionStr && actionStr.length <= 0) {
        AdViewLogDebug(@"can not open link.");
        return;
    }
    
    NSString *urlString = actionStr;
    
    BOOL bItunes = ([urlString rangeOfString:@"//itunes.apple.com"].location != NSNotFound);
    BOOL bHttp = ([urlString rangeOfString:@"http://"].location == 0);    //http
    BOOL bHttps = ([urlString rangeOfString:@"https://"].location == 0);
    
    BOOL bJudgeLocalWeb = (bHttp || bHttps) && !bItunes;
    
    AVAdActionType actionType = adData.adActionType;
    if (actionType != AVAdActionType_Unknown) {
        switch (actionType) {
            case AVAdActionType_Web:
            case AVAdActionType_OpenURL:
                bJudgeLocalWeb = YES;
                break;
            case AVAdActionType_AppStore:
                bJudgeLocalWeb = NO;
                break;
            case AVAdActionType_Call:
                urlString = [NSString stringWithFormat:@"tel://%@",urlString];
                bJudgeLocalWeb = NO;
                break;
            case AVAdActionType_Sms: {
                NSArray *arrItems = [urlString componentsSeparatedByString:@","];
                [self sendInAppSMS:[arrItems firstObject] Body:[arrItems objectAtIndex:1] withController:actionController];
                return;
            }
                break;
            case AVAdActionType_Mail:
                break;
            case AVAdActionType_Map:
                break;
            default:
                break;
        }
    }
    
    AdViewLogDebug(@"openLink:%@", urlString);
    AdViewLogDebug(@"Judge LocalWeb:%d", bJudgeLocalWeb);
    
    if (bJudgeLocalWeb && viType == AdViewVideoTypeInstl){
        AdViewWebViewController *webViewController = [[AdViewWebViewController alloc] init];
        webViewController.delegate = self;
        webViewController.urlString = urlString;
        [actionController presentViewController:webViewController animated:YES completion:nil];
        return;
    }
    
    NSURL *url = [NSURL URLWithString:urlString];
    if ([[UIApplication sharedApplication] canOpenURL:url])
    {
        [[UIApplication sharedApplication] openURL:url];
    } else {
        AdViewLogDebug(@"can not handle url %@", urlString);
    }
}

#pragma mark - ADURLConnectionDelegate
- (void)connectionDidFinshedLoadingWithUrlConnection:(ADURLConnection *)connection {
    NSString *vastString;
    if (viType == AdViewVideoTypeInstl) {
        self.vastController = [[AdViewVideoViewController alloc] initWithDelegate:self adverType:AdViewRewardVideo];
        self.vastController.leftGap = lAndRGap;
        self.vastController.topGap = tAndBGap;
        self.vastController.enableAutoClose = autoClose;
        self.vastController.allowAlertView = showAlert;
        self.vastController.orientation = controllerOrientation;
        self.vastController.view.backgroundColor = vastControllerBackgroundColor;
        self.vastController.modalPresentationStyle = UIModalPresentationFullScreen;
        [vastController loadVideoWithData:[connection.videoData.adBody dataUsingEncoding:NSUTF8StringEncoding]];
        adData = connection.videoData;
    } else if(viType == AdViewVideoTypePreMovie) {
        vastString = connection.videoData.adBody;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(adViewVideoDidReceiveAd:)]) {
            [self.delegate adViewVideoDidReceiveAd:vastString];
        }
    }
    videoConnection = nil;
}

- (void)connectionFailedLoadingWithError:(NSError *)error
{
    if (viType == AdViewVideoTypePreMovie)
    {
        if (self.delegate && [self.delegate respondsToSelector:@selector(adViewVideoFailReceiveDataWithError:)])
        {
            [self.delegate adViewVideoFailReceiveDataWithError:error];
            videoConnection = nil;
        }
    }
    else
    {
        [self rollOverWithError:error];
    }
}

#pragma mark - AdViewVideoViewControllerDelegate
- (void)vastReady:(AdViewVideoViewController *)vastVC
{
    isReadyToPlay = YES;
    if (self.delegate && [self.delegate respondsToSelector:@selector(adViewVideoIsReadyToPlay:)])
    {
        [self.delegate adViewVideoIsReadyToPlay:self];
    }
}

// sent when any VASTError occurs - optional
- (void)vastError:(AdViewVideoViewController *)vastVC error:(AdViewVastError)error {
    NSString *errMsg;
    switch (error) {
        case VASTErrorXMLParse:
            errMsg = @"异常广告，解析失败";
            break;
        case VASTErrorNone:
            errMsg = @"播放失败";
            break;
        case VASTErrorPlayerNotReady:
            errMsg = @"视频未准备好";
            break;
        case VASTErrorNoInternetConnection:
            errMsg = @"检查网络连接";
            break;
        case VASTErrorVideoFileTooBig:
            errMsg = @"视频文件过大";
            break;
        case VASTErrorTooManyWrappers:
            errMsg = @"wrapper跳转次数过多";
            break;
        case VASTErrorPlayerFailed:
            errMsg = @"播放器错误";
            break;
        default:
            errMsg = @"广告未知";
            break;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(adViewVideoFailReceiveDataWithError:)]) {
        NSError *err = [[NSError alloc] initWithDomain:errMsg code:9999 userInfo:nil];
        [self.delegate adViewVideoFailReceiveDataWithError:err];
    }
}

- (void)vastVideoAllPlayEnd:(AdViewVideoViewController *)vastVC {
    if (self.delegate && [self.delegate respondsToSelector:@selector(adViewVideoPlayEnded)]) {
        [self.delegate adViewVideoPlayEnded];
    }
}

- (void)vastVideoSkipped {
    if ([self.delegate respondsToSelector:@selector(adViewVideoSkipped)]) {
        [self.delegate adViewVideoSkipped];
    }
}

- (void)vastWillPresentFullScreen:(AdViewVideoViewController *)vastVC{}

- (void)vastDidDismissFullScreen:(AdViewVideoViewController *)vastVC{
    if (self.delegate && [self.delegate respondsToSelector:@selector(adViewVideoClosed)]) {
        [self.delegate adViewVideoClosed];
    }
    vastController = nil;
}

- (void)vastOpenBrowseWithUrl:(NSURL *)url{}
- (void)vastTrackingEvent:(NSString *)eventName{}

- (void)vastVideoPlayStatus:(AdViewVideoPlayStatus)videoStatus {
    if (videoStatus == AdViewVideoPlayStart) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(adViewVideoPlayStarted)]) {
            [self.delegate adViewVideoPlayStarted];
        }
    }
}

- (void)responsClickActionWithUrlString:(NSString*)clickStr {
    if (enableGPS) {
        [[AdViewExtTool sharedTool] getLocation];
    }
    [self openLink:[[AdViewExtTool sharedTool] replaceDefineString:clickStr] withController:vastController];
}

#pragma mark - AdViewWebViewControllerDelegate
- (void)dismissWebViewModal:(UIWebView*)webView {
    if (self.vastController) {
        [self.vastController resume];
    }
}

- (BOOL)isSuccessOpenAppStoreInAppWithUrlString:(NSString *)urlString {
    return YES;
}

#pragma mark sms delegate
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    switch (result) {
        case MessageComposeResultCancelled:
            AdViewLogDebug(@"Cancelled");
            break;
        case MessageComposeResultFailed:
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"OpenAPIAdView SDK"
                                                            message:@"Unknown Error"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles: nil];
            [alert show];
        }
            break;
        case MessageComposeResultSent:
            
            break;
        default:
            break;
    }
    if (viType == AdViewVideoTypeInstl) {
        [vastController close];
    }else
        [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - rollover methods
- (BOOL)checkIsHaveOtherPlatForRollOver {
    if (videoConnection.videoData.otherPlatArray && videoConnection.videoData.otherPlatArray.count > 0) {
        return YES;
    }
    return NO;
}

- (void)rollOverWithError:(NSError*)error {
    //    videoConnection
    if ([self checkIsHaveOtherPlatForRollOver]) {
        self.rollOverManager = [[AdViewRolloverManager alloc] initWithRolloverPaltInfo:videoConnection.videoData.otherPlatArray];
        self.rollOverManager.delegate = self;
        [self.rollOverManager loadVideoAd];
    }else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(adViewVideoFailReceiveDataWithError:)]) {
            [self.delegate adViewVideoFailReceiveDataWithError:error];
            videoConnection = nil;
        }
    }
}

#pragma mark - RollOverManagerDelegate
- (void)getAdFailedToReceiveAd {
    if (self.delegate && [self.delegate respondsToSelector:@selector(adViewVideoFailReceiveDataWithError:)]) {
        [self.delegate adViewVideoFailReceiveDataWithError:[[NSError alloc] initWithDomain:@"no suitable ad" code:0 userInfo:nil]];
    }
}

- (void)videoReadyToPlay {
    isReadyToPlay = YES;
    if (self.delegate && [self.delegate respondsToSelector:@selector(adViewVideoIsReadyToPlay:)]) {
        [self.delegate adViewVideoIsReadyToPlay:self];
    }
}

- (void)getAdSuccessToReceivedAdWithView:(UIView *)bannerView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(adViewVideoDidReceiveAd:)]) {
        [self.delegate adViewVideoDidReceiveAd:nil];
    }
}

- (void)adViewWillClicked {
    
}

- (void)videoPlayStarted {
    if (self.delegate && [self.delegate respondsToSelector:@selector(adViewVideoPlayStarted)]) {
        [self.delegate adViewVideoPlayStarted];
    }
}

- (void)videoPlayEnded {
    if (self.delegate && [self.delegate respondsToSelector:@selector(adViewVideoPlayEnded)]) {
        [self.delegate adViewVideoPlayEnded];
    }
}

- (void)videoClosed {
    if (self.delegate && [self.delegate respondsToSelector:@selector(adViewVideoClosed)]) {
        [self.delegate adViewVideoClosed];
    }
}

- (void)adViewDidDismissScreen {
    
}


- (void)adViewWillCloseInstl {
    
}


- (void)adViewWillPresentScreen {
    
}


- (void)adViewWillShowAd {
    
}


- (void)getAdSuccessToReceivedNativeAdWithArray:(NSArray *)dataArray {
    
}


@end

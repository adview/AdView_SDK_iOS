//
//  RolloverManager.m
//  AdViewHello
//
//  Created by AdView on 2018/8/15.
//

#import "AdViewRolloverManager.h"
#import "AdViewRolloverAdapterModel.h"
#import "AdViewExtTool.h"

typedef NS_ENUM(NSUInteger, RequestAdType) {
    RequestAdType_Banner,
    RequestAdType_Instl,
    RequestAdType_Spread,
    RequestAdType_Native,
    RequestAdType_Video
};

@interface AdViewRolloverManager ()

@property (nonatomic, copy) NSArray *platArray;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) NSUInteger currentIndex;
@property (nonatomic, strong) AdViewRolloverAdapter *currentAdapter;
@property (nonatomic, assign) RequestAdType adType;
@property (nonatomic, assign) int nativeAdCount;

@property (nonatomic, assign) BOOL canReportDisplayUrl; // 能否汇报展示地址/防止同一条广告多次发送展示汇报（原因是因为某个平台可能多次调用展示回调）

@end

@implementation AdViewRolloverManager
- (instancetype)initWithRolloverPaltInfo:(NSArray*)platInfoArray {
    if (self = [super init]) {
        self.platArray = platInfoArray;
        self.currentIndex = -1;
    }
    return self;
}

- (AdViewRolloverAdapterModel*)setModelConfig
{
    self.currentIndex++;
    if (self.currentIndex >= self.platArray.count)
    {
        if (self.delegate && [self.delegate respondsToSelector:@selector(getAdFailedToReceiveAd)])
        {
            [self.delegate getAdFailedToReceiveAd];
        }
        return nil;
    }
    self.canReportDisplayUrl = NO;
    
    AdViewRolloverAdapterModel * model = [self.platArray objectAtIndex:self.currentIndex];
    if (nil == model)
    {
        if (self.delegate && [self.delegate respondsToSelector:@selector(getAdFailedToReceiveAd)])
        {
            [self.delegate getAdFailedToReceiveAd];
        }
    }
    return model;
}

- (void)getBannerAd {
    self.adType = RequestAdType_Banner;
    AdViewRolloverAdapterModel *model = [self setModelConfig];
    if (nil == model) {return;}
    self.currentAdapter = [[model.adapterClass alloc] initWithDataModel:model];
    self.currentAdapter.controller = self.controller;
    self.currentAdapter.manager = self;
    [self.currentAdapter getBannerAd];
    [self startTimer];
}

- (void)loadInstlAd {
    self.adType = RequestAdType_Instl;
    AdViewRolloverAdapterModel *model = [self setModelConfig];
    if (nil == model) {return;}
    self.currentAdapter = [[model.adapterClass alloc] initWithDataModel:model];
    self.currentAdapter.manager = self;
    self.currentAdapter.controller = self.controller;
    [self.currentAdapter loadInstallAd];
    [self startTimer];
}

- (void)showInstlWithController:(UIViewController*)controller {
    [self.currentAdapter showInstallWithController:controller];
}

- (void)loadSpreadAd {
    self.adType = RequestAdType_Spread;
    AdViewRolloverAdapterModel *model = [self setModelConfig];
    if (nil == model) {return;}
    self.currentAdapter = [[model.adapterClass alloc] initWithDataModel:model];
    self.currentAdapter.manager = self;
    self.currentAdapter.controller = self.controller;
    [self.currentAdapter loadSplashAd];
    [self startTimer];
}

- (void)loadNativeAdWithCount:(int)count {
    self.adType = RequestAdType_Native;
    self.nativeAdCount = count;
    AdViewRolloverAdapterModel *model = [self setModelConfig];
    if (nil == model) {return;}
    self.currentAdapter = [[model.adapterClass alloc] initWithDataModel:model];
    self.currentAdapter.manager = self;
    self.currentAdapter.controller = self.controller;
    [self.currentAdapter loadNativeAdWithConunt:count];
    [self startTimer];
}

- (void)showNativeAdWithIndex:(NSUInteger)index toView:(UIView*)view {
    [self.currentAdapter showNativeAdWithIndex:index toView:view];
}

- (void)clickNativeAdWithIndex:(NSUInteger)index onView:(UIView*)view{
    [self.currentAdapter clickNativeAdWithIndex:index onView:view];
}

- (void)stopGetAd {
    [self.currentAdapter releaseAdapter];
}

- (void)loadVideoAd
{
    self.adType = RequestAdType_Video;
    AdViewRolloverAdapterModel *model = [self setModelConfig];
    if (nil == model) {return;}
    self.currentAdapter = [[model.adapterClass alloc] initWithDataModel:model];
    self.currentAdapter.manager = self;
    self.currentAdapter.controller = self.controller;
    [self.currentAdapter loadVideoAd];
    [self startTimer];
}

- (void)showVideoWithController:(UIViewController*)controller
{
    [self.currentAdapter showVideoWithController:controller];
}

#pragma mrak - help method
- (AdViewRolloverAdapterModel*)getCurrentModel {
    AdViewRolloverAdapterModel *model = [self.platArray objectAtIndex:self.currentIndex];
    return model;
}

#pragma mark - report url
- (void)reportUrlWithString:(NSString*)urlString {
    if (urlString && urlString.length) {
        urlString = [[AdViewExtTool sharedTool] replaceDefineString:urlString];
        AdViewLogDebug(@"%@",urlString);
        NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
        req.HTTPMethod = @"GET";
        [req setValue:[AdViewExtTool sharedTool].userAgent forHTTPHeaderField:@"User-Agent"];
        [NSURLConnection connectionWithRequest:req delegate:nil];
    }
}

#pragma mark - timer
- (void)rollover {
    self.currentAdapter = nil;
    [self stopTimer];
    
    switch (self.adType) {
        case RequestAdType_Banner:
            [self getBannerAd];
            break;
        case RequestAdType_Instl:
            [self loadInstlAd];
            break;
        case RequestAdType_Spread:
            [self loadSpreadAd];
            break;
        case RequestAdType_Native:
            [self loadNativeAdWithCount:self.nativeAdCount];
            break;
        default:
            break;
    }
}

- (void)nextAdapterRequestAd {
    NSString *errString = [self getCurrentModel].failurl;
    errString = [NSString stringWithFormat:@"%@&mg=%@",errString,[AdViewExtTool URLEncodedString:@"adapter no response"]];
    [self reportUrlWithString:errString];
    [self rollover];
}

- (void)startTimer {
    [self stopTimer];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(nextAdapterRequestAd) userInfo:nil repeats:NO];
}

- (void)stopTimer {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

#pragma mark - 广告相关行为方法
- (void)adapter:(AdViewRolloverAdapter*)adapter didReceiveAdView:(UIView*)view {
    [self stopTimer];
    adapter.responseCount++;
    self.canReportDisplayUrl = YES;
    if (adapter.responseCount == 1)
    {
        if(self.delegate && [self.delegate respondsToSelector:@selector(getAdSuccessToReceivedAdWithView:)])
        {
            [self.delegate getAdSuccessToReceivedAdWithView:view];
        }
        NSString *sucUrlString = [self getCurrentModel].succurl;
        [self reportUrlWithString:sucUrlString];
    }
}

- (void)adapter:(AdViewRolloverAdapter*)adapter didReceiveAdWithArray:(NSArray*)adArray {
    [self stopTimer];
    self.canReportDisplayUrl = YES;
    if (self.delegate && [self.delegate respondsToSelector:@selector(getAdSuccessToReceivedNativeAdWithArray:)]) {
        [self.delegate getAdSuccessToReceivedNativeAdWithArray:adArray];
    }
}

- (void)adapter:(AdViewRolloverAdapter*)adapter didFailAdWithError:(NSError*)error {

    NSString *errString = [self getCurrentModel].failurl;
    errString = [NSString stringWithFormat:@"%@&mg=%@",errString,[AdViewExtTool URLEncodedString:error.localizedDescription]];
    [self reportUrlWithString:errString];
    [self rollover];
}

- (void)adapter:(AdViewRolloverAdapter*)adapter displayOrClickAd:(BOOL)beDisplay {
    AdViewRolloverAdapterModel *model = [self getCurrentModel];
    NSString *reportStr;
    if (beDisplay) {
        reportStr = model.impurl;
        if (!self.canReportDisplayUrl) {
            return;
        }
    }else {
        reportStr = model.clkurl;
    }
    
    if (self.adType == RequestAdType_Banner && adapter.responseCount > 1) {
        reportStr = [NSString stringWithFormat:@"%@&sufid=%d",reportStr,adapter.responseCount - 1];
    }
    [self reportUrlWithString:reportStr];
    
    if (beDisplay) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(adViewWillShowAd)]) {
            [self.delegate adViewWillShowAd];
        }
        self.canReportDisplayUrl = NO;
    }else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(adViewWillClicked)]) {
            [self.delegate adViewWillClicked];
        }
    }
}

- (void)willPresentAdViewWithAdapter:(AdViewRolloverAdapter*)adapter {
    if (self.delegate && [self.delegate respondsToSelector:@selector(adViewWillPresentScreen)]) {
        [self.delegate adViewWillPresentScreen];
    }
}

- (void)didDismissAdViewWithAdapter:(AdViewRolloverAdapter*)adapter {
    if (self.delegate && [self.delegate respondsToSelector:@selector(adViewDidDismissScreen)]) {
        [self.delegate adViewDidDismissScreen];
    }
}

- (void)closeInstlWithAdapter:(AdViewRolloverAdapter*)adapter {
    if (self.delegate && [self.delegate respondsToSelector:@selector(adViewWillCloseInstl)]) {
        [self.delegate adViewWillCloseInstl];
    }
}

#pragma mark - video delegate
- (void)videoClosedWithAdapter:(AdViewRolloverAdapter *)adatper {
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoClosed)]) {
        [self.delegate videoClosed];
    }
}

- (void)videoPlayStartWithAdapter:(AdViewRolloverAdapter *)adatper {
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayStarted)]) {
        [self.delegate videoPlayStarted];
    }
}

- (void)didCacheVdieoWithAdapter:(AdViewRolloverAdapter *)adapter {
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoReadyToPlay)]) {
        [self.delegate videoReadyToPlay];
    }
}

- (void)videoPlayFinishedWithAdapter:(AdViewRolloverAdapter *)adatper {
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayEnded)]) {
        [self.delegate videoPlayEnded];
    }
}

@end

//
//  AdViewHelloAppDelegate.m
//  AdViewHello
//
//  Created by AdView on 10-11-24.
//  Copyright 2010 AdView. All rights reserved.
//

#import "AdViewHelloAppDelegate.h"
#import "AdViewHelloViewController.h"
#import "AdViewView.h"
#import "AdViewExtTool.h"
#import <objc/message.h>

#define AD_NUM 11

static int      gAdPlatType = 9;
static CGSize   gAdSize;
static BOOL     gTestMode = NO;

static char *gAppNames[AD_NUM] = {
	"AdDirect",
    "AdExchange",
	"SuiZong",
	"Immob",
	"InMobi",
    "Aduu",
    "WQMobile",
    "Koudai",
    "AdFill",
    "AdView",
    "AdViewRTB"
};

static char *gAppIDs[AD_NUM] =
{
    "SDK20111022530129m85is43b70r4iyc",
    "SDK20141615040237dhvcwfgbw3ea88w",
	"SDK20111022530129m85is43b70r4iyc",
	"4f0acf110cf2f1e96d8eb7ea",
	"d0638eec79904e783c4889abacc46e5c",
	"4028cbff3a6eaf57013a9b2847a004bd",
    "1C1F7F471E",
    "4c55f6cdf1f179087844bfb4665d2547",
    "SDK2014100110085937vf3muqfqoplbf",
    "SDK20191827061240r6ak2kivievp0f7", //AdViewOverseas 测试:SDK20191606040826utni417gaot5alt 正式:SDK20191028101142elckebuvuy5lczp
    "SDK20131916070901pjqdp6hdghhf34w"
};

static char *gAppPWDs[AD_NUM] = {
    nil,
    nil,
    nil,
    nil,
    nil,
    nil,
    "1FF8CA6832",
    "4265a0e46d4f447ca4c0e139fa0f00c0",
    nil,
    nil,
    nil,
};

@implementation AdViewHelloAppDelegate

#pragma mark -
#pragma mark Application lifecycle

- (void)addAdView {
	if (nil != self.adView) {
		[self.adView removeFromSuperview];
		self.adView = nil;
    }
    
    //传positionId是mrec广告,不传是普通Banner
//    self.adView = [AdViewView requestBannerSize:AdViewBannerSize_320x50 positionId:nil delegate:self];
    self.adView = [AdViewView requestBannerSize:AdViewBannerSize_300x250 positionId:@"POSID9pgkbm6lflf7" delegate:self];
    [_viewController.view addSubview:self.adView];
}

- (void)buttonTouched:(id)sender
{
    UIButton *button = (UIButton*)sender;
    if ([button.titleLabel.text isEqualToString:@"横幅"])
    {
        AdViewLogInfo(@"请求Banner");

        [self addAdView];
        [self setInfoStr:@"请求横幅"];
        [button setTitle:@"关闭横幅" forState:UIControlStateNormal];
    }
    else if ([button.titleLabel.text isEqualToString:@"关闭横幅"])
    {
        AdViewLogInfo(@"关闭Banner");

        if (nil != self.adView)
        {
            [self.adView removeFromSuperview];
            self.adView = nil;
        }
        [self setInfoStr:@"关闭横幅"];
        [button setTitle:@"横幅" forState:UIControlStateNormal];
    }
}

- (void)setStatusInfo
{
    NSString *strStatus = [NSString stringWithFormat:@"%@ %s %@",
                           gTestMode?@"test":@"real", gAppNames[gAdPlatType],
                           NSStringFromCGSize(gAdSize)];
    
    [self.viewController setUIStatusInfo:strStatus];
}

- (void)nextAdType
{
	gAdPlatType++;
	gAdPlatType%=AD_NUM;
	
    if (gAdPlatType == 9)
    {
        [self nextAdType];
    }
    
	NSString * strInfo = [NSString stringWithFormat:@"Change To Ad:%s", gAppNames[gAdPlatType]];
    [self setInfoStr:strInfo];
	
    [self setStatusInfo];
	[self addAdView];
}

- (void)nextAdSize
{
    int nHeight = (int)gAdSize.height;
    
    switch (nHeight) {
        case 50: gAdSize = ADVIEW_SIZE_480x44; break;
        case 44: gAdSize = ADVIEW_SIZE_300x250; break;
        case 250:gAdSize = ADVIEW_SIZE_480x60; break;
        case 60: gAdSize = ADVIEW_SIZE_728x90; break;
        case 90: gAdSize = ADVIEW_SIZE_320x50; break;
    }
	NSString *strInfo = [NSString stringWithFormat:@"Change To Size:%@",
                         NSStringFromCGSize(gAdSize)];
    [self setInfoStr:strInfo];
    
    [self setStatusInfo];
    [self addAdView];
}

- (void)toggleTestMode
{
    gTestMode = !gTestMode;
    
	NSString *strInfo = [NSString stringWithFormat:@"Change To TestMode:%d",gTestMode];
    [self setInfoStr:strInfo];
    [self setStatusInfo];
    [self addAdView];
}

- (void)addAdButtons
{
    CGRect startRect = [[UIScreen mainScreen] bounds];
    BOOL isLand = [AdViewExtTool getDeviceDirection];
    CGFloat width = isLand?startRect.size.height:startRect.size.width;
    CGFloat height =  isLand?startRect.size.width:startRect.size.height;
    if (isLand && width < height)
    {
        width = width + height;
        height = width - height;
        width = width - height;
    }
     CGRect rect = CGRectMake(startRect.origin.x,startRect.origin.y, width, height);
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(AdInstlButtonChange) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
  
    _adInstlButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_adInstlButton setFrame:CGRectMake(rect.size.width/3,rect.size.height/2 - 120,rect.size.width/3, 50)];
    [_adInstlButton setTitle:@"插屏" forState:UIControlStateNormal];
    [_adInstlButton addTarget:self action:@selector(adShowAdInstl) forControlEvents:UIControlEventTouchUpInside];
    
    _bannerButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_bannerButton setFrame:CGRectMake(rect.size.width/3,rect.size.height/2 - 70,rect.size.width/3, 50)];
    [_bannerButton setTitle:@"横幅" forState:UIControlStateNormal];
    [_bannerButton addTarget:self action:@selector(buttonTouched:) forControlEvents:UIControlEventTouchUpInside];

    
    [self.window.rootViewController.view addSubview:_bannerButton];
    [self.window.rootViewController.view addSubview:_adInstlButton];
}

- (void)AdInstlButtonChange
{
    CGRect startRect = [[UIScreen mainScreen] bounds];
    BOOL isLand = [AdViewExtTool getDeviceDirection];
    CGFloat width = isLand?startRect.size.height:startRect.size.width;
    CGFloat height =  isLand?startRect.size.width:startRect.size.height;
    CGFloat space = isLand?110:120;
    if (isLand && width < height) {
        width = width + height;
        height = width - height;
        width = width - height;
    }
    
    CGRect rect = CGRectMake(startRect.origin.x,startRect.origin.y, width, height);
    
    CGSize size = _adInstlButton.frame.size;
    
    if (isLand) {
        _adInstlButton.frame = CGRectMake((rect.size.width-size.width)/2,100,size.width, 50);
        _bannerButton.frame = CGRectMake(rect.size.width*2/3, 100, size.width, 50);
    }else {
        _adInstlButton.frame = CGRectMake(rect.size.width/3,rect.size.height/2-space,rect.size.width/3, 50);
        _bannerButton.frame = CGRectMake(rect.size.width/3, rect.size.height/2-space+50, rect.size.width/3, 50);
    }
    
    if(self.adView) {
        CGRect adviewRect = self.adView.frame;
        adviewRect.origin.x = (width - adviewRect.size.width)/2;
        self.adView.frame = adviewRect;
    }
}

- (void)adShowAdInstl
{
    id (* messageSend)(Class, SEL, id, int) = (id (*)(Class, SEL, id, int))objc_msgSend;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    //对外demo里不要这样调用私有API
    self.adInstl = messageSend([AdViewView class],@selector(requestAdInstlWithDelegate:withAdPlatType:),self,9);
#pragma clang diagnostic pop
}

#pragma makr - AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    gAdSize = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? ADVIEW_SIZE_728x90 : ADVIEW_SIZE_320x50;
    [self setStatusInfo];
    
    self.viewController = [[AdViewHelloViewController alloc] init];
    self.window.rootViewController = _viewController;
    
    [self addAdButtons];
    
    self.adSpread = [AdViewView requestSpreadActivityWithDelegate:self];
    return YES;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(nonnull NSURL *)url {
    return YES;
}

- (void)setInfoStr:(NSString*)info
{
    [self.viewController setUILogInfo:info];
}

- (int)configVersion
{
    return 120;
}

- (BOOL)testMode
{
    return NO;
}

-(BOOL)logMode
{
	return YES;
}

- (int)autoRefreshInterval
{
	return 30;
}

-(UIColor*) adBackgroundColor
{
    return [UIColor whiteColor];
}

-(UIColor*) adTextColor
{
    return [UIColor blackColor];
}

//- (NSString *)logoImgName
//{
//    return @"Logo";
//}

- (NSString *)appId
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *key = [defaults objectForKey:@"currentKey"];
    if (nil != key)
    {
        return key;
    }

    NSArray *keyArr = [defaults objectForKey:@"keys"];
    if (keyArr && keyArr.count)
    {
        return [keyArr firstObject];
    }
    
    NSString * appid = [NSString stringWithUTF8String:gAppIDs[gAdPlatType]];
    return appid;
}

-(NSString*)appPwd
{
    if (!gAppPWDs[gAdPlatType]) return nil;
    return [NSString stringWithUTF8String:gAppPWDs[gAdPlatType]];
}
 
- (BOOL)usingHTML5
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL htmlIsOn = [[defaults objectForKey:@"html"] boolValue];
    return htmlIsOn;
}

- (BOOL)usingCache
{
    return NO;
}

- (void)didReceivedAd:(AdViewView *)adView
{
    AdViewLogInfo(@"%s",__FUNCTION__);
    [self setInfoStr:@"didReceivedAd"];
    
    if (adView.advertType == AdViewBanner)
    {
        CGFloat fWidth = _viewController.view.frame.size.width;
        CGRect frm = adView.frame;
        frm.origin.x = (fWidth - frm.size.width) / 2;
        if ([[UIDevice currentDevice].systemVersion floatValue] >= 7)
        {
            frm.origin.y = 44;
        }
        adView.frame = frm;
    }
    else if (adView.advertType == AdViewInterstitial)
    {
        [self.adInstl showInterstitialWithRootViewController:_viewController];
    }
}

-(void)didFailToReceiveAd:(AdViewView*)adView Error:(NSError*)error
{
    AdViewLogInfo(@"%s : %@",__FUNCTION__, error);
    NSString *errStr = [NSString stringWithFormat:@"didFailToReceiveAd, For:%@", [error description]];
    [self setInfoStr:errStr];
}

- (void)adViewWillPresentScreen:(AdViewView *)adView
{
    AdViewLogInfo(@"%s",__FUNCTION__);
    [self setInfoStr:@"adViewWillPresentScreen"];
}

- (void)adViewDidFinishShow:(AdViewView *)adview
{
    AdViewLogInfo(@"%s",__FUNCTION__);
    [self setInfoStr:@"广告已经展示完毕 可以销毁"];
}

- (void)adViewDidDismissScreen:(AdViewView *)adView
{
    AdViewLogInfo(@"%s",__FUNCTION__);
    switch (adView.advertType) {
        case AdViewBanner:
            self.adView = nil;
            break;
        case AdViewSpread:
            self.adSpread = nil;
            break;
        case AdViewInterstitial:
            self.adInstl = nil;
            break;
        default:
            break;
    }
    [self setInfoStr:@"adViewDidDismissScreen"];
}

-(UIViewController*)viewControllerForShowModal
{
    return self.viewController;
}

-(float)moveCentr
{
    return 0;
}

-(float)scaleProportion
{
    return 0;
}

- (BOOL)subjectToGDPR {
    return NO;
}

- (NSString *)userConsentString {
    return nil;
}

@end

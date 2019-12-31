//
//  InstalAutoTestViewController.m
//  AdViewHello
//
//  Created by AdView on 2017/11/24.
//

#import "InstalAutoTestViewController.h"
#import <AdViewSDK/AdViewView.h>
#import <AdViewSDK/AdViewViewDelegate.h>

#define TestKey @"SDK20171604040512l8qwjuesfyiab55"

@interface InstalAutoTestViewController ()<AdViewViewDelegate>

@property (strong, nonatomic) NSTimer *autoGetAdTimer;
@property (strong, nonatomic) AdViewView *adInstl;

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wprotocol"
@implementation InstalAutoTestViewController
#pragma clang diagnostic pop

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    // Do any additional setup after loading the view.
    CGSize size = [UIScreen mainScreen].bounds.size;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, size.width, 60)];
    label.text = @"该页面用于测试自动跳转插屏广告，启动后自动请求插屏广告以及移除广告，时间间隔为10秒";
    label.numberOfLines = 3;
    label.textColor = [UIColor lightGrayColor];
    [self.view addSubview:label];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setTitle:@"启动测试" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(getInstalAd) forControlEvents:UIControlEventTouchUpInside];
    button.frame = CGRectMake((size.width - 80)/2, 150, 80, 40);
    [self.view addSubview:button];
    
    UIButton *button1 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button1 setTitle:@"停止测试" forState:UIControlStateNormal];
    [button1 addTarget:self action:@selector(stop) forControlEvents:UIControlEventTouchUpInside];
    button1.frame = CGRectMake((size.width - 80)/2, 350, 80, 40);
    [self.view addSubview:button1];
}

- (void)stop {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)getInstalAd
{
    if ([self.adInstl superview])
    {
        [self.adInstl removeFromSuperview];
        self.adInstl.delegate = nil;
        self.adInstl = nil;
    }
    self.adInstl = [AdViewView requestAdInterstitialWithDelegate:self];
}

- (void)removeAdinstl {
    if ([self.adInstl superview]) {
        [self.adInstl removeFromSuperview];
        self.adInstl.delegate = nil;
        self.adInstl = nil;
    }
    [NSTimer scheduledTimerWithTimeInterval:15 target:self selector:@selector(getInstalAd) userInfo:nil repeats:NO];
}

- (void)rollOver
{
    [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(removeAdinstl) userInfo:nil repeats:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - AdViewViewDelegate
- (BOOL)testMode {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL testIsOn = [[defaults objectForKey:USE_TEST_SERVER_KEY] boolValue];
    return testIsOn;
}

- (BOOL)usingHTML5 {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL htmlIsOn = [[defaults objectForKey:@"html"] boolValue];
    return htmlIsOn;
}

-(void)didReceivedAd:(AdViewView *)adView
{
    [self.adInstl showInterstitialWithRootViewController:self];
    [self rollOver];
}

-(void)didFailToReceiveAd:(AdViewView*)adView Error:(NSError*)error
{
    [self removeAdinstl];
}

- (NSString *)appId {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *key = [defaults objectForKey:@"currentKey"];
    if (nil != key) {
        return key;
    }
    
    NSArray *keyArr = [defaults objectForKey:@"keys"];
    if (keyArr && keyArr.count) {
        return [keyArr firstObject];
    }
    
    return TestKey;
}
@end

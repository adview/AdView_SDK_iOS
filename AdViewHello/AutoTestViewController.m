//
//  AutoTestViewController.m
//  AdViewHello
//
//  Created by AdView on 2017/6/28.
//
//

#import "AutoTestViewController.h"
#import "AdViewView.h"
#import "AdViewViewDelegate.h"
#import "AdViewExtTool.h"
#import "AdInfoCell.h"

typedef enum : NSUInteger {
    AD_Banner,
    AD_Instal,
    AD_Spread,
} AD_Type;

@protocol TestSettingViewDelegate <NSObject>

- (void)startAutoTest;

@end

@interface TestSettingView : UIView
@property (nonatomic, assign) int maxReponseCount; // 某个渠道请求广告出现该次数后，自动测试结束
@property (nonatomic, assign) AD_Type type;
@property (nonatomic, weak) id<TestSettingViewDelegate> delegate;
@property (nonatomic, strong) UILabel *numLabel;
@end

@implementation TestSettingView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.maxReponseCount = 2;
        [self initSubviews];
    }
    return self;
}

- (void)initSubviews {
    UISegmentedControl *control = [[UISegmentedControl alloc] initWithItems:@[@"广告条",@"插屏",@"开屏"]];
    [control addTarget:self action:@selector(myAction:) forControlEvents:UIControlEventValueChanged];
    control.tag = 111;
    [self addSubview:control];
    
    UIStepper *stepper = [[UIStepper alloc] init];
    stepper.minimumValue = 2;
    stepper.maximumValue = 10;
    stepper.stepValue = 1;
    [stepper addTarget:self action:@selector(stepperAction:) forControlEvents:UIControlEventValueChanged];
    stepper.tag = 222;
    [self addSubview:stepper];
    
    self.numLabel = [[UILabel alloc] init];
    self.numLabel.text = @"次数：2";
    self.numLabel.textAlignment = NSTextAlignmentCenter;
    self.numLabel.textColor = [UIColor grayColor];
    [self addSubview:self.numLabel];
    
    UILabel *label = [[UILabel alloc] init];
    label.text = @"当相同渠道出现以下次数的时候，自动测试结束";
    label.textColor = [UIColor lightGrayColor];
    label.font = [UIFont systemFontOfSize:13];
    label.textAlignment = NSTextAlignmentCenter;
    label.tag = 333;
    [self addSubview:label];
    
    UIButton *starButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [starButton setTitle:@"启动测试" forState:UIControlStateNormal];
    [starButton addTarget:self action:@selector(startAction:) forControlEvents:UIControlEventTouchUpInside];
    starButton.tag = 444;
    [self addSubview:starButton];
}

- (void)startAction:(id)sender {
    self.hidden = YES;
    if (self.delegate && [self.delegate respondsToSelector:@selector(startAutoTest)]) {
        [self.delegate startAutoTest];
    }
}

- (void)stepperAction:(id)sender {
    UIStepper *stepper = (UIStepper*)sender;
    self.maxReponseCount = stepper.value;
    self.numLabel.text = [NSString stringWithFormat:@"次数：%d",self.maxReponseCount];
}

- (void)myAction:(id)sender {
    UISegmentedControl *control = (UISegmentedControl*)sender;
    self.type = control.selectedSegmentIndex;
}

- (void)layoutSubviews {
    CGSize size = self.frame.size;
    UISegmentedControl *control = [self viewWithTag:111];
    UIStepper *stepper = [self viewWithTag:222];
    UIButton *button = [self viewWithTag:444];
    UILabel *label = [self viewWithTag:333];
    
    CGFloat space = size.width/10.0f;
    CGFloat height = 30;
    CGFloat width = size.width - space*2;
    
    control.frame = CGRectMake(space, space, (size.width - space*2), height);
    
    label.frame = CGRectMake(space, control.frame.origin.y + control.frame.size.height + space, width, height);
    self.numLabel.frame = CGRectMake(space, control.frame.origin.y + control.frame.size.height + space + height, width/2, height);
    stepper.frame = CGRectMake(space + width / 2, control.frame.origin.y + control.frame.size.height + space + height, width / 2, height);
    
    button.frame = CGRectMake(space + width / 4, stepper.frame.origin.y + height + space, width/2, height);
}

@end

@interface AutoTestViewController ()<TestSettingViewDelegate,UITableViewDelegate,UITableViewDataSource,AdViewViewDelegate>

@property (nonatomic, strong) TestSettingView *tsView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, assign) AD_Type adType;
@property (nonatomic, assign) int maxNumber;
@property (nonatomic, strong) NSMutableArray *infoArrayy;
@property (nonatomic, strong) AdViewView *adView;
@property (nonatomic, strong) NSMutableDictionary *dict;
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation AutoTestViewController

- (NSMutableArray *)infoArrayy {
    if (nil == _infoArrayy) {
        self.infoArrayy = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return _infoArrayy;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIImageView *view = [self.navigationController.navigationBar viewWithTag:10000];
    view.alpha = 0;
    
    CGFloat width = [UIScreen mainScreen].bounds.size.width - 26;
    self.tsView = [[TestSettingView alloc] initWithFrame:CGRectMake(13, 200, width, (width*2/5 + 120))];
    self.tsView.delegate = self;
    [self.view addSubview:self.tsView];
    self.view.backgroundColor = [UIColor whiteColor];
    [self addStopButton];
}

- (void)addStopButton {
    UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    rightButton.frame = CGRectMake(0, 0, 50, 25);
    [rightButton setTitleColor:[UIColor colorWithRed:0 green:0.5 blue:0.98 alpha:1] forState:UIControlStateNormal];
    [rightButton setTitle:@"停止" forState:UIControlStateNormal];
    [rightButton addTarget:self action:@selector(stopAction) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithCustomView:rightButton];
    self.navigationItem.rightBarButtonItem = rightItem;
}

- (void)addTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, ScreenWidth, ScreenHeight - 64) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self setExtraCellLineHidden:self.tableView];
    [self.view addSubview:_tableView];
}

- (void)setExtraCellLineHidden: (UITableView *)tableView
{
    UIView *view = [UIView new];
    view.backgroundColor = [UIColor clearColor];
    [tableView setTableFooterView:view];
}

#pragma mark tableview delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//    if (section == 0) {
//        return 0;
//    }
    return self.infoArrayy.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *reusableString = @"cell";
    UITableViewCellStyle style = UITableViewCellStyleDefault;
    
    AdInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:reusableString];
    if (nil == cell) {
        cell = [[AdInfoCell alloc] initWithStyle:style reuseIdentifier:reusableString];
    }
    
    [cell showInfoWithDict:[self.infoArrayy objectAtIndex:indexPath.row]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 30;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
//    if (section == 1) {
//        return 0;
//    }
    return 30.f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.1f;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSArray *infoArr = @[@"src",@"成功",@"失败",@"备注"];
    CGFloat space = 5;
    CGFloat width = 60;
    CGFloat lastWidth = (ScreenWidth - space*(infoArr.count+1)) - width*(infoArr.count-1);

    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor whiteColor];
    for (int i = 0; i < infoArr.count; i++) {
        CGFloat w = width;
        if (i == infoArr.count - 1) {
            w = lastWidth;
        }
        CGRect rect = CGRectMake(space + (width + space)*i, 0, w, 30);

        UILabel *label = [[UILabel alloc] initWithFrame:rect];
        label.text = [infoArr objectAtIndex:i];
        label.textAlignment = NSTextAlignmentCenter;
        [view addSubview:label];
    }
    return view;
}

#pragma mark - TestSettingViewDelegate
- (void)startAutoTest {
    [self addTableView];
    self.adType = self.tsView.type;
    self.maxNumber = self.tsView.maxReponseCount;
    [AdViewExtTool sharedTool].autoTestFunction = YES; // 开启自动测试用于存储数据
    [self startTest];
}

#pragma mark - auto test
- (void)stopAction {
    [self.adView removeFromSuperview];
    self.adView.delegate = nil;
    self.adView = nil;
    self.timer = nil;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"自动测试结束" message:@"" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [alert show];
}

- (void)startTest
{
    [self.adView removeFromSuperview];
    self.adView.delegate = nil;
    self.adView = nil;
    self.timer = nil;
    switch (self.adType)
    {
        case AD_Banner:
            self.adView = [AdViewView requestBannerSize:AdViewBannerSize_320x50 positionId:nil delegate:self];
            [self.view addSubview:self.adView];
            break;
        case AD_Instal:
        {
            self.adView = [AdViewView requestAdInterstitialWithDelegate:self];
            
            __weak typeof(self) weakSelf = self;
            self.timer = [NSTimer scheduledTimerWithTimeInterval:15 repeats:NO block:^(NSTimer * _Nonnull timer) {
                __strong typeof (weakSelf) strongSelf = weakSelf;
                [strongSelf startTest];
            }];
            break;
        }
        case AD_Spread:
        {
            self.adView = [AdViewView requestSpreadActivityWithDelegate:self];
            
            __weak typeof(self) weakSelf = self;
            self.timer = [NSTimer scheduledTimerWithTimeInterval:15 repeats:NO block:^(NSTimer * _Nonnull timer) {
                __strong typeof (weakSelf) strongSelf = weakSelf;
                [strongSelf startTest];
            }];
            break;
        }
    }
}

- (void)checkCanStop {
    int num = 0;
    if ([[self.dict objectForKey:@"1"] isEqualToString:@"未知"]) {
        return;
    }
    for (NSDictionary *dict in self.infoArrayy) {
        if ([[self.dict objectForKey:@"1"] isEqualToString:[dict objectForKey:@"1"]]) {
            num ++;
        }
    }
    if (num >= self.maxNumber) {
        [self stopAction];
    }
}

- (void)requestOnceAdEnd {
    if (nil == _dict) {
        self.dict = [[NSMutableDictionary alloc] init];
    }
    NSString *str = [AdViewExtTool sharedTool].srcString;
    if ([str isEqualToString:@"-1"]) {
        str = @"未知";
    }
    [self.dict setObject:str forKey:@"1"];
    NSDictionary *dict = [self.dict copy];
    [self.infoArrayy addObject:dict];
    [self.tableView reloadData];
    [self checkCanStop];
}

#pragma mark - compviewdelegate
- (BOOL)testMode
{
    return NO;
}

- (BOOL)logMode
{
    return YES;
}

- (int)autoRefreshInterval
{
    return 15;
}

- (NSString *)logoImgName{
    return @"Logo";
}

- (NSString*)appId
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *key = [defaults objectForKey:@"currentKey"];
    if (nil != key) {
        return key;
    }
    
    NSArray *keyArr = [defaults objectForKey:@"keys"];
    if (keyArr && keyArr.count) {
        return [keyArr firstObject];
    }
    
    return @"SDK20111022530129m85is43b70r4iyc";
}

- (BOOL)usingHTML5 {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL htmlIsOn = [[defaults objectForKey:@"html"] boolValue];
    return htmlIsOn;
}

- (BOOL)usingCache {
    return NO;
}

- (void)didReceivedAd:(AdViewView *)adView
{
    if (nil == _dict)
    {
        self.dict = [[NSMutableDictionary alloc] init];
    }
    
    [self.dict setObject:@"1" forKey:@"2"];
    [self.dict setObject:@"0" forKey:@"3"];
    [self.dict setObject:@"--" forKey:@"4"];
    
    if (self.adType == AD_Instal)
    {
        [self.adView showInterstitialWithRootViewController:self];
    }
    else if (self.adType == AD_Banner)
    {
        CGRect frm = self.adView.frame;
        frm.origin.x = (ScreenWidth - frm.size.width) / 2;
        frm.origin.y = (ScreenHeight - frm.size.height) / 2;
        self.adView.frame = frm;
    }
    [self requestOnceAdEnd];
}

-(void)didFailToReceiveAd:(AdViewView*)adView Error:(NSError*)error {
    NSString *errStr = [error domain];

    if (nil == _dict) {
        self.dict = [[NSMutableDictionary alloc] init];
    }
    
    [self.dict setObject:@"1" forKey:@"3"];
    [self.dict setObject:@"0" forKey:@"2"];
    [self.dict setObject:errStr forKey:@"4"];
    [self requestOnceAdEnd];
}

- (void)adViewWillPresentScreen:(AdViewView *)adView {
}

- (void)adViewDidDismissScreen:(AdViewView *)adView {

}

- (void)adInterstitialDidDismissScreen:(AdViewView *)adInstl
{
    
}

-(UIViewController*)viewControllerForShowModal
{
    return self;
}

- (BOOL)subjectToGDPR {
    return NO;
}

- (NSString *)userConsentString {
    return nil;
}
@end

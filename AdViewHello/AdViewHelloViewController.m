//
//  AdViewHelloViewController.m
//  AdViewHello
//
//  Created by AdView on 10-11-24.
//  Copyright 2010 AdView. All rights reserved.
//

#import "AdViewHelloViewController.h"
#import "AdViewHelloAppDelegate.h"
#import "AdViewNativeAd.h"
#import "AdViewExtTool.h"
#import "SettingViewController.h"
#import "InstalAutoTestViewController.h"
#import "VideoViewController.h"

//native广告key
#define APP_KEY @"SDK20191028101142elckebuvuy5lczp"
#define POSITION_ID @"POSID3j2hw0mkldfb"

@interface SettingView : UIView<UIPickerViewDataSource,UIPickerViewDelegate,UITextFieldDelegate> {
    UIPickerView *keyPickerView;
    UISwitch *testSwitch;
    UISwitch *htmlSwitch;
    UILabel *label1;
    UILabel *label2;
    NSMutableDictionary *infoDict;
}
@property (strong, nonatomic) NSMutableDictionary *infoDict;
@end

@implementation SettingView
@synthesize infoDict;
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor lightGrayColor];
        self.layer.cornerRadius = 5;
        
        infoDict = [[NSMutableDictionary alloc] init];
        
        keyPickerView = [[UIPickerView alloc] init];
        keyPickerView.delegate = self;
        keyPickerView.dataSource = self;
        [self addSubview:keyPickerView];
        
        label1 = [[UILabel alloc] init];
        label1.text = @"测试服务器:";
        label1.textAlignment = NSTextAlignmentRight;
        [self addSubview:label1];
        
        label2 = [[UILabel alloc] init];
        label2.text = @"HTML5:";
        label2.textAlignment = NSTextAlignmentRight;
        [self addSubview:label2];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        BOOL testIsOn = [[defaults objectForKey:USE_TEST_SERVER_KEY] boolValue];
        BOOL htmlIsOn = [[defaults objectForKey:@"html"] boolValue];
        
        testSwitch = [[UISwitch alloc] init];
        [self addSubview:testSwitch];
        [testSwitch addTarget:self action:@selector(testSwitchAction) forControlEvents:UIControlEventValueChanged];
        [testSwitch setOn:testIsOn];
        
        htmlSwitch = [[UISwitch alloc] init];
        [self addSubview:htmlSwitch];
        [htmlSwitch addTarget:self action:@selector(htmlSwitchAction) forControlEvents:UIControlEventValueChanged];
        [htmlSwitch setOn:htmlIsOn];
    }
    return self;
}

- (void)testSwitchAction {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSString stringWithFormat:@"%d",testSwitch.on] forKey:USE_TEST_SERVER_KEY];
}

- (void)htmlSwitchAction {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSString stringWithFormat:@"%d",htmlSwitch.on] forKey:@"html"];
}

- (void)layoutSubviews {
    CGSize size = self.frame.size;
    CGFloat offSet = 3.5;
    keyPickerView.frame = CGRectMake( 0, 0, size.width, size.height/2);
    
    CGFloat height = size.height - keyPickerView.frame.size.height;
    
    label1.frame = CGRectMake(0, keyPickerView.frame.size.height + height/9, size.width/2 - offSet, height/3);
    testSwitch.frame = CGRectMake( label1.frame.size.width + offSet, label1.frame.origin.y + offSet, size.width/2, height/3);
    
    label2.frame = CGRectMake(0, label1.frame.origin.y + label1.frame.size.height + height/9, size.width/2 - offSet, height/3);
    htmlSwitch.frame = CGRectMake( label2.frame.size.width + offSet, label2.frame.origin.y + offSet, size.width/2, height/3);
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *arr = [defaults objectForKey:@"keys"];
    if (arr && arr.count) {
        return arr.count + 1;
    }
    return 1;
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    CGSize size = self.frame.size;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake( 0, 0, size.width, size.height/3)];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *arr = [defaults objectForKey:@"keys"];
    if (row == [pickerView numberOfRowsInComponent:component] - 1) {
        label.text = @"添加key";
    }else
        label.text = [arr objectAtIndex:row];
    label.textAlignment = NSTextAlignmentCenter;
    return label;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    UILabel *label = (UILabel*)[pickerView viewForRow:row forComponent:component];
    if ([label.text isEqualToString:@"添加key"]) {
        UITextField *textField = [[UITextField alloc] initWithFrame:label.frame];
        [self addSubview:textField];
        textField.backgroundColor = [UIColor whiteColor];
        textField.delegate = self;
        textField.placeholder = @"请输入需要的key";
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.returnKeyType = UIReturnKeyDone;
    }else {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:label.text forKey:@"currentKey"];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    if (textField.text) {
        NSLog(@"text:%@",textField.text);
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSArray *keyArr = [defaults objectForKey:@"keys"];
        NSMutableArray *arr = [NSMutableArray arrayWithArray:keyArr];
        if (!arr) {
            arr = [[NSMutableArray alloc] init];
        }
        
        for (NSString *string in arr) {
            if ([string isEqualToString:textField.text])
                [arr removeObject:string];
        }
        
        [arr addObject:textField.text];
        keyArr = [NSArray arrayWithArray:arr];
        [defaults setObject:keyArr forKey:@"keys"];

        [keyPickerView reloadAllComponents];
    }
    [textField removeFromSuperview];
    return YES;
}

@end

@interface AdViewHelloViewController()<AdViewNativeAdDelegate,UITextViewDelegate>{
    AdViewNativeAd *nativeAd;
    NSArray *adArray;
    UIButton *setBtn;
}

@property (nonatomic, strong) AdViewNativeAd *nativeAd;
@property (strong, nonatomic) UIButton *setBtn;

@end

@implementation AdViewHelloViewController
@synthesize nativeAd;
@synthesize setBtn;
@synthesize setDict;

- (void)viewDidLayoutSubviews
{
    CGSize size = [UIScreen mainScreen].bounds.size;
    self.setBtn.frame = CGRectMake((size.width - 80), size.height-40, 80, 40);
    
    UIButton *btn = [self.view viewWithTag:124];
    btn.frame = CGRectMake(0, size.height - 40, 80, 40);
}

//如果需要开屏，则承载开屏的controller最好隐藏状态栏。不然很丑
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    self.setBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.setBtn setTitle:@"设置" forState:UIControlStateNormal];
    [self.setBtn addTarget:self action:@selector(setSomething) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.setBtn];
    
    CGSize size = [UIScreen mainScreen].bounds.size;
    
    UIButton *videoBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    videoBtn.frame = CGRectMake((size.width - 80) / 2, size.height - 40, 80, 40);
    [videoBtn setTitle:@"视频" forState:UIControlStateNormal];
    [videoBtn addTarget:self action:@selector(presentVideoController) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:videoBtn];
    
    UIButton *autoTestInstal = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    autoTestInstal.frame = CGRectMake(0, size.height - 40, 100, 40);
    [autoTestInstal setTitle:@"自动测试插屏" forState:UIControlStateNormal];
    [autoTestInstal addTarget:self action:@selector(autoTestInstal) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:autoTestInstal];
    
    CGRect startRect = [[UIScreen mainScreen] bounds];
    BOOL isLand = [AdViewExtTool getDeviceDirection];
    CGFloat width = isLand?startRect.size.height:startRect.size.width;
    CGFloat height =  isLand?startRect.size.width:startRect.size.height;
    if (isLand && width < height) {
        width = width + height;
        height = width - height;
        width = width - height;
    }
    CGRect rect = CGRectMake(startRect.origin.x,startRect.origin.y, width, height);
    UIButton* button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setFrame:CGRectMake(rect.size.width/3,100,rect.size.width/3, 50)];
    [button setTitle:@"原生" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(requestNativeAd) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)presentVideoController {
    VideoViewController *vvc = [[VideoViewController alloc] init];
    vvc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:vvc animated:YES completion:nil];
}

- (void)setSomething {
    SettingViewController *svc = [[SettingViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:svc];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)autoTestInstal {
    InstalAutoTestViewController *controller = [[InstalAutoTestViewController alloc] init];
    [self presentViewController:controller animated:YES completion:nil];
}

#pragma mark - -----

- (void)requestNativeAd {
    self.nativeAd = [[AdViewNativeAd alloc] initWithAppKey:APP_KEY positionID:POSITION_ID];
    self.nativeAd.delegate = self;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL testIsOn = [[defaults objectForKey:USE_TEST_SERVER_KEY] boolValue];
    if (testIsOn)
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        [self.nativeAd performSelector:@selector(setTestMode)];
#pragma clang diagnostic pop
    }
    
    self.nativeAd.controller = self;
    [self.nativeAd loadNativeAdWithCount:1];
}

- (void)setUILogInfo:(NSString*)str
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UILabel *label = (UILabel*)[self.view viewWithTag:31];
        [label setText:str];
    });
}

- (void)setUIStatusInfo:(NSString*)str {
    UILabel *label = (UILabel*)[self.view viewWithTag:30];
    [label setText:str];
}

- (IBAction)nextAdAction:(id)sender
{
	AdViewHelloAppDelegate *delegate = (AdViewHelloAppDelegate*)
	[[UIApplication sharedApplication] delegate];
	
	[delegate nextAdType];
}

- (IBAction)nextSizeAction:(id)sender
{
	AdViewHelloAppDelegate *delegate = (AdViewHelloAppDelegate*)
	[[UIApplication sharedApplication] delegate];
	
	[delegate nextAdSize];
}

- (IBAction)toggleTestAction:(id)sender
{
	AdViewHelloAppDelegate *delegate = (AdViewHelloAppDelegate*)[[UIApplication sharedApplication] delegate];
	[delegate toggleTestMode];
}

#ifdef __IPHONE_6_0

- (BOOL)shouldAutorotate{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

#endif

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {}
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {}
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    SettingView *setView;
    for (UIView *view in [self.view subviews]) {
        if (view.tag == 2000) {
            setView = (SettingView*)view;
        }
    }

    if (!CGRectContainsPoint(setView.frame, [touch locationInView:self.view])) {
        self.setDict = setView.infoDict;
        [setView removeFromSuperview];
    }
}

// banner 类型原生
static NSString * optOutCilickURL = nil;
- (void)showNativeAd:(NSArray*)nativeDataArray {
    NSLog(@"show native ad");
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGFloat space = 5;
    
    UIView *bgView = [[UIView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:bgView];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeBgView:)];
    [bgView addGestureRecognizer:tapGesture];
    bgView.backgroundColor = [UIColor lightGrayColor];
    
    AdViewNativeData *data = [nativeDataArray firstObject];
    
    NSString *iconUrlStr = [data.adProperties objectForKey:@"iconUrlString"];
    UIImage *iconImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:iconUrlStr]]];

    CGSize iconSize = iconImage.size;
    if (iconSize.width > 60) {
        iconSize = CGSizeMake(60, 60);
    }
    
    UIImageView *iconImgView = [[UIImageView alloc] initWithImage:iconImage];
    if (iconImage) {
        iconImgView.frame = CGRectMake(0, 0, iconSize.width, iconSize.height);
    }else
        iconImgView.frame = CGRectMake(0, 0, 0, 0);
    
    //应用名字
    NSString *title = [data.adProperties objectForKey:@"title"];
    UILabel *titleLabel = [[UILabel alloc] init];
    if (title && title.length > 0) {
        titleLabel.frame = CGRectMake(iconImgView.frame.size.width + iconImgView.frame.origin.x + space, 0, screenSize.width - iconImgView.frame.size.width - space, (iconImgView.frame.size.height==0)?60:iconImgView.frame.size.height/2);
        titleLabel.text = title;
        titleLabel.backgroundColor = [UIColor whiteColor];
    }
    
    NSString *desc = [data.adProperties objectForKey:@"desc"];
    UILabel *descLabel = [[UILabel alloc] init];
    if (desc && desc.length > 0) {
        descLabel.frame = CGRectMake(titleLabel.frame.origin.x, titleLabel.frame.origin.y+titleLabel.frame.size.height, titleLabel.frame.size.width, titleLabel.frame.size.height);
        descLabel.text = desc;
            descLabel.backgroundColor = [UIColor whiteColor];
    }
    
    NSString *optOutIconURL = data.adProperties[@"pimage"];
    optOutCilickURL = data.adProperties[@"pclick"];
    UIImageView *optOutIcon = [[UIImageView alloc] initWithImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:optOutIconURL]]]];
    optOutIcon.frame = CGRectMake(titleLabel.frame.origin.x + titleLabel.frame.size.width - 30, 0, 30, 30);
    optOutIcon.layer.borderWidth = 1.0;
    optOutIcon.userInteractionEnabled = YES;
    UITapGestureRecognizer *optOutIconTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(optOutIconClick:)];
    [optOutIcon addGestureRecognizer:optOutIconTap];
    
    //image
    NSMutableArray *imgsArr = [[NSMutableArray alloc] init];
    NSArray *imgArr = [data.adProperties objectForKey:@"imageList"];
    if (imgArr && imgArr.count) {
        for (NSString *urlStr in imgArr) {
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:urlStr]]];
            if (image) {
                [imgsArr addObject:image];
            }
        }
    }else {
        NSString *imageString = [data.adProperties objectForKey:@"imageUrlString"];
        UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageString]]];
        if (image) {
            [imgsArr addObject:image];
        }
    }
    
    UIView *view = [[UIView alloc] init];
    NSMutableArray * friendlyObstructionArray = [NSMutableArray new];
    
    CGSize imageSize = CGSizeMake(0, 0);
    if (imgsArr && imgsArr.count) {
        CGFloat space = 2;
        CGFloat width = (screenSize.width - (imgsArr.count - 1) * space) / imgsArr.count;
        UIImage *image1 = [imgsArr firstObject];
        CGFloat height = width*image1.size.height/image1.size.width;
        for (int i = 0; i < imgsArr.count; i++) {
            UIImage *image = [imgsArr objectAtIndex:i];
            UIImageView *imgView = [[UIImageView alloc] initWithImage:image];
            CGFloat y = (iconImgView.frame.size.height > 0) ? iconImgView.frame.size.height : (titleLabel.frame.size.height - descLabel.frame.size.height) ;
            imgView.frame = CGRectMake(i * (width + space), y, width, height);
            [view addSubview:imgView];
            [friendlyObstructionArray addObject:imgView];
        }
        imageSize = CGSizeMake(width, height);
    }
    
    CGFloat y = (screenSize.height - imageSize.height - titleLabel.frame.size.height - descLabel.frame.size.height)/2;
    view.frame = CGRectMake(0, y, screenSize.width, imageSize.height+titleLabel.frame.size.height + descLabel.frame.size.height);
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(click)];
    [view addGestureRecognizer:tap];
    view.layer.cornerRadius = 3.0;
    
    [view addSubview:titleLabel];
    [view addSubview:descLabel];
    [view addSubview:iconImgView];
    [view addSubview:optOutIcon];
    
    [friendlyObstructionArray addObject:titleLabel];
    [friendlyObstructionArray addObject:descLabel];
    [friendlyObstructionArray addObject:iconImage];
    [friendlyObstructionArray addObject:optOutIcon];
    
    NSLog(@"already show native ad");
    [nativeAd showNativeAdWithData:[nativeDataArray firstObject]
          friendlyObstructionArray:friendlyObstructionArray
                            onView:bgView];
    [bgView addSubview:view];
}

- (void)closeBgView:(UITapGestureRecognizer *)sender {
    UIView *view = sender.view;
    [view removeFromSuperview];
    self.nativeAd = nil;
}

- (void)click {
    [nativeAd clickNativeAdWithData:[adArray firstObject] withClickPoint:CGPointMake(100, 100) onView:nil];
}

- (void)optOutIconClick:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:optOutCilickURL]];
}

#pragma mark - nativeAd delegate
- (void)adViewNativeAdSuccessToLoadAd:(AdViewNativeAd*)adViewNativeAd NativeData:(NSArray*)nativeDataArray {
    adArray = nativeDataArray;
    [self showNativeAd:nativeDataArray];
    for (AdViewNativeData *data in nativeDataArray) {
        NSLog(@"%@\n%@",(NSString*)[data performSelector:@selector(nativeAdId)],data.adProperties);
    }
}

- (void)adViewNativeAdFailToLoadAd:(AdViewNativeAd*)adViewNativeAd WithError:(NSError*)error {
    NSLog(@"%@",error.domain);
}

- (void)adViewNativeAdWillShowPresent {
    NSLog(@"native ad will show present");
}

- (void)adViewNativeAdClosed {
    NSLog(@"native ad did closed");
}

- (void)adViewNativeAdResignActive {
    NSLog(@"app resign active");
}

- (BOOL)subjectToGDPR {
    return NO;
}

- (NSString *)userConsentString {
    return nil;
}
@end

//
//  VideoViewController.m
//  AdViewHello
//
//  Created by AdView on 2018/8/6.
//

#import "VideoViewController.h"
#import <AdViewSDK/AdViewVideo.h>
#import <MediaPlayer/MediaPlayer.h>
#import "AdViewVastFileHandle.h"

@interface VideoViewController ()<AdViewVideoDelegate,UITextFieldDelegate> {
    MPMoviePlayerController *mp;
    NSString *clickUrl;
}

@property (nonatomic, strong) AdViewVideo * video;
@property (nonatomic, strong) AdViewVideo * previewVideo;
@property (nonatomic, strong) UITextView  * infoTextView;
@property (nonatomic, assign) UIInterfaceOrientation ori;
@property (nonatomic, assign) CGFloat leftSpace;
@property (nonatomic, assign) CGFloat topSpace;
@property (nonatomic, assign) BOOL autoC;           //自动关闭
@property (nonatomic, strong) UIColor *videoColor;

@end

@implementation VideoViewController
@synthesize video;
@synthesize previewVideo;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    CGSize size = [UIScreen mainScreen].bounds.size;
    CGFloat space = 40;
    CGFloat btnWidth = 100;
    CGFloat btnHeight = 80;
    
    UIButton *playButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    playButton.frame = CGRectMake((size.width - btnWidth*2 - space) / 2, 40, btnWidth, btnHeight);
    [playButton addTarget:self action:@selector(jump:) forControlEvents:UIControlEventTouchUpInside];
    [playButton setTitle:@"插屏视频" forState:UIControlStateNormal];
    playButton.tag = 1001;
    [self.view addSubview:playButton];
    
    UIButton *instlButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    instlButton.frame = CGRectMake(playButton.frame.origin.x + space + btnWidth, 40, btnWidth, btnHeight);
    [instlButton addTarget:self action:@selector(jump:) forControlEvents:UIControlEventTouchUpInside];
    [instlButton setTitle:@"贴片视频" forState:UIControlStateNormal];
    instlButton.tag = 1002;
    [self.view addSubview:instlButton];
    
    NSArray *labelText = @[@"背景色",@"方向",@"间隙",@"自动关闭"];
    CGFloat lHeight = 50;
    CGFloat textSpace = 60;
    CGFloat y = instlButton.frame.origin.y + btnHeight;
    
    for (int i = 0; i < labelText.count; i++) {
        int a = i;
        if (a == 3) {
            a = 2;
        }
        UILabel *bgLabel = [[UILabel alloc] initWithFrame:CGRectMake(20 + i/3 * (size.width/2), y + 10 + a*(textSpace + lHeight), size.width - 50, lHeight)];
        bgLabel.textColor = [UIColor blackColor];
        bgLabel.text = [labelText objectAtIndex:i];
        [self.view addSubview:bgLabel];
    }
    
    y += lHeight + 15;
    CGFloat colorW = 80;
    CGFloat colorS = (size.width - colorW*4)/5;
    
    NSArray *colorArr = @[[UIColor blackColor],[UIColor orangeColor],[UIColor lightGrayColor],[UIColor purpleColor]];
    for (int i = 0; i < 4; i++) {
        UIButton *colorView = [UIButton buttonWithType:UIButtonTypeCustom];
        colorView.frame = CGRectMake(colorS + i*(colorW+colorS), y, colorW, lHeight);
        colorView.backgroundColor = [colorArr objectAtIndex:i];
        [colorView addTarget:self action:@selector(setVideoNewColor:) forControlEvents:UIControlEventTouchUpInside];
        colorView.tag = i+232;
        [self.view addSubview:colorView];
    }
    
    y += lHeight*2 + 15;
    NSArray *oriArr = @[@"上",@"下",@"左",@"右"];
    for (int i = 0; i < 4; i++) {
        UIButton *colorView = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        colorView.frame = CGRectMake(colorS + i*(colorW+colorS), y, colorW, lHeight);
        [colorView setTitle:[oriArr objectAtIndex:i] forState:UIControlStateNormal];
        [colorView setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [colorView setBackgroundColor:[UIColor lightGrayColor]];
        [colorView addTarget:self action:@selector(setVideoOrientation:) forControlEvents:UIControlEventTouchUpInside];
        colorView.tag = i+123;
        [self.view addSubview:colorView];
    }
    
    y += lHeight*2;
    
    UILabel *label = [[UILabel alloc] init];
    label.frame = CGRectMake(10, y - 10, 80, 40);
    label.textAlignment = NSTextAlignmentRight;
    label.text = @"leftGap:";
    [self.view addSubview:label];
    
    UITextField *left = [[UITextField alloc] initWithFrame:CGRectMake(90, y-10, 80, 40)];
    left.placeholder = @"0";
    left.borderStyle = UITextBorderStyleRoundedRect;
    left.clearsOnBeginEditing = YES;
    left.keyboardType = UIKeyboardTypeNumberPad;
    left.delegate = self;
    left.tag = 987;
    [self.view addSubview:left];
    
    UILabel *topLabel = [[UILabel alloc] init];
    topLabel.frame = CGRectMake(10, y + 30, 80, 40);
    topLabel.textAlignment = NSTextAlignmentRight;
    topLabel.text = @"topGap:";
    [self.view addSubview:topLabel];
    
    UITextField *top = [[UITextField alloc] initWithFrame:CGRectMake(90, y+30, 80, 40)];
    top.placeholder = @"0";
    top.borderStyle = UITextBorderStyleRoundedRect;
    top.clearsOnBeginEditing = YES;
    top.keyboardType = UIKeyboardTypeNumberPad;
    top.delegate = self;
    top.tag = 988;
    [self.view addSubview:top];
    
    
    UISwitch *autoSwitch = [[UISwitch alloc] init];
    [self.view addSubview:autoSwitch];
    [autoSwitch addTarget:self action:@selector(switchAction) forControlEvents:UIControlEventValueChanged];
    autoSwitch.tag = 574;
    autoSwitch.frame = CGRectMake(size.width/2 + (size.width/2 - 80)/2, y + 10, 80, 40);
    [autoSwitch setOn:NO];
    
    _infoTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 200, [UIScreen mainScreen].bounds.size.width, 200)];
    _infoTextView.layer.borderColor = [UIColor orangeColor].CGColor;
    _infoTextView.layer.borderWidth = 1;
    _infoTextView.editable = NO;
    [self.view addSubview:_infoTextView];
}

- (void)switchAction {
    UISwitch *view = [self.view viewWithTag:574];
    self.autoC = view.on;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField{
    if (textField.tag == 987) {
        self.leftSpace = [textField.text floatValue];
    }else
        self.topSpace = [textField.text floatValue];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITextField *field = [self.view viewWithTag:987];
    UITextField *field1 = [self.view viewWithTag:988];
    [field resignFirstResponder];
    [field1 resignFirstResponder];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setVideoOrientation:(id)sender {
    UIButton *button = (UIButton*)sender;
    switch (button.tag) {
        case 123:
            self.ori = UIInterfaceOrientationPortrait;
            break;
        case 124:
            self.ori = UIInterfaceOrientationPortraitUpsideDown;
            break;
        case 125:
            self.ori = UIInterfaceOrientationLandscapeLeft;
            break;
        case 126:
            self.ori = UIInterfaceOrientationLandscapeRight;
            break;
        default:
            break;
    }
    
}

- (void)setVideoNewColor:(id)sender
{
    UIButton *button = (UIButton*)sender;
    switch (button.tag)
    {
        case 232:
            self.videoColor = [UIColor blackColor];
            break;
        case 233:
            self.videoColor = [UIColor orangeColor];
            break;
        case 234:
            self.videoColor = [UIColor lightGrayColor];
            break;
        case 235:
            self.videoColor = [UIColor purpleColor];
            break;
        default:
            break;
    }
}

- (void)jump:(id)sender {
    UIButton *button = (UIButton*)sender;
    AdViewVideoType type = AdViewVideoTypeInstl;
    if (button.tag == 1002)
    {
        type = AdViewVideoTypePreMovie;
    }
    // [ADVASTFileHandle printCacheFile];
    
    if (type == AdViewVideoTypeInstl)
    {
        if (self.video == nil)
        {
            self.video = [AdViewVideo playVideoWithAppId:@"SDK20191606040826utni417gaot5alt"
                                              positionId:@"POSID9pgkbm6lflf7"
                                               videoType:type
                                                delegate:self];
        }
        [video setInterfaceOrientations:self.ori];
        [video setVideoBackgroundColor:self.videoColor];
        [video isShowTrafficReminderView:YES];
    }
    else
    {
        if (self.previewVideo == nil)
        {
            self.video = [AdViewVideo playVideoWithAppId:@"SDK201709030903389ula5levxt17ukq"
                                              positionId:@"VIDEOeg90m2r50ak6"
                                               videoType:type
                                                delegate:self];
        }
    }
    [video getVideoAD];
}

- (void)playVideoWithSourceArr:(NSArray*)sourceArr
{
    mp = [[MPMoviePlayerController alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeView) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    [mp.view setFrame:self.view.bounds];
    mp.controlStyle = MPMovieControlStyleFullscreen;
    mp.contentURL = [NSURL URLWithString:[sourceArr objectAtIndex:0]];
    mp.shouldAutoplay = YES;
    [mp prepareToPlay];
    [self.view addSubview:mp.view];
    [mp play];
}

- (void)removeView
{
    [mp.view removeFromSuperview];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setTitle:@"贴片跳转" forState:UIControlStateNormal];
    button.frame = CGRectMake(210, 220, 100, 100);
    [button addTarget:self action:@selector(openUrl) forControlEvents:UIControlEventTouchUpInside];
    button.tag = 1000;
    [self.view addSubview:button];
}

- (void)openUrl
{
    [[self.view viewWithTag:1000] removeFromSuperview];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:clickUrl]];
}

#pragma mark - videoDelegate
- (void)adViewVideoIsReadyToPlay:(AdViewVideo *)video
{
    [self.video showVideoWithController:self];
    _infoTextView.text = [AdViewVastFileHandle logVideoCacheInfoForTest];
}

- (void)adViewVideoDidReceiveAd:(NSString *)vastString
{
    if (vastString) {
        _infoTextView.text = vastString;
    }
}

- (void)adViewVideoFailReceiveDataWithError:(NSError *)error {
    _infoTextView.text = error.description;
}
/*
 * 视频广告播放开始回调
 */
- (void)adViewVideoPlayStarted{
    AdViewLogInfo(@"%s",__FUNCTION__);
}

/*
 * 视频广告播放结束回调
 */
- (void)adViewVideoPlayEnded{
    AdViewLogInfo(@"%s",__FUNCTION__);
}

/*
 * 视频广告关闭回调
 */
- (void)adViewVideoClosed {
    AdViewLogInfo(@"%s",__FUNCTION__);
}

- (void)adViewVideoSkipped {
    AdViewLogInfo(@"%s",__FUNCTION__);
}

- (BOOL)subjectToGDPR {
    return NO;
}

- (NSString *)userConsentString {
    return nil;
}
@end

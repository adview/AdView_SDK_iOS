    //
//  AdViewWebViewController.m
//  AdViewSDK
//
//  Created by AdView on 12-9-3.
//  Copyright 2012 AdView. All rights reserved.
//

#import "AdViewWebViewController.h"
#import "AdViewExtTool.h"

@interface AdViewWebViewController(PRIVATE)

- (void)makeToolBar;

@end


@implementation AdViewWebViewController

@synthesize webView = _webView;
@synthesize urlRequest = _urlRequest;
@synthesize urlString = _urlString;

@synthesize bodyString = _bodyString;

@synthesize delegate = _delegate;

@synthesize currURL;

- (void)makeToolBar
{
    CGRect rect = self.view.frame;
    rect.origin.x = 0;
    rect.origin.y = rect.size.height - 44;
    rect.size.height = 44;
    
    UIToolbar *bottomToolBar = [[UIToolbar alloc] initWithFrame:rect];

    bottomToolBar.barStyle = UIBarStyleDefault;
    bottomToolBar.tintColor = [UIColor grayColor];
    bottomToolBar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    
    UIBarButtonItem *edgeItem = nil;
    edgeItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                             target:nil action:nil];
    edgeItem.width = 20;
    
    UIBarButtonItem *spaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    int density = [AdViewExtTool getDensity];
    CGImageRef theCGImage = nil;
    theCGImage = createForwardOrBackArrowImageRef_AdView(NO);
    UIImage *backImage = [[UIImage alloc] initWithCGImage:theCGImage scale:density orientation:UIImageOrientationUp];
    CGImageRelease(theCGImage);
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithImage:backImage
              style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
    
    theCGImage = createForwardOrBackArrowImageRef_AdView(YES);
    UIImage *forwardImage = [[UIImage alloc] initWithCGImage:theCGImage scale:density orientation:UIImageOrientationUp];
    CGImageRelease(theCGImage);
    UIBarButtonItem *forwardItem = [[UIBarButtonItem alloc] initWithImage:forwardImage
                                                                 style:UIBarButtonItemStylePlain target:self action:@selector(goForward)];
    
    //UIBarButtonItem *forwardItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(goForward)];
    
    
    UIBarButtonItem *refreshItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reload)];
    
    UIBarButtonItem *actionItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(goAction)];
    
    UIBarButtonItem *closeItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(closeButtonPressed:)];
    
    arrToolItems = [[NSMutableArray alloc] initWithCapacity:4];
    [arrToolItems addObjectsFromArray:[NSArray arrayWithObjects:backItem, forwardItem, nil]];
    
    [bottomToolBar setItems:[NSArray arrayWithObjects:edgeItem,backItem,spaceItem,forwardItem,spaceItem, refreshItem, spaceItem, actionItem, spaceItem, closeItem, edgeItem, nil]];
    
    [self.view addSubview:bottomToolBar];
}

- (void)makeCloseButton
{
	UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
	closeButton.tag = 0;
	
	UIImage *closeImage = [[AdViewExtTool sharedTool] getCloseImageNormal];
	UIImage *closeImagePressed = [[AdViewExtTool sharedTool] getCloseImageHighlight];
	
	[closeButton setImage:closeImage forState:UIControlStateNormal];
	[closeButton setImage:closeImagePressed forState:UIControlStateHighlighted];
	
	CGSize closeSize = closeImage.size;
	closeButton.frame = CGRectMake(0, 0, closeSize.width, closeSize.height);
	
	[closeButton addTarget:self action:@selector(closeButtonPressed:) 
		  forControlEvents:UIControlEventTouchUpInside];
	
	[self.view addSubview:closeButton];
    
    closeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleBottomMargin;
	
	CGRect frm = self.view.frame;
	CGRect closeFrm = CGRectMake(frm.size.width - 2 - closeSize.width, 2,
								 closeSize.width, closeSize.height);
	closeButton.frame = closeFrm;
}

#pragma mark web actions

- (void)closeButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion{
    [super dismissViewControllerAnimated:flag completion:completion];
    if (self.delegate && [self.delegate respondsToSelector:@selector(dismissWebViewModal:)])
        [self.delegate dismissWebViewModal:self.webView];
}

- (void)goBack {
    [self.webView goBack];
}

- (void)goForward {
    [self.webView goForward];
}

- (void)reload {
    [self.webView reload];
}

- (void)openInSafari {
    NSURL *url = self.currURL;
    //NSString *currentURL = self.webView.request.URL.absoluteString;
    if ([[UIApplication sharedApplication] canOpenURL:url])
        [[UIApplication sharedApplication] openURL:url];
}

- (void)goAction {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Open In Safari", nil];
    actionSheet.tag = 100;
    actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    [actionSheet showInView:self.view]; // show from our table view (pops up in the middle of the table)
}

- (void)setItemStates
{
    int nCount = (int)[arrToolItems count];
    if (0 < nCount) [[arrToolItems objectAtIndex:0] setEnabled:[self.webView canGoBack]];
    if (1 < nCount) [[arrToolItems objectAtIndex:1] setEnabled:[self.webView canGoForward]];
}

#pragma mark UIViewController override functions.

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    /*横屏修改是为 横屏创建viewcontroller 时有半屏情况*/
	CGRect startRect = [[UIScreen mainScreen] bounds];
    CGFloat width =  [AdViewExtTool getDeviceDirection]?startRect.size.height:startRect.size.width;
    CGFloat height =  [AdViewExtTool getDeviceDirection]?startRect.size.width:startRect.size.height;
    self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, width, height);
    /*横屏修改是为 横屏创建viewcontroller 时有半屏情况*/
    CGRect rectAll = self.view.frame;
    CGRect rect = rectAll;
    rect.origin.x = 0;
    rect.origin.y = 0;
    rect.size.height -= 44;
    if (([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)) {
        rect.origin.y = 20;
        self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, width, height+20);
    }
    
	UIWebView *webView0 = nil;
	BOOL	bNewWebView = NO;
	if (nil == self.webView) {
		webView0 = [[UIWebView alloc] init];
		bNewWebView = YES;
	} else {
		webView0 = self.webView;
	}
	webView0.userInteractionEnabled = YES;
    webView0.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    webView0.frame = rect;
	
    webView0.scalesPageToFit = YES;
    webView0.delegate = self;
	[self.view addSubview:webView0];
	
	if (bNewWebView) {
		self.webView = webView0;
        self.webView.backgroundColor = [UIColor whiteColor];
	}
    
    [self makeToolBar];
    
    CGRect rectWeb = self.webView.frame;
    
    indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    CGRect rectIndi = indicatorView.frame;
    rectIndi.origin.x = (rectWeb.size.width - rectIndi.size.width)/2.0f;
    rectIndi.origin.y = (rectWeb.size.height - rectIndi.size.height)/2.0f;
    indicatorView.frame = rectIndi;
    indicatorView.hidesWhenStopped = YES;
    indicatorView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin
                    | UIViewAutoresizingFlexibleBottomMargin
                    | UIViewAutoresizingFlexibleLeftMargin
                    | UIViewAutoresizingFlexibleRightMargin;
    [self.webView addSubview:indicatorView];
    
    [self performSelector:@selector(loadWebView) withObject:nil afterDelay:0.1];
	
	//[self makeCloseButton];
}


- (void)loadWebView {
	if (nil != self.urlRequest)
		[self.webView loadRequest:self.urlRequest];
	else if (nil != self.urlString) {
        NSURL* url = [NSURL URLWithString:self.urlString];
		NSURLRequest* req = [NSURLRequest requestWithURL:url];
		[self.webView loadRequest:req];
	} else if (nil != self.bodyString) {
		[self.webView loadHTMLString:self.bodyString baseURL:nil];
    }
	
	[self setItemStates];
}

- (BOOL)shouldAutorotate {
	return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (void)dealloc {
    [indicatorView removeFromSuperview];
    indicatorView = nil;
    
	self.webView.delegate = nil;
    [self.webView removeFromSuperview];
	self.webView = nil;
    
    arrToolItems = nil;
	
	self.urlRequest = nil;
	self.urlString = nil;
    self.currURL = nil;
    self.bodyString = nil;
    
	self.delegate = nil;
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // the user clicked one of the OK/Cancel buttons
    if (buttonIndex == 0)
    {
        //NSLog(@"ok");
        [self openInSafari];
    }
    else
    {
        //NSLog(@"cancel");
    }
}

#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType
{

    NSString *urlString = [[request URL] absoluteString];
    AdViewLogDebug(@"webView 加载 ：%@",urlString);
    
    if (nil != urlString && ![urlString isEqualToString:@"about:blank"]) {
        BOOL bItunes = ([urlString rangeOfString:@"//itunes.apple.com"].location != NSNotFound);
        BOOL bHttp = ([urlString rangeOfString:@"http://"].location == 0);	//http
        BOOL bHttps = ([urlString rangeOfString:@"https://"].location == 0);
	
        BOOL bJudgeLocalWeb = (bHttp || bHttps) && !bItunes;
        
        if (!bJudgeLocalWeb) {
            BOOL isSuccess = NO;
            if (bItunes) {
                isSuccess = [self.delegate isSuccessOpenAppStoreInAppWithUrlString:urlString];
                if (isSuccess)  {
//                    [self performSelector:@selector(closeButtonPressed:) withObject:nil];
                    return NO;
                }
            }
            
            NSURL *url = [NSURL URLWithString:urlString];
            UIApplication *application = [UIApplication sharedApplication];
            if (@available(iOS 10.0, *))
            {
                [application openURL:url options:@{} completionHandler:^(BOOL success) {
                    if (success)
                    {
                        [self performSelector:@selector(closeButtonPressed:) withObject:nil];
                    }
                }];
            }
            else
            {
                BOOL success = [application openURL:url];
                if (success)
                {
                    [self performSelector:@selector(closeButtonPressed:) withObject:nil];
                }
                
            }
            return NO;
        }
    }
    
    self.currURL = [request URL];
    
	return YES;
}

//these three functions to set loading icon.
- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [self setItemStates];
    [indicatorView startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self setItemStates];
    [indicatorView stopAnimating];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self setItemStates];
    [indicatorView stopAnimating];
}

@end

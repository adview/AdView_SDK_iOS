//
//  AdViewWebViewController.h
//  AdViewSDK
//
//  Created by AdView on 12-9-3.
//  Copyright 2012 AdView. All rights reserved.
//  用于点击弹出的网页

#import <UIKit/UIKit.h>
#import <SafariServices/SafariServices.h>

@protocol AdViewWebViewControllerDelegate <NSObject>

- (void)dismissWebViewModal:(UIWebView*)webView;
- (BOOL)isSuccessOpenAppStoreInAppWithUrlString:(NSString*)urlString;

@end


@interface AdViewWebViewController : UIViewController <UIWebViewDelegate, UIActionSheetDelegate> {
    NSMutableArray      *arrToolItems;
    
    UIActivityIndicatorView  *indicatorView;
    
    NSURL         *currURL;
}

@property (nonatomic, retain) NSURL         *currURL;

@property (nonatomic, retain) UIWebView		*webView;
@property (nonatomic, retain) NSURLRequest	*urlRequest;
@property (nonatomic, retain) NSString		*urlString;
@property (nonatomic, retain) NSString		*bodyString;

@property (nonatomic, weak) id<AdViewWebViewControllerDelegate> delegate;

@end

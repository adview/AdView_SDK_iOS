//
//  ADVGLogWKWebView.h
//  AdViewHello
//
//  Created by unakayou on 8/9/19.
//  自动打印JS日志webview

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AdViewLogWKWebView : WKWebView <WKScriptMessageHandler>
- (void)stopListenJSLog;
@end

NS_ASSUME_NONNULL_END

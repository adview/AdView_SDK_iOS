//
//  ADVGLogWKWebView.m
//  AdViewHello
//
//  Created by unakayou on 8/9/19.
//

#import "AdViewLogWKWebView.h"
#import "AdViewDefines.h"

#define kCustomJSLoggerName @"log"
@implementation AdViewLogWKWebView

- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration*)configuration {
    if(self = [super initWithFrame:frame configuration:configuration]) {
        WKUserContentController * userCC = configuration.userContentController;
        [userCC addScriptMessageHandler:self name:kCustomJSLoggerName];
        [self showConsole];
    }
    return self;
}

- (void)showConsole {
    NSString *jsCode = @"console.log = (function(oriLogFunc){\
    return function(str)\
    {\
    window.webkit.messageHandlers.log.postMessage(str);\
    oriLogFunc.call(console,str);\
    }\
    })(console.log);";
    
    [self.configuration.userContentController addUserScript:[[WKUserScript alloc]
                                                             initWithSource:jsCode
                                                             injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                                             forMainFrameOnly:YES]];
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    AdViewLogInfo(@"%s - %@",__FUNCTION__, message.body);
}

- (void)stopListenJSLog {
    [self.configuration.userContentController removeScriptMessageHandlerForName:kCustomJSLoggerName];
}

@end

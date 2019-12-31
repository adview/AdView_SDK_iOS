//
//  ADVGOMAdHTMLManager.m
//  AdViewHello
//
//  Created by unakayou on 7/24/19.
//

#import "AdViewOMAdHTMLManager.h"

@implementation AdViewOMAdHTMLManager

- (instancetype)init {
    return [self initWithWebView:[UIView new]];
}

- (instancetype)initWithWebView:(UIView *)webView {
    if (self = [super init]) {
        _webView = webView;
    }
    return self;
}

+ (NSString *)injectOMJSIntoAdHTML:(NSString *)adHtml error:(NSError * _Nullable __autoreleasing *)error {
    Class OMIDAdviewScriptInjectorClass = NSClassFromString(@"OMIDAdviewScriptInjector");
    if (OMIDAdviewScriptInjectorClass) {
        NSString * injectedString = [OMIDAdviewScriptInjectorClass injectScriptContent:[AdViewOMAdHTMLManager OMIDService]
                                                                              intoHTML:adHtml
                                                                                 error:error];
        return injectedString;
    }
    return adHtml;
}

- (OMIDAdviewAdSessionConfiguration *)createAdSessionConfiguration {
    Class OMIDAdviewAdSessionConfigurationClass = NSClassFromString(@"OMIDAdviewAdSessionConfiguration");
    if (OMIDAdviewAdSessionConfigurationClass) {
        return [[OMIDAdviewAdSessionConfigurationClass alloc] initWithImpressionOwner:OMIDNativeOwner
                                                                     videoEventsOwner:OMIDNoneOwner
                                                           isolateVerificationScripts:NO
                                                                                error:nil];
    }
    return nil;
}

- (OMIDAdviewAdSessionContext *)createAdSessionContextWithPartner:(OMIDAdviewPartner *)partner {
    Class OMIDAdviewAdSessionContextClass = NSClassFromString(@"OMIDAdviewAdSessionContext");
    if (OMIDAdviewAdSessionContextClass) {
        NSError * error = nil;
        OMIDAdviewAdSessionContext * retContext = [[OMIDAdviewAdSessionContextClass alloc] initWithPartner:partner
                                                                                                   webView:_webView
                                                                                 customReferenceIdentifier:nil
                                                                                                     error:&error];
        if (error) {
            AdViewLogInfo(@"%s - %@",__FUNCTION__, error);
        }
        return retContext;
    }
    return nil;
}
@end

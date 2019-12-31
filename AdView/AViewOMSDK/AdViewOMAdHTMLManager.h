//
//  ADVGOMAdHTMLManager.h
//  AdViewHello
//
//  Created by unakayou on 7/24/19.
//

#import "AdViewOMBaseAdUnitManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface AdViewOMAdHTMLManager : AdViewOMBaseAdUnitManager
@property (nonatomic, strong, readonly) UIView * webView;

+ (NSString *)injectOMJSIntoAdHTML:(NSString *)adHtml error:(NSError **)error;
- (instancetype)initWithWebView:(UIView *)webView NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END

//
//  NSObject+AdViewFrameworkResource.m
//  AdViewHello
//
//  Created by unakayou on 8/7/19.
//

#import "NSObject+AdViewFrameworkResource.h"
#import "AdViewOMAdHTMLManager.h"

@implementation NSObject (AdViewFrameworkResource)

- (NSString *)pathForFrameworkResource:(NSString *)name ofType:(NSString *)ext {
    NSBundle * frameworkBundle = [NSBundle bundleForClass:[AdViewOMAdHTMLManager class]];
    NSString * filePath = [frameworkBundle pathForResource:name ofType:ext];
    return filePath;
}

//静态库
//- (NSString *)pathForFrameworkResource:(NSString *)name ofType:(NSString *)ext {
//    NSString * bundlePath = [[NSBundle mainBundle] pathForResource:@"AdViewSDK" ofType:@"framework"];
//    NSBundle * bundle = [NSBundle bundleWithPath:bundlePath];
//    NSString * omsdkJSPath = [bundle pathForResource:name ofType:ext];
//    return omsdkJSPath;
//}
@end

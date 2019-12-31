//
//  AdViewCheckTool.h
//  AdViewHello
//
//  Created by AdView on 17/3/1.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface AdViewCheckTool : NSObject{
    NSArray*  matchLanding;         //用于检测是自动跳转不应该允许的地址
}

@property (nonatomic, strong) NSArray* matchLanding;
+ (AdViewCheckTool*)sharedTool;
//判断地址是否是落地页，比如是设置的落地页，或者是AppStore下载页面，或者是认定类似落地的页面
- (BOOL)isLandingUrl:(NSString*)reqUrl;
//判断广告是否为空白，上下左右中五点是否为同色
- (BOOL)isEmptyAd:(UIView*)rAdView;

@end

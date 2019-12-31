//
//  ADVGImageDownloadManager.h
//  AdViewHello
//
//  Created by unakayou on 7/23/19.
//  图片加载管理器(包括请求 + 缓存)

#import <Foundation/Foundation.h>
#import "ADVGURLSessionManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface ADVGImageDownloadManager : NSObject
@property (nonatomic, strong) ADVGURLSessionManager * sessionManager;
@end

NS_ASSUME_NONNULL_END

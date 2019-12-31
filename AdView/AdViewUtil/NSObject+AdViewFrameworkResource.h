//
//  NSObject+AdViewFrameworkResource.h
//  AdViewHello
//
//  Created by unakayou on 8/7/19.
// 专门用来拿framework里面的文件的路径

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (AdViewFrameworkResource)

//动态库中读取文件路径
- (NSString *)pathForFrameworkResource:(NSString *)name ofType:(NSString *)ext;
@end

NS_ASSUME_NONNULL_END

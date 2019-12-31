//
//  NSObject+AdViewDeallocLog.h
//  AdViewHello
//
//  Created by unakayou on 8/13/19.
//  释放日志扩展

#import <Foundation/Foundation.h>
#import "AdViewDefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (AdViewDeallocLog)
@property (nonatomic, assign) BOOL deallocLog;
@end

NS_ASSUME_NONNULL_END

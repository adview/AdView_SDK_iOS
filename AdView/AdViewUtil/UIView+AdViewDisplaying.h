//
//  UIView+Displaying.h
//  AdViewHello
//
//  Created by unakayou on 8/14/19.
//  判断是否正在展示

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (AdViewDisplaying)
@property (nonatomic, assign, readonly) BOOL displaying;
@end

NS_ASSUME_NONNULL_END

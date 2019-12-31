//
//  UIView+Displaying.m
//  AdViewHello
//
//  Created by unakayou on 8/14/19.
//

#import "UIView+AdViewDisplaying.h"

@implementation UIView (AdViewDisplaying)
@dynamic displaying;

- (BOOL)displaying {
    //如果superview不存在
    if (self.superview == nil) {
        if (self == [[UIApplication sharedApplication] keyWindow]) {
            return YES;
        } else {
            return NO;
        }
    }
    
    if (!self.window) {
        return NO;
    }

    //转换view对应window的Rect
    CGRect rect = [self convertRect:self.frame fromView:nil];
    if (CGRectIsEmpty(rect) || CGRectIsNull(rect)) {
        return NO;
    }
    
    //若view 隐藏
    if (self.hidden) {
        return NO;
    }
    
    //若size为CGrectZero
    if (CGSizeEqualToSize(rect.size, CGSizeZero)) {
        return  NO;
    }
    
    //获取 该view与window 交叉的 Rect
    CGRect screenRect = [UIScreen mainScreen].bounds;
    CGRect intersectionRect = CGRectIntersection(rect, screenRect);
    if (CGRectIsEmpty(intersectionRect) || CGRectIsNull(intersectionRect)) {
        return NO;
    }
    
    //如果有superview,则递归查看..
    if (!self.superview.displaying) {
        return NO;
    }
    return YES;
}
@end

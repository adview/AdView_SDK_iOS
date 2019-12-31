//
//  NSTimer+AdViewWeakTimer.m
//  AdViewHello
//
//  Created by AdView on 6/3/19.
//

#import "NSTimer+AdViewWeakTimer.h"
@interface AdViewTimerWeakTarget : NSObject
@property (nonatomic, weak) id _Nullable  target;
@property (nonatomic, assign) SEL selector;
@property (nonatomic, weak) NSTimer * timer;
- (void)fire:(NSTimer *)timer;
@end

@implementation AdViewTimerWeakTarget
- (void)fire:(NSTimer *)timer {
    if (self.target) {
        if ([self.target respondsToSelector:self.selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [self.target performSelector:self.selector withObject:timer.userInfo];
#pragma clang diagnostic pop
        } else {
            [self.timer invalidate];
        }
    }
}
@end;

@implementation NSTimer (AdViewWeakTimer)
+ (NSTimer *)scheduledWeakTimerWithTimeInterval:(NSTimeInterval)ti
                                         target:(id)aTarget
                                       selector:(SEL)aSelector
                                       userInfo:(nullable id)userInfo repeats:(BOOL)yesOrNo {
    AdViewTimerWeakTarget * target = [[AdViewTimerWeakTarget alloc] init];
    target.target = aTarget;
    target.selector = aSelector;
    target.timer = [NSTimer scheduledTimerWithTimeInterval:ti target:target selector:@selector(fire:) userInfo:userInfo repeats:yesOrNo];
    return target.timer;
}
@end

//
//  NSTimer+AdViewWeakTimer.h
//  AdViewHello
//
//  Created by AdView on 6/3/19.
//  弱引用timer

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
@interface NSTimer (AdViewWeakTimer)
+ (NSTimer *)scheduledWeakTimerWithTimeInterval:(NSTimeInterval)ti
                                         target:(id)aTarget
                                       selector:(SEL)aSelector
                                       userInfo:(nullable id)userInfo
                                        repeats:(BOOL)yesOrNo;
@end
NS_ASSUME_NONNULL_END

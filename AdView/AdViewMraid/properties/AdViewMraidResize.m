//
//  AdViewMraidResize.m
//  AdViewHello
//
//  Created by AdView on 15-1-20.
//
//

#import "AdViewMraidResize.h"

@implementation AdViewMraidResize

- (id)init {
    if (self = [super init]) {
        _width = 0;
        _height = 0;
        _offSetX = 0;
        _offSetX = 0;
        _customClosePosition = AdViewMraidCustomClosePositionTopRight;
        _allowOffScreen = YES;
    }
    
    return self;
}

+ (AdViewMraidCustomClosePosition)mraidCustomClosePositionFromString:(NSString *)positionStr {
    NSArray * names = @[@"top-left",
                        @"top-center",
                        @"top-right",
                        @"center",
                        @"bottom-left",
                        @"bottom-center",
                        @"bottom-right"];
    NSUInteger position = [names indexOfObject:positionStr];
    if (position != NSNotFound) {
        return (AdViewMraidCustomClosePosition)position;
    }
    //default vale --> top-right
    return AdViewMraidCustomClosePositionTopRight;
}

@end

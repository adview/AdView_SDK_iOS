//
//  AdViewMraidResize.h
//  AdViewHello
//
//  Created by AdView on 15-1-20.
//
//

#import <Foundation/Foundation.h>

typedef enum {
    AdViewMraidCustomClosePositionTopLeft,
    AdViewMraidCustomClosePositionTopCenter,
    AdViewMraidCustomClosePositionTopRight,
    AdViewMraidCustomClosePositionCenter,
    AdViewMraidCustomClosePositionBottomLeft,
    AdViewMraidCustomClosePositionBottomCenter,
    AdViewMraidCustomClosePositionBottomRight
} AdViewMraidCustomClosePosition;

@interface AdViewMraidResize : NSObject

@property (nonatomic, assign) int width;
@property (nonatomic, assign) int height;
@property (nonatomic, assign) int offSetX;
@property (nonatomic, assign) int offSetY;
@property (nonatomic, assign) AdViewMraidCustomClosePosition customClosePosition;
@property (nonatomic, assign) BOOL allowOffScreen;

+ (AdViewMraidCustomClosePosition)mraidCustomClosePositionFromString:(NSString*)positionStr;

@end

//
//  AdViewMraidOrientation.h
//  AdViewHello
//
//  Created by AdView on 15-1-20.
//
//

#import <Foundation/Foundation.h>

typedef enum{
    AdViewMraidForceOrientationPortrait,
    AdViewMraidForceOrientationLandscape,
    AdViewMraidForceOrientationNone
}AdViewMraidForceOrientation;

@interface AdViewMraidOrientation : NSObject

@property (nonatomic, assign) BOOL allowOrientationChange;
@property (nonatomic, assign) AdViewMraidForceOrientation forceOrientation;

+ (AdViewMraidForceOrientation)mraidForceOrientationFromString:(NSString*)orientationStr;

@end

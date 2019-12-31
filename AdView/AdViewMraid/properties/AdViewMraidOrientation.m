//
//  AdViewMraidOrientation.m
//  AdViewHello
//
//  Created by AdView on 15-1-20.
//
//

#import "AdViewMraidOrientation.h"

@implementation AdViewMraidOrientation

- (id)init
{
    if (self = [super init])
    {
        self.allowOrientationChange = YES;
        self.forceOrientation = AdViewMraidForceOrientationNone;
    }
    return self;
}

+ (AdViewMraidForceOrientation)mraidForceOrientationFromString:(NSString *)orientationStr
{
    NSArray * names = @[@"portrait", @"landscape", @"none"];
    NSUInteger orientation = [names indexOfObject:orientationStr];
    if (orientation != NSNotFound)
    {
        return (AdViewMraidForceOrientation)orientation;
    }
    //default vale --> none
    return AdViewMraidForceOrientationNone;
}

@end

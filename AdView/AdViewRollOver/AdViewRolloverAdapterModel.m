//
//  RolloverAdapterDataModel.m
//  KOpenAPIAdView
//
//  Created by AdView on 2018/8/15.
//

#import "AdViewRolloverAdapterModel.h"

@implementation AdViewRolloverAdapterModel

- (void)setAggsrc:(NSNumber *)aggsrc
{
    switch (aggsrc.integerValue)
    {
        case 1006:
        {
            self.adapterClass = NSClassFromString(@"AdViewAdapterGDT");
        }
            break;
        case 1007:
        {
            self.adapterClass = NSClassFromString(@"AdViewAdapterBaidu");
        }
            break;
        case 1008:
        {
            self.adapterClass = NSClassFromString(@"AdViewAdapterToutiao");
        }
            break;
        default:
            self.adapterClass = NSClassFromString(@"RolloverAdapter");
            break;
    }
}
@end

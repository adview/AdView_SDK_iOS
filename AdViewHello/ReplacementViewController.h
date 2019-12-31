//
//  ReplacementViewController.h
//  AdViewHello
//
//  Created by AdView on 2017/6/26.
//
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    Replacement_ALL,
    Replacement_XS,
} ReplacementString;

@interface ReplacementViewController : UIViewController

- (instancetype)initWithType:(ReplacementString)type;

@end

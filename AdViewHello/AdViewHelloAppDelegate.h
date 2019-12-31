//
//  AdViewHelloAppDelegate.h
//  AdViewHello
//
//  Created by AdView on 10-11-24.
//  Copyright 2010 AdView. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AdViewViewDelegate.h"
#import "AdViewView.h"

@class AdViewHelloViewController;

@interface AdViewHelloAppDelegate : NSObject <UIApplicationDelegate, AdViewViewDelegate>
@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) AdViewHelloViewController * viewController;
@property (nonatomic, strong) AdViewView * adView;
@property (nonatomic, strong) AdViewView * adInstl;
@property (nonatomic, strong) AdViewView * adSpread;
@property (nonatomic, strong) UIButton *adInstlButton;
@property (nonatomic, strong) UIButton *bannerButton;
- (void)nextAdType;
- (void)nextAdSize;
- (void)toggleTestMode;
- (void)setInfoStr:(NSString*)info;

@end


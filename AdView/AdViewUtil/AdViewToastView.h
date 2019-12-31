//
//  AdViewToastView.h
//  GetIdfa
//
//  Created by AdView on 16/11/11.
//  Copyright © 2016年 AdView. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AdViewToastView : UIView

+ (AdViewToastView*)setTipInfo:(NSString*)text;
- (void)showTastView;

@end

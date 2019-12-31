//
//  AdViewToastView.m
//  GetIdfa
//
//  Created by AdView on 16/11/11.
//  Copyright © 2016年 AdView. All rights reserved.
//

#import "AdViewToastView.h"

@interface AdViewToastView()

@property (nonatomic, strong) UILabel *tipLabel;

@end

#define SCALE 1.0

@implementation AdViewToastView

+ (AdViewToastView *)setTipInfo:(NSString *)text {
    static AdViewToastView *toast = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        toast = [[self alloc] init];
        toast.tipLabel = [[UILabel alloc] init];
        toast.tipLabel.textColor = [UIColor whiteColor];
        toast.tipLabel.textAlignment = NSTextAlignmentCenter;
        toast.tipLabel.layer.masksToBounds = YES;
        toast.tipLabel.layer.cornerRadius = 15*SCALE;
        toast.tipLabel.numberOfLines = 0;
        toast.tipLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.75f];
    });
    
    CGSize scrSize = [UIScreen mainScreen].bounds.size;
    
    CGSize size = [text boundingRectWithSize:CGSizeMake(250*SCALE, 100*SCALE) options:NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:20*SCALE]} context:nil].size;
    
    toast.tipLabel.frame = CGRectMake((scrSize.width - size.width - 20*SCALE)/2, (scrSize.height  - 50*SCALE - size.height)/2, size.width + 20*SCALE, size.height + 10*SCALE);
    toast.tipLabel.text = text;
    
    return toast;
}

- (void)showTastView {
    [[UIApplication sharedApplication].keyWindow addSubview:self.tipLabel];
    [[UIApplication sharedApplication].keyWindow bringSubviewToFront:self.tipLabel];
    [UIView animateWithDuration:3.0 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.tipLabel.alpha = 0;
    } completion:^(BOOL finished) {
        self.tipLabel.alpha = 1;
        [self.tipLabel removeFromSuperview];
    }];
}

@end

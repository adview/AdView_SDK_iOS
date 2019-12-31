//
//  CountDownView.h
//  KOpenAPIAdView
//
//  Created by AdView on 2018/5/4.
//

#import <UIKit/UIKit.h>

@interface AdViewCountDownView : UIView

@property (nonatomic, strong) UIColor *strokeColor;     // 进度条颜色
@property (nonatomic, strong) UIColor *backStrokeColor; // 背景圆颜色
@property (nonatomic, strong) UIColor *textColor;       // 文字颜色
@property (nonatomic, strong) UIColor *fillColor;       // 填充颜色
@property (nonatomic, assign) CGFloat fontSize;         // 字体大小
@property (nonatomic, assign) CGFloat progress;         // 进度条的值：[0，1]
@property (nonatomic, assign) float length;

- (instancetype)initWithFrame:(CGRect)frame lineWidth:(CGFloat)lineWidth;
- (void)updateCountDownLabelTextWithString:(NSString *)textString;

@end

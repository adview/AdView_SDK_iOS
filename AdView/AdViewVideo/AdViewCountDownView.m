//
//  CountDownView.m
//  KOpenAPIAdView
//
//  Created by AdView on 2018/5/4.
//

#import "AdViewCountDownView.h"

#define Width self.bounds.size.width
#define Height self.bounds.size.height

@interface AdViewCountDownView ()

@property (nonatomic, assign) CGFloat lineWidth; // 默认值为3
@property (nonatomic, strong) CAShapeLayer *backLayer; // 背景layer
@property (nonatomic, strong) CAShapeLayer *circleLayer; // 进度条layer
@property (nonatomic, strong) UILabel *countDownLabel;
@property (nonatomic, strong) UIBezierPath *path;

@end

@implementation AdViewCountDownView

- (instancetype)initWithFrame:(CGRect)frame lineWidth:(CGFloat)lineWidth {
    if (self = [super initWithFrame:frame]) {
        self.lineWidth = lineWidth;
        [self setupSubviews];
    }
    return self;
}

-(void)setupSubviews {
    [self.layer addSublayer:self.backLayer];
    [self.layer addSublayer:self.circleLayer];
    [self addSubview:self.countDownLabel];
}

//更新倒计时
- (void)updateCountDownLabelTextWithString:(NSString *)textString
{
    int time = [textString intValue];
    self.countDownLabel.text = [NSString stringWithFormat:@"%d",time];
    self.progress = (self.length - [textString floatValue]) / self.length;
}

#pragma mark - setter method
- (void)setFillColor:(UIColor *)fillColor {
    _fillColor = fillColor;
    self.countDownLabel.backgroundColor = fillColor;
}

- (void)setLineWidth:(CGFloat)lineWidth {
    if (lineWidth <= 0 || lineWidth >= Width/5) {
        _lineWidth = Width/10;
    }else {
        _lineWidth = lineWidth;
    }
    self.backLayer.lineWidth = _lineWidth;
    self.circleLayer.lineWidth = _lineWidth;
}

-(void)setStrokeColor:(UIColor *)strokeColor {
    _strokeColor = strokeColor;
    self.circleLayer.strokeColor = strokeColor.CGColor;
}

-(void)setBackStrokeColor:(UIColor *)backStrokeColor {
    _backStrokeColor = backStrokeColor;
    self.backLayer.strokeColor = backStrokeColor.CGColor;
}

-(void)setTextColor:(UIColor *)textColor {
    _textColor = textColor;
    self.countDownLabel.textColor = textColor;
}

-(void)setFontSize:(CGFloat)fontSize {
    _fontSize = fontSize;
    self.countDownLabel.font = [UIFont systemFontOfSize:fontSize];
}

-(void)setProgress:(CGFloat)progress {
    _progress = progress;
    self.circleLayer.strokeStart = 0;
    if (progress != 0)
        self.circleLayer.strokeEnd = progress;
}

- (void)setLength:(float)length {
    _length = length;
    self.countDownLabel.text = [NSString stringWithFormat:@"%d",(int)length];
}

#pragma mark - getter method
- (UILabel *)countDownLabel {
    if (!_countDownLabel) {
        _countDownLabel = [[UILabel alloc] init];
        _countDownLabel.frame = self.bounds;
        _countDownLabel.backgroundColor = self.fillColor ? self.fillColor : [UIColor lightGrayColor];
        _countDownLabel.layer.cornerRadius = self.frame.size.width/2;
        _countDownLabel.layer.masksToBounds = YES;
        _countDownLabel.text = [NSString stringWithFormat:@"%d",(int)self.length];
        _countDownLabel.font = [UIFont systemFontOfSize:self.frame.size.width/2];
        _countDownLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _countDownLabel;
}

- (CAShapeLayer *)backLayer {
    if (!_backLayer) {
        _backLayer = [CAShapeLayer layer];
        _backLayer.frame = self.bounds;
        _backLayer.path = self.path.CGPath;
        _backLayer.fillColor = [UIColor clearColor].CGColor;
        _backLayer.strokeColor = self.backStrokeColor ? self.backStrokeColor.CGColor : [UIColor lightGrayColor].CGColor;
        _backLayer.lineWidth = self.lineWidth;
        _backLayer.lineCap = kCALineCapRound;
        _backLayer.strokeEnd = 1;
    }
    return _backLayer;
}

- (CAShapeLayer *)circleLayer {
    if (!_circleLayer) {
        _circleLayer = [CAShapeLayer layer];
        _circleLayer.frame = self.bounds;
        _circleLayer.path = self.path.CGPath;
        _circleLayer.fillColor = [UIColor clearColor].CGColor;
        _circleLayer.strokeColor = self.strokeColor ? self.strokeColor.CGColor : [UIColor whiteColor].CGColor;
        _circleLayer.lineWidth = self.lineWidth;
        _circleLayer.lineCap = kCALineCapRound;
        _circleLayer.strokeEnd = 0;
        [self.layer addSublayer:_circleLayer];
        
    }
    return _circleLayer;
}

- (UIBezierPath *)path {
    if (!_path) {
        CGFloat centerX = Width / 2;
        CGFloat centerY = Height / 2;
        CGFloat radius = 0;
        if (Width > Height) {
            radius = (Height- self.lineWidth)/2;
        } else if (Width < Height) {
            radius = (Width- self.lineWidth)/2;
        } else {
            radius = (Width - self.lineWidth)/2;
        }
        
        CGPoint point = CGPointMake(centerX, centerY);
        _path = [UIBezierPath bezierPathWithArcCenter:point radius:radius startAngle:(-0.5 * M_PI) endAngle:(1.5 * M_PI) clockwise:YES];
    }
    return _path;
}

@end


//
//  SkipVideoButton.m
//  AdViewHello
//
//  Created by AdView on 2018/4/28.
//

#import "AdViewSkipVideoButton.h"
#import "AdViewExtTool.h"
@implementation AdViewSkipVideoButton

- (instancetype)init {
    return [self initWithFrame:CGRectZero];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setBackgroundColor:[AdViewExtTool hexStringToColor:@"#3FA0A0A0"]];
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
         NSString * tmpString = [AdViewExtTool locale] == AdViewLocale_Chinese ? @"跳过视频" : @"Skip";
        NSMutableAttributedString * title = [[NSMutableAttributedString alloc] initWithString:tmpString];
        
        NSRange titleRange = { 0,[title length]};
        [title addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:titleRange];
        [title addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:titleRange];
        [self setAttributedTitle:title forState:UIControlStateNormal];
    }
    return self;
}

@end

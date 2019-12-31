//
//  ADVASTNonVideoView.m
//  AdViewVideoSample
//
//  Created by AdView on 16/10/21.
//  Copyright © 2016年 AdView. All rights reserved.
//

#import "AdViewVastNonVideoView.h"
#import "AdViewExtTool.h"
#import "ADVASTIconModel.h"
#import "ADVASTCompanionModel.h"

@interface AdViewVastNonVideoView ()<UIWebViewDelegate> {
    NSString *htmlRes;
    NSString *iframeRes;
    NSString *staticRes;
    NSString *staticResType;
    NSString *clickThrough;
    NSArray *clickTracking;
    NSArray *impressionArray;
    BOOL isIcon;
    NSDictionary *adDict;
    float scale;
    CGSize size;//容器大小
}

@property (nonatomic, strong) ADVASTIconModel *iconModel;
@property (nonatomic, strong) ADVASTCompanionModel *companionModel;
@end

@implementation AdViewVastNonVideoView
@synthesize iconModel;
@synthesize companionModel;
@synthesize delegate;

- (instancetype)initWithInfoDict:(NSDictionary*)dict isIcon:(BOOL)icon scale:(float)transScale size:(CGSize)superSize{
    if (self = [super init]) {
        adDict = dict;
        isIcon = icon;
        scale = transScale;
        size = superSize;
        [self mateTheAdInfo];
    }
    return self;
}

- (instancetype)initWithObject:(id)obj type:(ADVASTNonVideoViewType)type scale:(CGFloat)transScale size:(CGSize)superSize {
    if (self = [super init]) {
        self.backgroundColor = [UIColor clearColor];
        self.viewType = type;
        if (self.viewType == ADVASTNonVideoViewTypeIcon) {
            self.iconModel = obj;
        }else if (self.viewType == ADVASTNonVideoViewTypeCompanion) {
            self.companionModel = obj;
        }
        scale = transScale;
        size = superSize;
        [self mateTheAdInfo];
    }
    return self;
}

//匹配字典中的数据
- (void)mateTheAdInfo {
    if (self.viewType == ADVASTNonVideoViewTypeCompanion) {
        htmlRes = self.companionModel.htmlSourceStr;
        iframeRes = self.companionModel.iframeSourceStr;
        staticRes = [self.companionModel.staticSourceDict objectForKey:@"StaticResource"];
        staticResType = [self.companionModel.staticSourceDict objectForKey:@"type"];
        if (!staticResType || staticResType.length <= 0) {
            staticResType = @"image";
        }
        staticResType = [staticResType lowercaseString];
        clickThrough = [self.companionModel.clickThroughArr firstObject];
    }else if(self.viewType == ADVASTNonVideoViewTypeIcon){
        htmlRes = self.iconModel.htmlSourceStr;
        iframeRes = self.iconModel.iframeSourceStr;
        staticRes = [self.iconModel.staticSourceDict objectForKey:@"StaticResource"];
        staticResType = [self.companionModel.staticSourceDict objectForKey:@"type"];
        if (!staticResType || staticResType.length <= 0) {
            staticResType = @"image";
        }
        staticResType = [staticResType lowercaseString];
        clickThrough = [self.iconModel.clickThroughArr firstObject];
        NSString *offset = [self.iconModel.contentDict objectForKey:@"offset"];
        NSString *duration = [self.iconModel.contentDict objectForKey:@"duration"];
        self.showTimeStr = offset == nil ? @"-1" : offset;
        self.durationTimeStr = duration == nil ? @"999" : duration;
    }
}

- (void)createView {
    CGFloat width;
    CGFloat height;
    NSString *xPStr;
    NSString *yPStr;
    CGFloat xPosition;
    CGFloat yPosition;
    
    if (self.viewType == ADVASTNonVideoViewTypeIcon) {
        width = [[self.iconModel.contentDict objectForKey:@"width"] floatValue];
        height = [[self.iconModel.contentDict objectForKey:@"height"] floatValue];
        xPStr = [self.iconModel.contentDict objectForKey:@"xPosition"];
        yPStr = [self.iconModel.contentDict objectForKey:@"yPosition"];
    }else {
        width = [[self.companionModel.contentDict objectForKey:@"width"] floatValue];
        height = [[self.companionModel.contentDict objectForKey:@"height"] floatValue];
        xPStr = [self.companionModel.contentDict objectForKey:@"xPosition"];
        yPStr = [self.companionModel.contentDict objectForKey:@"yPosition"];
    }
    
    if ([xPStr isEqualToString:@"left"]) {
        xPosition = 0;
    }else if ([xPStr isEqualToString:@"right"]) {
        xPosition = size.width - width;
    }else {
        xPosition = [xPStr floatValue];
    }
    
    if ([yPStr isEqualToString:@"top"]) {
        yPosition = 0;
    }else if ([yPStr isEqualToString:@"bottom"]) {
        yPosition = size.height - height;
    }else {
        yPosition = [yPStr floatValue];
    }

    self.frame = CGRectMake(xPosition, yPosition, width, height);
    
    UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    if (staticRes && staticRes.length > 0 && ![staticResType containsString:@"flash"]) {
        if ([staticResType containsString:@"image"]) {
            NSString *string = @"<meta charset='utf-8'><style type='text/css'>* { padding: 0px; margin: 0px;}a:link { text-decoration: none;}</style><div  style='width: 100%; height: 100%;'><img src=\"%@\" width=\"%fpx\" height=\"%fpx\" ></div>";
            string = [NSString stringWithFormat:string,staticRes,width,height];
            [webView loadHTMLString:string baseURL:nil];
        }else if ([staticResType containsString:@"javascript"]){
            if ([staticRes hasPrefix:@"http"]) {
                staticRes = [NSString stringWithFormat:@"<script>%@</script>",staticRes];
            }
            [webView loadHTMLString:staticRes baseURL:nil];
        }
    }else {
        NSURL *url;
        if (htmlRes && htmlRes.length > 0) {
            if ([htmlRes hasPrefix:@"http"]) {
                url = [NSURL URLWithString:htmlRes];
                [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:htmlRes]]];
            }else {
                [webView loadHTMLString:htmlRes baseURL:nil];
            }
        }else {
            if ([iframeRes hasPrefix:@"http"]) {
                url = [NSURL URLWithString:iframeRes];
                [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:iframeRes]]];
            }else {
                [webView loadHTMLString:iframeRes baseURL:nil];
            }
        }
    }
    webView.backgroundColor = [UIColor clearColor];
    [self addSubview:webView];
}

- (void)reportImpressionTracking {
    AdViewLogDebug(@"ADVASTNonVideoView report impression trackings");
    if (self.viewType == ADVASTNonVideoViewTypeCompanion) {
        [self.companionModel reportImpressionTracking];
    }else if (self.viewType == ADVASTNonVideoViewTypeIcon) {
        [self.iconModel reportImpressionTracking];
    }
}

- (void)responsClickAction {
    [self reportClickTracking];
    if (!clickThrough) {
        return;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(clickActionWithUrlString:)]) {
        [self.delegate clickActionWithUrlString:clickThrough];
    }
}

- (void)reportClickTracking {
    if (self.viewType == ADVASTNonVideoViewTypeCompanion) {
        [self.companionModel reportClickTracking];
    }else if (self.viewType == ADVASTNonVideoViewTypeIcon) {
        [self.iconModel reportClickTracking];
    }
}

#pragma mark touch event
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint currentPoint = [touch locationInView:self];
    
    if (CGRectContainsPoint(self.bounds, currentPoint)) {
        AdViewExtTool *tool = [AdViewExtTool sharedTool];
        [tool storeObject:[NSString stringWithFormat:@"%d", (int)currentPoint.x] forKey:@"__DOWN_X__"];
        [tool storeObject:[NSString stringWithFormat:@"%d", (int)currentPoint.y] forKey:@"__DOWN_y__"];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {}
- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint currentPoint = [touch locationInView:self];
    
    if (CGRectContainsPoint(self.bounds,currentPoint)) {
        AdViewExtTool *tool = [AdViewExtTool sharedTool];
        
        NSString *downX = [NSString stringWithFormat:@"%@",[tool objectStoredForKey:@"__DOWN_X__"] ];
        NSString *downY = [NSString stringWithFormat:@"%@",[tool objectStoredForKey:@"__DOWN_Y__"] ];
        NSString *upX = [NSString stringWithFormat:@"%d", (int)currentPoint.x];
        NSString *upY = [NSString stringWithFormat:@"%d", (int)currentPoint.y];
        
        [tool storeObject:upX forKey:@"__UP_X__"];
        [tool storeObject:upY forKey:@"__UP_y__"];
        
        NSMutableDictionary *clickPositionDic = [NSMutableDictionary dictionary];
        [clickPositionDic setObject:downX forKey:@"down_x"];
        [clickPositionDic setObject:upX forKey:@"up_x"];
        [clickPositionDic setObject:downY forKey:@"down_y"];
        [clickPositionDic setObject:upY forKey:@"up_y"];
        [tool storeObject:[AdViewExtTool jsonStringFromDic:clickPositionDic] forKey:@"{ABSOLUTE_COORD}"];
        
        NSMutableDictionary *rPositionDic = [NSMutableDictionary dictionary];
        NSString *down_x = [NSString stringWithFormat:@"%d", (int)(([downX floatValue]*1000)/self.frame.size.width)];
        NSString *down_y = [NSString stringWithFormat:@"%d", (int)(([downY floatValue]*1000)/self.frame.size.width)];
        NSString *click_x = [NSString stringWithFormat:@"%d", (int)((currentPoint.x*1000)/self.frame.size.height)];
        NSString *click_y = [NSString stringWithFormat:@"%d", (int)((currentPoint.y*1000)/self.frame.size.height)];
        [rPositionDic setObject:down_x forKey:@"down_x"];
        [rPositionDic setObject:down_y forKey:@"down_y"];
        [rPositionDic setObject:click_x forKey:@"up_x"];
        [rPositionDic setObject:click_y forKey:@"up_y"];
        [tool storeObject:[AdViewExtTool jsonStringFromDic:rPositionDic] forKey:@"{RELATIVE_COORD}"];
        
        //处理点击事件
        [self responsClickAction];
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    // 当前控件上的点转换到chatView上
    CGPoint chatP = [self convertPoint:point toView:self];
    // 判断下点在不在chatView上
    if ([self pointInside:chatP withEvent:event]) {
        return self;
    }else{
        return [super hitTest:point withEvent:event];
    }
}

@end

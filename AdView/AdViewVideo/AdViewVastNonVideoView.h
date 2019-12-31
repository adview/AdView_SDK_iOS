//
//  ADVASTNonVideoView.h
//  AdViewVideoSample
//
//  Created by AdView on 16/10/21.
//  Copyright © 2016年 AdView. All rights reserved.
//  伴随视图

#import <UIKit/UIKit.h>

@protocol AdViewVastNonVideoViewDelegate <NSObject>
@required
- (void)clickActionWithUrlString:(NSString*)urlString;
@end

typedef enum {
    ADVASTNonVideoViewTypeIcon,
    ADVASTNonVideoViewTypeCompanion,
}ADVASTNonVideoViewType;

@interface AdViewVastNonVideoView : UIView
@property (nonatomic, assign) ADVASTNonVideoViewType viewType;
@property (nonatomic, strong) NSString *showTimeStr; // 多少秒后展示
@property (nonatomic, strong) NSString *durationTimeStr; // 展示持续时间
@property (nonatomic, weak) id<AdViewVastNonVideoViewDelegate> delegate;

- (instancetype)initWithObject:(id)obj type:(ADVASTNonVideoViewType)type scale:(CGFloat)transScale size:(CGSize)superSize;
- (void)createView;
- (void)reportImpressionTracking;
@end

//
//  ADVASTIconModel.h
//  KOpenAPIAdView
//
//  Created by AdView on 2018/4/27.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ADVASTIconModel : NSObject
@property (nonatomic, copy) NSString *htmlSourceStr;
@property (nonatomic, copy) NSString *iframeSourceStr;
@property (nonatomic, copy) NSDictionary *staticSourceDict;
@property (nonatomic, strong) NSDictionary *contentDict;
@property (nonatomic, strong) NSArray *clickTrackingsArr;   // 点击监听地址
@property (nonatomic, strong) NSArray *clickThroughArr;     // 跳转地址
@property (nonatomic, strong) NSArray *viewTrackingsArr;    // 展示监听地址

@property (nonatomic, assign) int wrapperNumber;            // 伴随处于第几层包装，如果不在wrapper中则为0
@property (nonatomic, assign) CGRect frame;

- (void)reportImpressionTracking;
- (void)reportClickTracking;

@end

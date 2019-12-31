//
//  ADVASTCompanionModel.h
//  KOpenAPIAdView
//
//  Created by AdView on 2018/4/27.
//  伴随广告模型

#import <Foundation/Foundation.h>

@interface ADVASTCompanionModel : NSObject
@property (nonatomic, copy) NSString *htmlSourceStr;
@property (nonatomic, copy) NSString *iframeSourceStr;
@property (nonatomic, copy) NSDictionary *staticSourceDict;
@property (nonatomic, strong) NSDictionary *contentDict;
@property (nonatomic, strong) NSArray *clickTrackingsArr;   // 点击监听地址
@property (nonatomic, strong) NSArray *clickThroughArr;     // 跳转地址
@property (nonatomic, strong) NSDictionary *trackingsDict;  // 监听地址
@property (nonatomic, assign) int wrapperNumber;            // 伴随处于第几层包装，如果不在wrapper中则为0

- (void)reportImpressionTracking;
- (void)reportClickTracking;

@end

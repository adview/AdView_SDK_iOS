//
//  ADVASTModel.h
//  AdViewVideoSample
//
//  Created by AdView on 16/9/30.
//  Copyright © 2016年 AdView. All rights reserved.
//  VAST解析最外层总model.包含所有信息 相当于VAST标签

#import <Foundation/Foundation.h>
#import "AdViewVastAdModel.h"

@class AdViewVastUrlWithId;

@interface AdViewVastModel : NSObject

@property (nonatomic, assign) NSUInteger currentIndex;
@property (nonatomic, strong) NSMutableArray <AdViewVastAdModel *>* adsArray;   // ADVASTAdModel 数组
@property (nonatomic, assign) int wrapperNumber;                                // 第几层封装

//获取当前需要播放的AD标签
- (AdViewVastAdModel *)getCurrentAd;

//VAST版本号
- (NSString *)vastVersion;

//第一次解析最外层VAST标签
- (void)parseWrapperData;

//第二次解析每个AD标签
- (AdViewVastModel *)getInLineAvailableAd;

//获取当前需要播放的MdediaFile
- (AdViewVastMediaFile*)getCurrentMediaFile;

- (NSURL*)getCurrentURL;

//设置当前播放的是第几个AD标签里的广告
- (void)adjustCurrentIndex;

//重制计数器
- (void)resetCurrentIndex;

//是否最后一个Creative
- (BOOL)isLastCreative;
@end

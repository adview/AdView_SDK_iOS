//
//  ADVASTAdModel.h
//  KOpenAPIAdView
//
//  Created by AdView on 2018/4/27.
//  某一个广告的Model AD标签

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "AdViewVastMediaFile.h"
@class AdViewVastCreative;
@class ADVGVastExtensionModel;

@interface AdViewVastAdModel : NSObject

@property (nonatomic, assign) NSUInteger currentIndex;      //当前广告Creative序号

@property (copy, nonatomic) NSDictionary * compaionsDict;   //伴随广告数组
@property (copy, nonatomic) NSArray <AdViewVastCreative *>* creativeArray;      //视频数据
@property (nonatomic, copy) NSArray <ADVGVastExtensionModel *>* extesionArray;  //附加信息 比如OMSDK
@property (copy, nonatomic) NSArray  * errorArrary;
@property (copy, nonatomic) NSString * sequence;
@property (copy, nonatomic) NSArray  * impressionArray;

@property (nonatomic, copy) NSArray * wrapperImpArray;
@property (nonatomic, copy) NSArray * wrapperErrArray;

- (NSURL*)getCurrentAvailableUrl;
- (AdViewVastMediaFile*)getCurrentMediaFile;
- (NSArray*)getAvailableCompaionsWithSize:(CGSize)showArea;

- (void)reportImpressionTracking;
- (void)reportErrorsTracking;

@end

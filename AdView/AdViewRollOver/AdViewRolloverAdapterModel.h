//
//  RolloverAdapterDataModel.h
//  KOpenAPIAdView
//
//  Created by AdView on 2018/8/15.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, RolloverAdapterDataModelRequestType) {
    RolloverAdapterDataModelRequestType_Material = 0,   //物料
    RolloverAdapterDataModelRequestType_Mould           //模版
};

@interface AdViewRolloverAdapterModel : NSObject
@property (nonatomic, copy) NSNumber *aggsrc;                               //需要唤起的渠道
@property (nonatomic, copy) NSString *appid;                                //需要唤起的渠道的Appid 应用id
@property (nonatomic, copy) NSString *posid;                                //需要唤起的渠道的posid 广告位id
@property (nonatomic, copy) NSString *failurl;                              //上报Adview的失败回调
@property (nonatomic, copy) NSString *succurl;                              //上报Adview的成功回调
@property (nonatomic, copy) NSString *clkurl;                               //上报Adview的点击回调
@property (nonatomic, copy) NSString *impurl;                               //上报Adview的展示回调
@property (nonatomic, assign) RolloverAdapterDataModelRequestType reqtype;  //0.物料模式 1.模版模式
@property (nonatomic, assign) Class adapterClass;                           //平台适配器类对象
@end

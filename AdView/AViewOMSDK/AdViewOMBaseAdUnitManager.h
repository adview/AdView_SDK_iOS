//
//  ADVGOMBaseAdUnitManager.h
//  AdViewHello
//
//  Created by unakayou on 7/24/19.
//

#import <Foundation/Foundation.h>
#import "AdViewDefines.h"
#import <OMSDK_Adview/OMIDSDK.h>
#import <OMSDK_Adview/OMIDAdEvents.h>
#import <OMSDK_Adview/OMIDAdSession.h>
#import <OMSDK_Adview/OMIDVideoEvents.h>
#import <OMSDK_Adview/OMIDScriptInjector.h>
#import <OMSDK_Adview/OMIDAdSessionContext.h>
#import <OMSDK_Adview/OMIDAdSessionConfiguration.h>
#import <OMSDK_Adview/OMIDVASTProperties.h>

NS_ASSUME_NONNULL_BEGIN
extern NSString * const ADVGOSDKPartnerNameString;
extern NSString *  VendorKey;
extern NSString *  VerificationScriptURLString;
extern NSString *  VerificationParameters;

@interface AdViewOMBaseAdUnitManager : NSObject
@property (nonatomic, strong, readonly) OMIDAdviewSDK * OMAdViewSDK;            //OMSDK单例
@property (nonatomic, strong, readonly) OMIDAdviewAdEvents * OMIDAdEvent;       //事件发送
@property (nonatomic, strong, readonly) OMIDAdviewAdSession * OMIDAdSession;    //OM会话

/// OMSDK是否存在
+ (BOOL)isOMSDKExist;

/// OMSDK是否匹配
+ (BOOL)isCompatible;

//OMSDK活跃
+ (BOOL)isActive;

//SDK启动
+ (BOOL)activateOMIDSDK;

//OMSDK JS脚本
+ (NSString *)OMIDService;

//设置本次会话中的广告
- (void)setMainAdview:(UIView *)adview;

//设置广告阻挡View白名单
- (void)setFriendlyObstruction:(UIView *)view;

//监测开始、完毕
- (void)startMeasurement;
- (void)finishMeasurement;

//创建AdSessionConfiguration 需要子类重写
- (OMIDAdviewAdSessionConfiguration *)createAdSessionConfiguration;

//创建AdSessionContent 需要子类重写
- (OMIDAdviewAdSessionContext *)createAdSessionContextWithPartner:(OMIDAdviewPartner *)partner;

//创建VerificationScriptResource 子类直接调用 通用方法
- (OMIDAdviewVerificationScriptResource *)createVerificationScriptResourceVendorKey:(NSString *)vendorKey
                                                              verificationScriptURL:(NSString *)verificationScriptURL
                                                                         parameters:(NSString *)parameters;

//设置特殊的AdEvent.如视频 需要子类重写
- (void)setupAdditionalAdEvents:(OMIDAdviewAdSession *)addSession;

//发生错误
- (void)logErrorWithType:(OMIDErrorType)errorType message:(nonnull NSString *)message;
@end

NS_ASSUME_NONNULL_END

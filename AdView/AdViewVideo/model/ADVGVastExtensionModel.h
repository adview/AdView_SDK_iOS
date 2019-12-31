//
//  ADVGVastExtensionModel.h
//  AdViewHello
//
//  Created by unakayou on 8/6/19.
//  AD标签下的Extension和Creative平级

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ADVGVastExtensionModel : NSObject
@property (nonatomic, copy) NSString * typeString;                  //omsdk只需要AdVerifications类型的extension

@property (nonatomic, copy) NSString * vendor;                      //广告商名
@property (nonatomic, copy) NSString * verificationParameters;      //认证参数
@property (nonatomic, copy) NSString * VerificationScriptURLString; //认证JS地址
@property (nonatomic, copy) NSDictionary * trackingEvents;          //事件
- (void)reportVerificationNotExecuted;
@end

NS_ASSUME_NONNULL_END

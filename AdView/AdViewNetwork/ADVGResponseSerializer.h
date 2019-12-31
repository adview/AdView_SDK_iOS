//
//  ADVGResponseSerializer.h
//  AdViewHello
//
//  Created by unakayou on 7/18/19.
//  请求解析器

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ADVGResponseSerializationProcotol <NSObject>
- (nullable id)responseObjectForResponse:(nullable NSURLResponse *)response
                                    data:(nullable NSData *)data
                                   error:(NSError * _Nullable __autoreleasing *)error;
@end

//抽象类 啥也不干
@interface ADVGResponseSerializer : NSObject <ADVGResponseSerializationProcotol>
+ (ADVGResponseSerializer *)serializer;
@end

//JSON序列化(简单实现)
@interface ADVGJSONResponseSerializer : ADVGResponseSerializer

@end

//XML解析器(未实现)
@interface ADVGXMLResponseSerializer : ADVGResponseSerializer

@end

//图片解析
@interface ADVGImageResponseSerializer : ADVGResponseSerializer

@end
NS_ASSUME_NONNULL_END

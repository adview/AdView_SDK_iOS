//
//  ADVGResponseSerializer.m
//  AdViewHello
//
//  Created by unakayou on 7/18/19.
//

#import "ADVGResponseSerializer.h"
#import <UIKit/UIKit.h>

@implementation ADVGResponseSerializer
+ (ADVGResponseSerializer *)serializer {
    return [[self alloc] init];
}

- (id)responseObjectForResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *__autoreleasing  _Nullable *)error {
    return data;
}
@end

@implementation ADVGJSONResponseSerializer
- (id)responseObjectForResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *__autoreleasing  _Nullable *)error {
    NSDictionary * retJSONDict = [NSJSONSerialization JSONObjectWithData:data
                                                                 options:NSJSONReadingMutableContainers
                                                                   error:error];
    return retJSONDict;
}
@end

@implementation ADVGXMLResponseSerializer
- (id)responseObjectForResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *__autoreleasing  _Nullable *)error {
    NSString * XMLString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return XMLString;
}
@end

@implementation ADVGImageResponseSerializer
- (id)responseObjectForResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *__autoreleasing  _Nullable *)error {
    UIImage * image = [[UIImage alloc] initWithData:data scale:[UIScreen mainScreen].scale];
    return image;
}
@end

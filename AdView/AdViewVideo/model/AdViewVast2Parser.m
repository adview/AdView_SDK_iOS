//
//  ADVAST2Parser.m
//  AdViewVideoSample
//
//  Created by AdView on 16/10/9.
//  Copyright © 2016年 AdView. All rights reserved.
//

#import "AdViewVast2Parser.h"
#import "AdViewVastXMLUtil.h"
#import "AdViewVastModel.h"
#import "AdViewVastSettings.h"
#import "AdViewExtTool.h"
#import "AdViewVastSchema.h"

@interface AdViewVast2Parser ()
@property (nonatomic, strong) AdViewVastModel * vastModel;
- (AdViewVastError)parseRecursivelyWithData:(NSData *)vastData depth:(int)depth;
@end

@implementation AdViewVast2Parser

#pragma mark - "LifeCycle"
- (id)init {
    if (self = [super init]) {
        self.vastModel = [[AdViewVastModel alloc] init];
    }
    return self;
}

- (void)dealloc {
    self.vastModel = nil;
}

#pragma mark - "public" methods
- (void)parseWithUrl:(NSURL *)url completion:(void (^)(AdViewVastModel *, AdViewVastError))block
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *vastData = [NSData dataWithContentsOfURL:url];
        AdViewVastError vastError = [self parseRecursivelyWithData:vastData depth:0];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            block(self->_vastModel, vastError);
        });
    });
}

//目前只从data加载
- (void)parseWithData:(NSData *)vastData completion:(void (^)(AdViewVastModel *, AdViewVastError))block
{
    //开个新线程异步执行加载VAST-XML解析成Model
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        AdViewVastError vastError = [self parseRecursivelyWithData:vastData depth:0];
        
        //返回主线程 将建立好的model传递给 AdViewVideoViewController 的 parserCompletionBlock
        dispatch_async(dispatch_get_main_queue(), ^{
            block(self->_vastModel, vastError);
        });
    });
}

#pragma mark - "private" method
//⚠️ 第一次解析-判断外层是否有wrapper 如果有递归加载解析
- (AdViewVastError)parseRecursivelyWithData:(NSData *)vastData depth:(int)depth {
    //wrapper请求超过5次报错
    if (depth >= AdViewkMaxRecursiveDepth) {
        self.vastModel = nil;
        return VASTErrorTooManyWrappers;
    }
    
    //打印一下VAST XML
    AdViewLogDebug(@"VAST - Parser : VAST file\n%@",[[NSString alloc] initWithData:vastData encoding:NSUTF8StringEncoding]);
    
    // 验证VAST字符串XML语法是否有效
    BOOL isValid = adViewValidateXMLDocSyntax(vastData);
    if (!isValid) {
        self.vastModel = nil;
        return VASTErrorXMLParse;
    }
    
    //XML是否有scheme,默认没有
    if (adcmopkValidateWithSchema) {
        // Using header data
        NSData *vastSchemaData = [NSData dataWithBytesNoCopy:AdView_compvast_xsd
                                                      length:nexage_compvast_2_0_1_xsd_len
                                                freeWhenDone:NO];
        isValid = adViewValidateXMLDocAgainstSchema(vastData, vastSchemaData);
        if (!isValid) {
            self.vastModel = nil;
            return VASTErrorSchemaValidation;
        }
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    //向model中添加VAST-XML
    [_vastModel performSelector:@selector(addVASTDocument:) withObject:vastData];    //将本次的XML字符串放到vastModel里,等待二次解析
#pragma clang diagnostic pop
    
    //检查是否是wrapper广告.
    NSArray * results = adViewPerformXMLXPathQuery(vastData, @"//VASTAdTagURI");
    if ([results count] > 0)
    {
        NSString * url;
        NSDictionary *node = results[0];
        if ([node[@"nodeContent"] length] > 0)  //字符串数据
        {
            url = node[@"nodeContent"];
        }
        else    //CDATA数据 (不应由XML解析器进行解析的文本数据)
        {
            NSArray *childArray = node[@"nodeChildArray"];
            if ([childArray count] > 0)
            {
                //⚠️ 假设数组中只有一个元素
                url = ((NSDictionary *)childArray[0])[@"nodeContent"];
            }
        }
        url = [url stringByReplacingOccurrencesOfString:@" " withString:@""];   //URL中有空格需要去掉

        _vastModel.wrapperNumber = depth + 1;    //wrapper层数加1
        [_vastModel parseWrapperData];           //⚠️ 第一次解析,解析本层wrapper相关数据.保存到VAST-model的数组中
        
        //开始递归请求解析wapper
        vastData = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
        return [self parseRecursivelyWithData:vastData depth:(depth + 1)];
    }
    _vastModel.wrapperNumber = 0;
    return VASTErrorNone;
}

- (NSString *)content:(NSDictionary *)node
{
    // this is for string data
    if ([node[@"nodeContent"] length] > 0)
    {
        return node[@"nodeContent"];
    }
    
    // this is for CDATA
    NSArray *childArray = node[@"nodeChildArray"];
    if ([childArray count] > 0)
    {
        // we assume that there's only one element in the array
        return ((NSDictionary *)childArray[0])[@"nodeContent"];
    }
    
    return nil;
}

@end

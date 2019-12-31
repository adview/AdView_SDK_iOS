//
//  AdViewAdapter.h
//  AdViewSDK
//
//  Created by AdView on 12-8-30.
//  Copyright 2012 AdView. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AdViewDefines.h"

#define ADDIRECT_STR        @"Adview直投"
#define ADEXCHANGE_STR      @"Adview交换"
#define ADFILL_STR          @"AdView"

@class AdViewContent;
@class AdViewAdCondition;

typedef enum {
    ERR_AUTOLANDING = 1,
    ERR_EMPTYAD
} ErrReportType;

@interface AdViewAdapterResponse : NSObject
@property (nonatomic, strong) NSData * body;
@property (nonatomic, strong) NSDictionary * headers;
@property (nonatomic, assign) AdViewHTTPStatus status;      //http status code, 200, 401, etc.
@property (nonatomic, assign) AdViewConnectionState	type;   //get, getbody, display, click?

@end

@interface AdViewAdapter : NSObject {

}

@property (nonatomic, copy)   NSString * appId;
@property (nonatomic, assign) AdViewAdPlatType  adPlatType;
@property (nonatomic, assign) BOOL adTestMode;          //0:正式广告 1:测试广告
@property (nonatomic, assign) BOOL useTestServer;       //0:正式服务器地址 1:测试服务器地址
@property (nonatomic, assign) int configVer;
@property (nonatomic, assign) AdvertType adType;
@property (nonatomic, assign) BOOL bIgnoreShowRequest;
@property (nonatomic, assign) BOOL bIgnoreClickRequest;

@property (strong, nonatomic) NSString *showUrlStr;     //Adview自己的上报链接
@property (strong, nonatomic) NSString *clickUrlStr;

@property (copy, nonatomic) NSArray *otherPaltArray;    //三方平台信息数组

+ (void)linkMutableString:(NSMutableString*)str
                     Dict:(NSMutableDictionary*)infoDict;

//是否采用自带的xmlparser处理请求。
- (BOOL)useInternalParser;

- (NSMutableURLRequest*)getAdReportRequest:(BOOL)bClickOtherDisplay AdContent:(AdViewContent*)theAdContent;

- (NSMutableURLRequest*)getAdGetRequest:(AdViewAdCondition*)condition;

- (NSMutableURLRequest*)makeAdErrorReport:(ErrReportType)errType AdContent:(AdViewContent*)theAdContent Arg:(NSString*)arg;

- (BOOL)parseResponse:(AdViewAdapterResponse*)response
		  AdContent:(AdViewContent*)adContent ErrorInfo:(NSString**)errInfo;

- (BOOL)parseResponse:(AdViewAdapterResponse*)response
            contentArr:(NSMutableArray*)contentArr ErrorInfo:(NSString**)errInfo;

- (BOOL)parseXMLStartElement:(NSString*)elementName 
				  attributes:(NSDictionary*)attributes
				   adContent:(AdViewContent*)theAdContent;

- (BOOL)parseXMLFoundCharacters:(NSString*)string
					  inElement:(NSString*)elementName
					  adContent:(AdViewContent*)theAdContent;

- (void)adjustAdSize:(CGSize*)size;

- (NSString*)copyRightString;
//- (NSString*)replaceDefineString:(NSString *)urlString AdContent:(AdViewContent*)content ;

 //may should add some parameter to the linkUrl
- (BOOL)adjustClickLink:(AdViewContent*)adContent;

// 重新解释Error
- (NSError *)parseStatus:(int)statusCode error:(NSError *)error;

+ (void)logRequestHeaders:(NSURLRequest*)requst;
+ (void)metricPing:(NSString*)query;

- (void)cleanDummyData;

@end

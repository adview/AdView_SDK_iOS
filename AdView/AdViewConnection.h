#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Foundation/NSURLConnection.h>
#import "AdViewDefines.h"

@class AdViewAdCondition;
@class AdViewContent;
@class AdViewAdapterResponse;
@class AdViewContent;
@class AdViewAdGetRequest;
@class AdViewAdDisplayRequest;
@class AdViewAdClickRequest;
@class AdViewConnection;

#define LOADING_IMG_ADICON  -4
#define LOADING_IMG_ADLOGO  -3
#define LOADING_IMG_BG      -2
#define LOADING_IMG_ACT     -1

@protocol AdViewConnectionDelegate <NSObject>

//响应回调
- (void)adConnection:(AdViewConnection *)connection didReceiveResponse:(NSURLResponse *)response;

//请求成功回调
- (void)adConnectionDidFinishLoading:(AdViewConnection*)connection;

//收到解析完的广告数组
- (void)adConnection:(AdViewConnection*)connection didReceiveAdContent:(NSMutableArray <AdViewContent *>*)contentArr;

//请求失败回调
- (void)adConnection:(AdViewConnection*)connection didFailWithError:(NSError*)error;

//是否需要缓存
- (BOOL)isNeedCache;
@end

@class AdViewAdapter;

@interface AdViewAdRequest : NSObject
{
    NSString* adAppId;
    NSMutableURLRequest* httpRequest;
	
	BOOL		bWontVisit;     //not need to visit
}

@property (nonatomic, strong) NSString* adAppId;
@property (nonatomic, strong) NSMutableURLRequest* httpRequest;

@end

@interface AdViewAdResponse : NSObject
@end

@interface AdViewAdGetRequest : AdViewAdRequest
+ (AdViewAdGetRequest *)requestWithConditon:(AdViewAdCondition*)condition adapter:(AdViewAdapter*)adapter;
@end

@interface AdViewAdGetResponse : AdViewAdResponse
@end

//展示汇报
@interface AdViewAdDisplayRequest : AdViewAdRequest
+ (AdViewAdDisplayRequest *)requestWithAdContent:(AdViewContent *)adContent Adapter:(AdViewAdapter *)adapter;
@end

@interface AdViewAdDisplayResponse : AdViewAdResponse
@end

//点击汇报
@interface AdViewAdClickRequest : AdViewAdRequest
+(AdViewAdClickRequest*) requestWithAdContent:(AdViewContent *)adContent Adapter:(AdViewAdapter *)adapter;
@end

@interface AdViewAdClickResponse : AdViewAdResponse
@end

@interface AdViewConnection : NSObject <NSXMLParserDelegate>
{    
    int             nLoadImage;             //不同值代表加载不同位置的图片.参考LOADING_IMG_ADICON、LOADING_IMG_ADLOGO、LOADING_IMG_BG、LOADING_IMG_ACT
    BOOL            tryUseCache;
    int             failDisplayReqTimes;    //times of fialed display request .
}
@property (nonatomic, strong) NSXMLParser * adXMLParser;                    //XML解析器
@property (nonatomic, strong) NSString * currentElementName;                //XML的解析元素

@property (nonatomic, strong) AdViewAdRequest * adRequest;                  //当前的AdViewAdRequest
@property (nonatomic, strong) AdViewContent * adContent;                    //解析完的广告数据 一个巨胖的model
@property (nonatomic, strong) NSMutableArray <AdViewContent *>* contentArr; //解析完的广告数据数组
@property (nonatomic, strong) NSMutableData * httpData;                     //请求体数据
@property (nonatomic, strong) NSMutableDictionary * httpHeader;             //请求头

//这三个是做个URL内存缓存
@property (nonatomic, strong) NSString*				conMethod;              //HTTPMethod(GET、POST)
@property (nonatomic, strong) NSURLResponse*        conResponse;            //存储请求的Response
@property (nonatomic, strong) NSMutableURLRequest*	conRequest;             //当前的请求

@property (nonatomic, weak) id<AdViewConnectionDelegate> delegate;
@property (nonatomic, strong) AdViewAdapter *adapter;                       //按理说应该设置一个procotol.目前这样做直接给他传请求返回参数
@property (nonatomic, readonly) AdViewConnectionType connectionType;        //请求类型
@property (nonatomic, readonly) AdViewConnectionState connectionState;      //进行状态

@property (nonatomic, strong) NSTimer * retryConTimer;                      //重试定时器30s
@property (nonatomic, strong) NSMutableArray <NSURLConnection *>* connections;

- (AdViewConnection*)initWithGetRequest:(AdViewAdGetRequest *)request
                                adapter:(AdViewAdapter *)adapter
                               delegate:(id<AdViewConnectionDelegate>)delegate;

- (AdViewConnection*)initWithDisplayRequest:(AdViewAdDisplayRequest *)request
                                   delegate:(id<AdViewConnectionDelegate>)theDelegate;

- (AdViewConnection*)initWithClickRequest:(AdViewAdClickRequest*)request
                                 delegate:(id<AdViewConnectionDelegate>)delegate;

- (void)startConnection;
- (void)parseAdBody;
- (BOOL)fetchExternalImage:(BOOL)bReuse;
- (void)cancel;
- (void)clearRetryTimer;
@end

#define OPENAPI_ADDATA_LIMIT		512*1024

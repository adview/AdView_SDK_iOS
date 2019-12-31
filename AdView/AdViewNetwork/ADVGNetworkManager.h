//
//  ADVGNetworkManager.h
//  AdViewHello
//
//  Created by unakayou on 7/10/19.
//  网络请求业务类

#import <Foundation/Foundation.h>
#import "AdViewDefines.h"
#import "ADVGURLSessionManager.h"
#import "ADVGImageDownloadManager.h"
@class ADVGNetworkManager;

//请求类型
typedef NS_ENUM(NSInteger, ADVGRequestType)
{
    ADVGRequestTypeRequestAd     = 1,       //请求广告
    ADVGRequestTypeDisplayReport = 5,       //展示汇报
    ADVGRequestTypeClickReport   = 6,       //点击汇报
    ADVGRequestTypeRequestImage,            //请求图片
};

typedef NS_ENUM(NSInteger, ADVGErrorCode) {
    ADVGErrorCodeRequestTooFast,
    ADVGErrorCodeParseFail
};

@protocol ADVGNetworkManagerProtocol <NSObject>
- (void)networkManagerDidFinishLoading:(ADVGNetworkManager *)manager;
- (void)networkManager:(ADVGNetworkManager *)manager didFailWithError:(NSError *)error;
- (BOOL)useCache;
@end

@interface ADVGNetworkManager : NSObject
@property (nonatomic, assign) BOOL useCache;                                        //是否使用缓存
@property (nonatomic, strong, readonly) AdViewAdapter * adapter;                    //数据源
@property (nonatomic, assign, readonly) ADVGRequestType requestType;                //请求类型
@property (nonatomic, weak) id<ADVGNetworkManagerProtocol> delegate;                //用于网络回调

//任务
@property (readonly, nonatomic, strong) NSArray <NSURLSessionTask *> *tasks;
@property (readonly, nonatomic, strong) NSArray <NSURLSessionDataTask *> *dataTasks;
@property (readonly, nonatomic, strong) NSArray <NSURLSessionDownloadTask *> *downloadTasks;

//获取管理器
+ (instancetype)sharedManager;

//请求广告
- (NSURLSessionDataTask *)requestAdWithAdCondition:(AdViewAdCondition *)condition
                                           adapter:(AdViewAdapter *)adapter
                                 completionHandler:(void (^)(NSURLResponse *response, NSArray <AdViewContent *>*responseObject,  NSError *error))completionHandler;

//展示汇报
- (NSURLSessionDataTask *)requestAdDisplayWithAdCondition:(AdViewAdCondition *)condition
                                        ReportWithAdapter:(AdViewAdapter *)adapter;
//点击汇报
- (NSURLSessionDataTask *)requestAdClickWithAdCondition:(AdViewAdCondition *)condition
                                      ReportWithAdapter:(AdViewAdapter *)adapter;

- (void)cancel;
@end

